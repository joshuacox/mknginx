# local-nginx
local-nginx docker container with everything built locally

### Usage 

`make temp`

run a  container temporarily to grab the config directory, you can then watch the startup with `make logs`, but not alot to see here, ctrl-c from the logs tail and

`make grab`

which will prompt you for a path, and then grab the directories necessary for you to have persistent configs, and place them in the path you just provided

`make nusite`

will prompt you for the necessary information to setup a new site proxy (usually to another container running on the same machine)

`make sitecert`

will get you a SSL/TLS certificate from LetsEncrypt

`make prod`

will run the nginx container with your new persistent setup
