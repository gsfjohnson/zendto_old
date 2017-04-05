#!/bin/bash

# Install ClamAV with SELinux support

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
shout Install and configure ClamAV
shout
shout =================================================================
shout
pause

shout Installing ClamAV packages
apt-get -y install clamav clamav-daemon

# Change default SelfCheck time from 1h to 10mins.
shout Making clamd notice new signatures much faster
sed -i.zendto '/^SelfCheck/ s/[0-9][0-9]*/600/' /etc/clamav/clamd.conf

shout Stop freshclam daemon so we can update signatures
if [ "$OSVER" -ge "16" ]; then
  systemctl stop clamav-freshclam
else
  /etc/init.d/clamav-freshclam stop
fi
shout Updating signatures  
shout '(Ignore errors about not being able to notify clamd)'
freshclam

shout Allowing ClamAV to read Apache files
usermod -a -G www-data clamav
# and the other way around!
usermod -a -G clamav www-data

shout Allowing ClamAV through AppArmor to read ZendTo uploads
if [ -d /etc/apparmor.d ]; then
  mkdir -p /etc/apparmor.d/local # Just in case
  APP=/etc/apparmor.d/local/usr.sbin.clamd
  # Create it if necessary
  if [ ! -f $APP ]; then
    :> $APP
    chown root:root $APP
    chmod 0644 $APP
  fi
  if fgrep -q zendto $APP; then
    shout No need, already done.
  else
    echo '# ZendTo settings (do not delete this line)' >> $APP
    echo '/var/zendto/** r,' >> $APP
  fi
  if [ -x /etc/init.d/apparmor ]; then
    /etc/init.d/apparmor restart
  else
    echo You will have to reboot to restart AppArmor before ZendTo will work.
  fi
else
  shout "You do not appear to have AppArmor installed."
fi

shout Starting ClamAV and freshclam daemons
if [ "$OSVER" -ge "16" ]; then
  systemctl stop clamav-freshclam
  systemctl restart clamav-daemon
  systemctl start clamav-freshclam
else
  /etc/init.d/clamav-freshclam stop
  /etc/init.d/clamav-daemon restart
  /etc/init.d/clamav-freshclam start
fi

shout
shout ClamAV has been setup for you to work with ZendTo.
shout

exit 0

