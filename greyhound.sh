#!/bin/bash

#VARS
teamname=""
username=""
token=""
team_url="https://teams.auth.zalando.com/teams"
user_url="https://users.auth.zalando.com/employees"
token_url="https://token.auth.zalando.com/access_token"
tokeninfo="https://auth.zalando.com/oauth2/tokeninfo?access_token"
APPJSON='{"application_username":"XXXXXXXXXXXXXX","application_password":"XXXXXXXXXXXXXXXXX"}'
CLIENTJSON='{"client_id":"XXXXXXXXXXXXXXX","client_secret":"XXXXXXXXXXXXXXXXXXXXXX"}'

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
printf "Usage: ./token.sh [-ha] [-t TEAMNAME] [-u USERNAME] [-ir TOKEN]
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
        read -p "Enter Username : " uname
        read -s -p "Enter Password : " pass
        base=$(echo -n "$uname:$pass" | base64)

        #Retrieve Access Token
        token=$(curl -s --header  "Authorization: Basic $base" $token_url)
}

OPTIND=1
while getopts "hast:u:i:r:" opt; do
    case "$opt" in
        h)
            show_help
            exit 0
            ;;
        a)
            login
            printf "\nToken added to clipboard\n"
            echo $token | pbcopy
            exit 1
            ;;
        s)
            get_service_token
            exit 1
            ;;
        t)  teamname=$OPTARG
            login
            curl -s --header "Authorization: Bearer $token" "$team_url/$teamname" | jq .
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
            token=$OPTARG
            curl -s --header "Authorization: Bearer $token" "https://token.auth.zalando.com/invalidate/employees/$token"
            exit 5
            ;;
    esac
done



# EOF
