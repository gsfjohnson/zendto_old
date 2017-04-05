#!/bin/bash

# Install a new ZendTo installation into an otherwise-empty
# CentOS 5/6/7 or RedHat Enterprise 5/6/7 or Ubuntu 14 server.
#
# Need to install:
# 
# 1. Dev tools & web server
# 2. Rebuild PHP
# 3. ClamAV
# 4. Firewall
# 5. httpd & PHP config. (needs PHP to be there)
# OBSOLETE 6. email <<=== Now configures PHPMailer at the end of 7.
# 7. ZendTo itself
# 8. SELinux
# 9. Leave them to edit preferences.php (with some notes)
#    and add a local user if necessary.
#    Must tell them how to test AD and/or LDAP.


# Setup stuff we need later.
# This script exports everything needed by other parts.
. lib/functions.sh

if [ "x$OS" = "xubuntu" ]; then
  export HERESUB="$HERE/Ubuntu"
elif [ "x$OS" = "xredhat" -o "x$OS" = "xcentos" ]; then
  export HERESUB="$HERE/CentOS-RedHat"
else
  shout ' '
  shout 'Sorry, I only know about RedHat Enterprise, CentOS and Ubuntu.'
  shout ' '
  shout 'Exiting...'
  exit 1
fi

export OK='\n\n\n\n\nIs it okay for me to'

#
# This asks the user if it is okay to start each part of the installation process.
# They may only want some of it done if the server is already partially setup.
#
# It will bail out immediately if any of the scripts return non-zero.
#

runIfYes "$OK install the web server and development tools (this should not overwrite anything)" \
"$HERESUB/1-devtools.sh"    && \
runIfYes "$OK rebuild PHP if necessary to support big uploads, and install PHP modules" \
"$HERESUB/2-php.sh" && \
runIfYes "$OK install and set up ClamAV (with SELinux config if necessary)" \
"$HERESUB/3-clamav.sh"      && \
runIfYes "$OK add firewall rules for ssh, http and https" \
"$HERESUB/4-firewall.sh"    && \
runIfYes "$OK create the ZendTo http website in your Apache config and configure PHP" \
"$HERESUB/5-httpd-php.sh"       && \
#OBSOLETE for versions 4.21 onwards - now done at the end of stage 7
#OBSOLETE runIfYes "$OK install and set up email sending if not already done" \
#OBSOLETE "$HERESUB/6-email.sh"       && \
runIfYes "$OK install the ZendTo package itself and configure email sending" \
"$HERESUB/7-zendto.sh"      && \
runIfYes "$OK configure SELinux for ZendTo" \
"$HERESUB/8-selinux.sh"     && \
\
echo -en '\033[1m' && \
cat <<EOMESG1

=====================================================================
=====================================================================

Well, it looks like we made it. Yay!

You will need to reboot the server and view the home page once
before going any further.

** To quickly test it **
1. Reboot.
2. View this server's home page in a web browser.
3. Make sure you did not skip step 2 !
EOMESG1

if [ "x$OS" = "xubuntu" ]; then
  echo '4. sudo -i /opt/zendto/bin/adduser.php'
else
  echo '4. su -'
  echo '   /opt/zendto/bin/adduser.php'
fi

cat <<EOMESG2
   That will show you the syntax to use.
5. Use it to add a single test user.
6. Login to the website and drop off some files.

Now go and configure ZendTo itself in
/opt/zendto/config/preferences.php and
/opt/zendto/config/zendto.conf

For help configuring ZendTo for Active Directory, see
http://zend.to/activedirectory.php

EOMESG2
echo -e '\033[0m'

exit 0

