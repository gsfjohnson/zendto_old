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

if [ "$OSVER" -lt "14" ]; then
  # But only if we have just installed Apache 2.2
  APACHEVER="$( apache2 -v | grep -i version | perl -ne 'm/Apache\/(\d+\.\d+)\./i && print "$1"' )"
  if [ "x$APACHEVER" = "x2.2" ]; then
    shout And swapping mpm-worker for mpm-prefork.
    shout Otherwise the PHP we are about to build will not install.
    apt-get -y install apache2-mpm-worker- apache2-mpm-prefork
  fi
fi

exit 0

