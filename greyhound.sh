#!/bin/bash
set -euo pipefail
IFS=$'\n\t'


#VARS
teamname=""
username=""
token=""
OAUTH_TOKEN=""
zonarkey=""
keypath="$HOME/keys/keys/.zonar"
team_url="https://teams.auth.zalando.com/api"
user_url="https://users.auth.zalando.com/employees"
token_url="https://token.auth.zalando.com/access_token?json=true"
tokeninfo="https://auth.zalando.com/oauth2/tokeninfo?access_token"
zonar_url="https://zonar.zalando.net"

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


show_help() {
printf "Usage: ./greyhound.sh [-har] [-t TEAMNAME] [-u USERNAME] [-i TOKEN] [-n AWS-ID]
      _____                _                           _ 
     / ____|              | |                         | |
    | |  __ _ __ ___ _   _| |__   ___  _   _ _ __   __| |
    | | |_ | '__/ _ \ | | | '_ \ / _ \| | | | '_ \ / _\` |
    | |__| | | |  __/ |_| | | | | (_) | |_| | | | | (_| |
     \_____|_|  \___|\__. |_| |_|\___/ \__._|_| |_|\__|_|
                     __/ |                              
                    |___/                               
    Token Helper
    -t  TEAMNAME    Retrieves listing from team api
    -u  USERNAME    Get specific user info
    -p  QUERY       Search for Names (can be incomplete)
    -i  TOKEN       Poll the Tokeninfo endpoint
    -p IP          Returns Team-Name from given AWS NAT instance
    -n  AWS-ID      Pulls information about a given aws account
    -z USERNAME     Poll userdata from SAP\n"
}

#Getting credentials
login() {
    exportToken
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
        token=`ztoken token`
}

get_session(){
    zonarkey=`cat $keypath`
}

OPTIND=1
while getopts "hast:u:i:p:q:rn:z:" opt; do
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
            curl -s --header "Authorization: Bearer $token" "$user_url/$username" | jq 'del(.keys, .time_zone, .shell, .home, .country, .company, .first_name, .last_name, .full_name )'
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
        p)
            ipaddr=$OPTARG
            login
            curl -s -H "Authorization: Bearer $token" "$team_url/accounts/aws?ip=$ipaddr" | jq .
            exit 1
            ;;
        n)  aws=$OPTARG
            login
            curl -s --header "Authorization: Bearer $token" "$team_url/accounts/aws/$aws" | jq .
            exit 1
            ;;
        z)
            zonaruser=$OPTARG
            login
            get_session
            curl -s --header "Authorization: Bearer $token" --header "Cookie: SESSION=$zonarkey" "$zonar_url/api/employees?username=$zonaruser" | jq .
            exit 1
            ;;
    esac
done



# EOF
