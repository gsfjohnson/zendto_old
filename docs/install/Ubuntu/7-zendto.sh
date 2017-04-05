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
shout 'Install ZendTo itself and configure email sending'
shout
shout =================================================================
shout
pause


shout Installing usage statistics graphing package
apt-get -y install rrdtool

# Need nc for determining SMTP server ports
if which nc >/dev/null 2>&1; then
  shout netcat is already installed.
else
  shout Installing netcat
  apt-get -y install netcat-openbsd
fi

# Do we want to use the repo?
if [ "x$USEREPO" = "x" ]; then
  # This setting will be replaced with n if a beta installer
  USEREPO=y
fi

shout ' '
mkdir -p "$SRCSTORE" && cd "$SRCSTORE" || exit 1
REPOFAILED=no
if [ "x$USEREPO" = "xy" ]; then
  shout "Trying to use the ZendTo apt repository."
  curl -O http://zend.to/files/zendto-repo.deb || REPOFAILED=yes
  dpkg -i zendto-repo.deb || REPOFAILED=yes
else
  # Fake repo failure, as we didn't want to use it anyway
  REPOFAILED=yes
fi

if [ "x$REPOFAILED" = "xno" ]; then
  apt-get update
  shout "Now to install ZendTo itself from the apt repository."
  shout "Drumroll please..."
  pause
  # Is it already installed? If so, upgrade rather than install
  ( if dpkg -l | awk '{ print $2 }' | grep -q '^zendto$'; then
      # Sorry about the force-yes. I haven't figured secure APT yet.
      shout Upgrading ZendTo
      apt-get -y --force-yes upgrade zendto
    else
      # Sorry about the force-yes. I haven't figured secure APT yet.
      shout Installing ZendTo
      apt-get -y --force-yes install zendto
    fi
  ) || {
    # If either of those failed...
    shout Failed to install ZendTo from the apt repository.
    shout Exiting...
    exit 1
  }
else
  shout "Failed to find ZendTo apt repository deb."
  shout "So we will find and install the latest version without it."
  VERSION="$( curl --silent http://zend.to/files/ZendTo-Version )"
  shout "According to the zend.to website, the latest version is $VERSION."
  VERSION="$( prompt "Version of ZendTo to install" "4.19-1" "$VERSION")"
  curl -O http://zend.to/files/zendto_"$VERSION".deb || {
    shout "Failed to find ZendTo deb for version ${VERSION}."
    shout "Exiting..."
    exit 1
  }
  shout "About to install ZendTo version $VERSION"
  shout "Slightly shorter and quieter drumroll please..."
  pause
  # Attempt to install it, install any outstanding deps,
  # try again to be sure.
  # Only actually care if the the last one installs correctly.
  ( dpkg -i "zendto_${VERSION}.deb";
    apt-get -y -f install;
    dpkg -i "zendto_${VERSION}.deb"
  ) || {
    shout Failed to install ZendTo deb package.
    shout Exiting...
    exit 1
  }
fi

#OBSOLETE for versions 4.21 onwards
#OBSOLETE shout
#OBSOLETE if [ "$OSVER" -ge "16" ]; then
#OBSOLETE   shout "Disabling the 'useRealProgressBar' setting as it"
#OBSOLETE   shout "is not supported in PHP 7 and above."
#OBSOLETE   pause
#OBSOLETE   #  'useRealProgressBar'   => TRUE,
#OBSOLETE   # Change the TRUE (or whatever it may say) to FALSE
#OBSOLETE   perl -pi -e "s/^(\s*'useRealProgressBar'\s*=>\s*)[^,]+,/\$1FALSE,/" /opt/zendto/config/preferences.php
#OBSOLETE fi


shout And set up graphing data
php /opt/zendto/sbin/rrdUpdate.php /opt/zendto/config/preferences.php | grep -v '^[0-9]*x[0-9]*$'

configurePHPMailer

shout
shout ZendTo itself has been installed.
shout

exit 0
