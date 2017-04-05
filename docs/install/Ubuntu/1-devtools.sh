#!/bin/bash

# Install entire Development Tools and Web Server groups

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
shout Install web server and development tools we will need
shout
shout =================================================================
shout

pause
apt-get update
if [ "$OSVER" -lt "16" ]; then
  shout Installing basic development tools
  apt-get -y install build-essential dpatch fakeroot devscripts equivs lintian quilt
fi

shout Installing web server
apt-get -y install apache2

exit 0

