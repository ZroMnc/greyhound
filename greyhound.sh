#!/bin/bash
set -e

#VARS
teamname=""
username=""
team_url="https://teams.auth.zalando.com/api"
user_url="https://users.auth.zalando.com/employees"
token_url="https://token.auth.zalando.com/access_token?json=true"
tokeninfo="https://auth.zalando.com/oauth2/tokeninfo?access_token"

APPJSON='{"application_username":"XXXXXXXXXXXXXX","application_password":"XXXXXXXXXXXXXXXXX"}'
CLIENTJSON='{"client_id":"XXXXXXXXXXXXXXX","client_secret":"XXXXXXXXXXXXXXXXXXXXXX"}'

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
    -i  TOKEN       Poll the Tokeninfo endpoint
    -r  TOKEN       Revoke your token\n"
}

#Getting credentials
login() {
    DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
    if [ -f $DIR/.token ]; then
#        echo 'Here'
        token=$( cat $DIR/.token )
        RESPONSE=$(curl -s "$tokeninfo=$token")
        VAR1=$( echo "$RESPONSE" | jq .'error')
        if [ "$VAR1" == "$INVALID_REQUEST_ERROR" ]; then
            echo 'Blubb'
            printf "$TOKEN_INVALID_MSG\n"
            getToken
        else
            printf "$TOKEN_STILL_VALID_MSG\n"
            getToken
        fi
    else
        echo 'There'
        echo "" > .token
        getToken
    fi

#    if [ -e $DIR/.token ]; then
#            else
#        #Retrieve Access Token
#    fi
}

getToken() {
        read -p "Enter Username : " uname
        read -s -p "Enter Password : " pass
        base=$(echo -n "$uname:$pass" | base64)
        printf "BASE $base \n"
        token=$(curl -s --header  "Authorization: Basic $base" $token_url)
       # echo $token
        # Print either an access token or the error code
        VAR2=$( echo "$token" | jq -r '[.access_token // .code]' | tr -d '[]' )
        echo $VAR2
        printf "$VAR2\n"
        if [[ "$VAR2" == *$ERROR_401* ]]; then
            printf "Unauthorized - Username or Password Error\n"
#            echo $ERROR_401
#            echo $VAR2
            exit 1
        else
            echo $VAR2 | tr -d '""' > $DIR/.token
#            echo 'Beer'
            echo $VAR2 | pbcopy
            export TOKEN=$( cat .token )

#            printf "\n[+] Token added to clipboard\n"
        fi
    }

revoke() {
    read -p "Enter Username : " uname
    read -s -p "Enter Password : " pass
    base=$(echo -n "$uname:$pass" | base64)
    curl -s --request DELETE --header "Authorization: Basic $base" "https://token.auth.zalando.com/access_token/employees/$uname" | jq .
    printf "\n[+] Done\n"
}

OPTIND=1
while getopts "hast:u:i:r" opt; do
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
            exit 2
            ;;
        u)  username=$OPTARG
            login
            curl -s --header "Authorization: Bearer $token" "$user_url/$username" | jq .
            exit 3
            ;;
        i)
            token=$OPTARG
            curl -s "$tokeninfo=$token" | jq .
            exit 4
            ;;
        r)
            revoke
            exit 5
            ;;
    esac
done



# EOF
