#!/bin/bash

# Install ZendTo itself.

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
shout 'Install ZendTo itself (the easy bit)'
shout
shout =================================================================
shout
pause

shout Installing usage statistics graphing package
yum -y install rrdtool

shout ' '
mkdir -p "$SRCSTORE" && cd "$SRCSTORE" || exit 1
REPOFAILED=no
shout "Trying to use the ZendTo yum repository."
curl -O http://zend.to/files/zendto-repo.rpm || REPOFAILED=yes
rpm -Uvh zendto-repo.rpm || REPOFAILED=yes
if [ "x$REPOFAILED" = "xno" ]; then
  shout "Now to install ZendTo itself from the yum repository."
  shout "Drumroll please..."
  pause
  if rpm --quiet -q zendto; then
    shout Upgrading ZendTo
    yum -y upgrade zendto
  else
    shout Installing ZendTo
    yum -y install zendto
  fi
else
  shout "Failed to find ZendTo yum repository rpm."
  shout "So we will find and install the latest version without it."
  VERSION="$( curl --silent http://zend.to/files/ZendTo-Version )"
  shout "According to the zend.to website, the latest version is $VERSION."
  VERSION="$( prompt "Version of ZendTo to install" "4.20-1" "$VERSION")"
  curl -O http://zend.to/files/zendto-"$VERSION".noarch.rpm || {
    shout "Failed to find ZendTo rpm for version ${VERSION}."
    shout "Exiting..."
    exit 1
  }
  shout "About to install ZendTo version $VERSION"
  shout "Slightly shorter and quieter drumroll please..."
  pause
  rpm -Uvh "zendto-${VERSION}.noarch.rpm" || {
    shout Failed to install ZendTo rpm.
    shout Exiting...
    exit 1
  }
fi

shout
shout And set up graphing data
php /opt/zendto/sbin/rrdUpdate.php /opt/zendto/config/preferences.php | grep -v '^[0-9]*x[0-9]*$'

shout
shout ZendTo itself has been installed.
shout

if [ "$OSVER" -le "5" ]; then
  shout "As you are running ${OS} ${OSVER}, you will need to setup either"
  shout "a local MySQL database server, or a connection to a remote one."
  shout "This is documented on the ZendTo website. You will then need to"
  shout "tell ZendTo you are using MySQL and give it all the connection"
  shout "details, in /opt/zendto/config/preferences.php."
  shout
  pause 10
fi

exit 0
