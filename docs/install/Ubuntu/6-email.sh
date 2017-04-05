#!/bin/bash

# Setup MTA for ZendTo

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
shout Setup Postfix or sendmail to send email
shout
shout =================================================================
shout
pause

configure_postfix() {
  CONF=/etc/postfix/main.cf
  cp -f $CONF $CONF.zendto
  shout
  shout "I will configure Postfix by setting a few"
  shout "settings in $CONF."
  shout "None of the rest of the file will be changed."
  shout "If you do not like those new settings, please check"
  shout "the file and remove or change them to suit your site."
  shout "I have backed up your file to $CONF.zendto."
  shout
  # If they have a relayhost already, don't replace it.
  grep -E -q '^relayhost\s*=\s*\S+' $CONF || {
    RELAY="smtp.$(hostname --domain)"
    RELAY="$(prompt "Fully-qualified name of your SMTP server" "smtp.your-domain.com" "$RELAY")"
    setmaincf "$CONF" 'relayhost' "$RELAY"
  }
  #setmaincf "$CONF" 'myorigin' '$mydomain'
  #setmaincf "$CONF" 'inet_interfaces' 'localhost'
  #setmaincf "$CONF" 'mynetworks_style' 'host'

  # Are they using Postfix at the moment
  if [ "$OSVER" -le "14" ]; then
    shout "The postfix service will need to be restarted."
    shout "I will not do that, so you can check I have not"
    shout "broken any existing postfix main.cf settings."
    shout "To restart it, either reboot or"
    shout "service postfix restart"
    pause
  else
    # Systemd on Ubuntu 16 and above
    if systemctl --quiet is-enabled postfix.service >/dev/null 2>&1; then
      shout "The postfix service will need to be restarted."
      shout "I will not do that, so you can check I have not"
      shout "broken any existing postfix main.cf settings."
      shout "To restart it, either reboot or"
      shout "systemctl restart postfix.service"
      pause
    fi
  fi
}

configure_sendmail() {
  CONF=/etc/mail/sendmail.mc
  cp -f $CONF $CONF.zendto
  shout
  shout "I will configure sendmail by setting"
  shout "the value of SMART_HOST in your $CONF"
  shout "if it has not been set."
  shout "I will then rebuild your sendmail.cf"
  shout "file from that."
  shout "I have backed up your file to $CONF.zendto."

  # Can we find a setting for SMART_HOST?
  shout
  if grep -q "^define(\`SMART_HOST'," $CONF; then
    shout I found you already have SMART_HOST set.
    shout I will not touch sendmail.mc nor rebuild your sendmail.cf.
  else
    RELAY="smtp.$(hostname --domain)"
    RELAY="$(prompt "Fully-qualified name of your SMTP server" "smtp.your-domain.com" "$RELAY")"
    shout "Setting your SMART_HOST to $RELAY"
    NEWLINE="define(\`SMART_HOST', \`$RELAY')dnl"
    LINENUM="$( grep -En "^dnl *define\(\`SMART_HOST'," $CONF | tail -1 | cut -d: -f1 )"
    if [ "x$LINENUM" = "x" ]; then
      # Not found, so appens
      echo "$NEWLINE" >> $CONF
    else
      # Found commented out, so replace
      sed -i -e "$LINENUM c \\$NEWLINE" $CONF
    fi
    rpm -q --quiet sendmail-cf || {
      shout Installing the sendmail-cf package.
      yum -y install sendmail-cf
    }
    shout Rebuilding your sendmail.cf file.
    pushd /etc/mail
    make
    popd >/dev/null

    # Are they using sendmail at the moment
    shout
    if [ "$OSVER" -le "6" ]; then
      if chkconfig --list sendmail 2>/dev/null | grep -q 3:on; then
        shout "The sendmail service will need to be restarted."
        shout "I will not do that, so you can check I have not"
        shout "broken any existing sendmail.mc settings."
        shout "To restart it, either reboot or"
        shout "service sendmail restart"
        pause
      fi
    else
      # Systemd on Ubunt 16 and above
      if systemctl --quiet is-enabled sendmail.service >/dev/null 2>&1; then
        shout "The sendmail service will need to be restarted."
        shout "I will not do that, so you can check I have not"
        shout "broken any existing sendmail.mc settings."
        shout "To restart it, either reboot or"
        shout "systemctl restart sendmail.service"
        pause
      fi
    fi
  fi
  pause
}


DONE=no
if [ -d /etc/postfix ]; then
  shout Found Postfix.
  configure_postfix
  DONE=yes
elif [ -d /etc/mail -o -d /etc/sendmail ]; then
  shout Found sendmail.
  configure_sendmail
  DONE=yes
else
  shout 'I could not find any mail transport software'
  shout '(such as Postfix or sendmail) installed on this server.'
  shout 'You might possibly have Exim or qmail installed,'
  shout 'but I do not know how to configure them.'
  shout ' '
  shout 'Without a mail transport (MTA) ZendTo will not work.'
  shout ' '
  shout 'Would you like me to install and configure Postfix'
  if yesno "for you now" "y"; then
    shout
    shout Okay, installing and configuring Postfix for you.
    pause
    export DEBIAN_FRONTEND=noninteractive
    apt-get -y install postfix
    #  systemctl disable sendmail.service >/dev/null 2>&1
    #  systemctl disable exim.service >/dev/null 2>&1
    #  systemctl enable postfix.service
    configure_postfix
    DONE=yes
  fi
fi

shout
if [ "$DONE" = "yes" ]; then
  shout Email sending has been configured.
else
  shout WARNING: Your system will need to be able to send email to work
  shout WARNING: properly. You will need to set this up by hand before
  shout WARNING: you attempt to use ZendTo.
  shout For info, ZendTo sends email via the PHP 'mail()' function.
fi
shout

exit 0

