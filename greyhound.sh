#!/bin/bash
set -e

#VARS
teamname=""
username=""
token=""
team_url="https://teams.auth.zalando.com/teams"
user_url="https://users.auth.zalando.com/employees"
token_url="https://token.auth.zalando.com/access_token"
tokeninfo="https://auth.zalando.com/oauth2/tokeninfo?access_token"

show_help() {
printf "Usage: ./token.sh [-ha] [-t TEAMNAME] [-u USERNAME] [-ir TOKEN]
    Token Helper
    -a              Get an access_token and add to clipboard (OSX Only)
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
while getopts "hat:u:i:r:" opt; do
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
