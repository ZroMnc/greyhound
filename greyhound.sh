#!/bin/bash
set -euo pipefail
IFS=$'\n\t'


#VARS
teamname=""
username=""
token=""
OAUTH_TOKEN=""
team_url="https://teams.auth.zalando.com/api"
user_url="https://users.auth.zalando.com/employees"
token_url="https://token.auth.zalando.com/access_token?json=true"
tokeninfo="https://auth.zalando.com/oauth2/tokeninfo?access_token"

#APPJSON=$(cat user.json)
#CLIENTJSON=$(cat client.json)

#MESSAGES
TOKEN_STILL_VALID_MSG="Your Token is still valid"
TOKEN_INVALID_MSG="Your Token is invalid - requesting a new"
INVALID_REQUEST_ERROR='"invalid_request"'

#ERROR CODES
ERROR_401="401"

json_decode () {
    echo -n "$1" | jq -r ."$2"
}

url_encode () {
    echo -n "$1" | perl -pe 's/([^a-zA-Z0-9])/"%".sprintf("%x", ord($1))/ge'
}

get_service_token () {

    APP_PASS=$( json_decode "$APPJSON" "application_password" )
    APP_NAME=$( json_decode "$APPJSON" "application_username" )
    CLIENT_ID=$( json_decode "$CLIENTJSON" "client_id" )
    CLIENT_SECRET=$( json_decode "$CLIENTJSON" "client_secret" )
    AUTH_HDR=$( echo -n "$CLIENT_ID:$CLIENT_SECRET" | base64 | tr -d ' \n' )
    USER_ID=$( url_encode "$APP_NAME" )
    USER_PASS=$( url_encode "$APP_PASS" )

    curl -X POST --header "Authorization: Basic $AUTH_HDR" --data "grant_type=password&username=$USER_ID&password=$USER_PASS&scope=uid" "https://auth.zalando.com/oauth2/access_token?realm=/services"
}


show_help() {
printf "Usage: ./token.sh [-har] [-t TEAMNAME] [-u USERNAME] [-i TOKEN]
    Token Helper
    -a              Get an access_token and add to clipboard (OSX Only)
    -s              Get an access_token from service realm
    -t  TEAMNAME    Retrieves listing from team api
    -u  USERNAME    Get specific user info
    -p  QUERY       Search for Names (can be incomplete)
    -i  TOKEN       Poll the Tokeninfo endpoint
    -r  TOKEN       Revoke your token\n"
}

#Getting credentials
login() {
    DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
    if [ -f $DIR/.token ]; then
        OAUTH_TOKEN=$( cat $DIR/.token | awk '{gsub(/^ +| +$/,"")} {print $0 }')
        RESPONSE=$(curl -s "$tokeninfo=$OAUTH_TOKEN")
        ERROR=$( echo "$RESPONSE" | jq .'error')
        if [ "$ERROR" == "$INVALID_REQUEST_ERROR" ]; then
            printf "$TOKEN_INVALID_MSG\n"
            getToken
        else
            printf "$TOKEN_STILL_VALID_MSG\n"
            exportToken
        fi
    else
        echo "" > .token
        getToken
    fi
}

getToken() {
        read -p "Enter Username : " uname
        read -s -p "Enter Password : " pass
        base=$(echo -n "$uname:$pass" | base64)
        token=$(curl -s --header  "Authorization: Basic $base" $token_url)
        # Print either an access token or the error code
        VAR2=$( echo "$token" | jq -r '[.access_token // .code]' | tr -d '[]' )
        if [[ "$VAR2" == *$ERROR_401* ]]; then
            printf "Unauthorized - Username or Password Error\n"
            exit 1
        else
            OAUTH_TOKEN=$( echo $VAR2 | tr -d '""' | awk '{gsub(/^ +| +$/,"")} {print $0 }' )
            exportToken
        fi
}

exportToken() {
        exportValue=$( echo $OAUTH_TOKEN | tr -d '""' > $DIR/.token)
        token=$OAUTH_TOKEN
}

revoke() {
    read -p "Enter Username : " uname
    read -s -p "Enter Password : " pass
    base=$(echo -n "$uname:$pass" | base64)
    curl -s --request DELETE --header "Authorization: Basic $base" "https://token.auth.zalando.com/access_token/employees/$uname" | jq .
    printf "\n[+] Done\n"
}

OPTIND=1
while getopts "hast:u:i:q:r" opt; do
    case "$opt" in
        h)
            show_help
            exit 0
            ;;
        a)
            login
            exit 1
            ;;
        s)
            get_service_token
            exit 1
            ;;
        t)  teamname=$OPTARG
            login
            curl -s --header "Authorization: Bearer $token" "$team_url/teams/$teamname" | jq .
            exit 1
            ;;
        u)  username=$OPTARG
            login
            curl -s --header "Authorization: Bearer $token" "$user_url/$username" | jq .
            exit 1
            ;;
        q)  query=$OPTARG
            login
            curl -s --header "Authorization: Bearer $token" "$user_url?sort=name&q=$query" | jq .
            exit 1
            ;;
        i)
            token=$OPTARG
            curl -s "$tokeninfo=$token" | jq .
            exit 1
            ;;
        r)
            revoke
            exit 1
            ;;
    esac
done



# EOF
