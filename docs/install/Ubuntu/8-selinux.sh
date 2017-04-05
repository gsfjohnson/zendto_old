#!/bin/bash

# Install SELinux support for Apache and ZendTo (but not ClamAV)
# NOTE: This must be run after ZendTo itself is installed

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
shout Configure SELinux for Apache and ZendTo
shout
shout =================================================================
shout
pause

if [ "$SELINUX" = "disabled" ]; then
  shout You are not using SELinux so I will not try to configure it.
  shout ' '
  pause
  exit 0
fi

if [ "$OSVER" -ge "16" ]; then
  shout "Ubuntu do not appearing to be maintaining SELinux currently,"
  shout "so I will not attept to configure it."
  shout "If you wish to do so manually, please take a look at the"
  shout "step 8 SELinux install script in the Ubuntu subdirectory."
  shout
  pause
  exit 0
fi

shout 'This takes a while, please be patient.'
shout ' '
shout Setting booleans for httpd:
if [ "$OSVER" -ge "7" ]; then
  setBool httpd_builtin_scripting 1
  setBool httpd_can_connect_ldap 1
  setBool httpd_can_network_connect_db 1
  setBool httpd_can_sendmail 1
  setBool httpd_unified 0
else
  setBool httpd_builtin_scripting 1
  setBool httpd_can_network_connect 1
  setBool httpd_can_network_connect_db 1
  setBool httpd_can_sendmail 1
  setBool httpd_unified 0
fi
pause

shout Setting file contexts for /var/zendto
if [ "$OSVER" -le "5" ]; then
  semanage fcontext --add -s system_u -t httpd_sys_script_rw_t '/var/zendto(/.*)?'
  semanage fcontext --add -s system_u -t httpd_sys_script_ra_t '/var/zendto/zendto.log(.*)?'
  semanage fcontext --add -s system_u -t httpd_sys_content_t '/var/zendto/rrd(/.*)?'
else
  semanage fcontext --add -s system_u -t httpd_sys_rw_content_t '/var/zendto(/.*)?'
  semanage fcontext --add -s system_u -t httpd_sys_ra_content_t '/var/zendto/zendto.log(.*)?'
  semanage fcontext --add -s system_u -t httpd_sys_content_t '/var/zendto/rrd(/.*)?'
fi
restorecon -F -R /var/zendto

shout Setting file contexts for /opt/zendto
if [ "$OSVER" -le "5" ]; then
  HTTPDRW='httpd_sys_script_rw_t'
else
  HTTPDRW='httpd_sys_rw_content_t'
fi
# These 4 are now under /var/zendto.
#semanage fcontext --add -s system_u -t $HTTPDRW '/opt/zendto/templates_c(/.*)?'
#semanage fcontext --add -s system_u -t $HTTPDRW '/opt/zendto/cache(/.*)?'
#semanage fcontext --add -s system_u -t $HTTPDRW '/opt/zendto/myzendto.templates_c(/.*)?'
#semanage fcontext --add -s system_u -t $HTTPDRW '/opt/zendto/library(/.*)?'
semanage fcontext --add -s system_u -t httpd_sys_content_t '/opt/zendto/config(/.*)?'
semanage fcontext --add -s system_u -t httpd_sys_content_t '/opt/zendto/lib(/.*)?'
semanage fcontext --add -s system_u -t httpd_sys_content_t '/opt/zendto/templates(/.*)?'
semanage fcontext --add -s system_u -t httpd_sys_content_t '/opt/zendto/www(/.*)?'
semanage fcontext --add -s system_u -t httpd_sys_content_t '/opt/zendto/myzendto.templates(/.*)?'
semanage fcontext --add -s system_u -t httpd_sys_content_t '/opt/zendto/myzendto.www(/.*)?'
restorecon -F -R /opt/zendto

shout Setting file context for ZendTo nightly statistics cron job in /etc/cron.d
semanage fcontext --add -s system_u -t system_cron_spool_t /etc/cron.d/zendto
restorecon -v -F -R /etc/cron.d
pause

shout Resetting file context for other places we have touched:
shout Sendmail and Postfix: /etc/mail and /etc/postfix
restorecon -v -i -F -R /etc/mail /etc/postfix
pause
shout PHP: /etc/php.ini /etc/php.d
restorecon -v -i -F -R /etc/php.ini /etc/php.d
pause
shout Apache: /etc/httpd/conf.d
restorecon -v -i -F -R /etc/httpd/conf.d
pause
shout ClamAV: /etc/clamd.conf /etc/clamd.d
restorecon -v -i -F -R /etc/clamd.conf /etc/clamd.d
pause

shout
shout SELinux has been configured: Apache, ZendTo, email, PHP, Clamd
shout

exit 0

