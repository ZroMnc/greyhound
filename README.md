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
Usage: ./token.sh [-ha] [-t TEAMNAME] [-u USERNAME] [-ir TOKEN]
    Token Helper
    -a              Get an access_token and add to clipboard (OSX Only)
    -t  TEAMNAME    Retrieves listing from team api
    -u  USERNAME    Get specific user info
    -q  QUERY       Search parameter for users
    -i  TOKEN       Poll the Tokeninfo endpoint
    -r  TOKEN       Revoke your token
```

Add this to make it available
```bash
echo "export PATH=${PATH}:~/<workspace>/greyhound" >> ~/.bashrc
```
