#!/bin/bash

# Setup firewall for Apache

# If we haven't read functions.sh by now, then read it
if [ "x$ZTFUNCTIONS" = "x" ]; then
  if [ -f lib/functions.sh ]; then
    . lib/functions.sh
  elif [ -f ../lib/functions.sh ]; then
    cd ..
    . lib/functions.sh
  else
    echo 'Sorry, I need to be able to source functions.sh first.'
    echo Exiting...
    exit 1
  fi
fi

shout
shout =================================================================
shout
shout Configure firewall to allow in ssh, http and https traffic
shout
shout =================================================================
shout
pause

shout Install ufw firewall if not already installed.
DEBIAN_FRONTEND=nonteractive apt-get -y install ufw

shout Configuring firewall
ufw allow "OpenSSH"         # 22/tcp
ufw allow "Apache Full"     # 80/tcp and 443/tcp
ufw default allow outgoing
ufw default deny incoming
yes | ufw enable

shout
shout Your firewall has been configured to allow in http and https traffic
shout on ports 80/tcp and 443/tcp, and ssh traffic on port 22/tcp.
shout

exit 0

