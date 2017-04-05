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

shout Installing yum groups '"Development Tools" and "Web Server"'
pause
if [ "$OSVER" -ge "7" ]; then
  yum -y --exclude='php*' groups install "Development Tools" "Web Server"
  shout Enabling httpd on next boot
  systemctl enable httpd
else
  # RHEL6 only notices the 1st group in the command, so split this into 2
  yum -y --exclude='php*' groupinstall "Development Tools"
  yum -y --exclude='php*' groupinstall "Web Server"
  shout Enabling httpd on next boot
  chkconfig httpd on
fi
pause

# Install the EPEL repo
shout Installing the EPEL extra packages repo
pause
if [ "$OS" = "centos" ]; then
  yum -y install epel-release
else
  yum -y install curl
  curl -O https://dl.fedoraproject.org/pub/epel/epel-release-latest-"$OSVER".noarch.rpm
  rpm -Uvh epel-release-latest-"$OSVER".noarch.rpm || {
    if [ -f /etc/yum.repos.d/epel.repo ]; then
      shout
      shout 'I could not get and install the RPM that sets up the EPEL repo,'
      shout 'but you appear to probably have it installed already.'
      shout 'I will carry on...'
      pause
    else
      shout
      shout 'Eek! Could not get and install the RPM that sets up the EPEL repo.'
      shout 'Please find it on fedoraproject.org and install it, then re-run this script.'
      shout 'Exiting...'
      exit 1
    fi
  }
  rm -f epel-release-latest-"$OSVER".noarch.rpm
fi

exit 0

