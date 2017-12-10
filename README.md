# Greyhound
Little Helper Script for work to manage tokens
```
   _____                _                           _ 
  / ____|              | |                         | |
 | |  __ _ __ ___ _   _| |__   ___  _   _ _ __   __| |
 | | |_ | '__/ _ \ | | | '_ \ / _ \| | | | '_ \ / _` |
 | |__| | | |  __/ |_| | | | | (_) | |_| | | | | (_| |
  \_____|_|  \___|\__, |_| |_|\___/ \__,_|_| |_|\__,_|
                   __/ |                              
                  |___/                               
```

```bash
Token Helper
    -a              Get an access_token and add to clipboard (OSX Only)
    -s              Get an access_token from service realm
    -t  TEAMNAME    Retrieves listing from team api
    -u  USERNAME    Get specific user info
    -p  QUERY       Search for Names (can be incomplete)
    -i  TOKEN       Poll the Tokeninfo endpoint
    -p IP          Returns Team-Name from given AWS NAT instance
   -r  TOKEN       Revoke your token
    -n  AWS-ID      Pulls information about a given aws account
```

Add this to make it available
```bash
echo "export PATH=${PATH}:~/<workspace>/greyhound" >> ~/.bashrc
alias getToken="greyhound.sh -a || TOKEN=$(cat ~/workspace/greyhound/.token) || echo $TOKEN"
```

### NOTES
You will need to get a session key of the zonar tooling. Simply just login and save the cookie named session.
