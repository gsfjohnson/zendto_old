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

shout Setting file contexts for /var/zendto
if [ "$OSVER" -le "5" ]; then
  semanage fcontext --add -s system_u -t httpd_sys_script_rw_t '/var/zendto(/.*)?'
  echo -n 3
  semanage fcontext --add -s system_u -t httpd_sys_script_ra_t '/var/zendto/zendto.log(.*)?'
  echo -n 2
  semanage fcontext --add -s system_u -t httpd_sys_content_t '/var/zendto/rrd(/.*)?'
  echo 1
else
  echo -n 4
  semanage fcontext --add -s system_u -t httpd_sys_rw_content_t '/var/zendto(/.*)?'
  echo -n 3
  semanage fcontext --add -s system_u -t httpd_sys_ra_content_t '/var/zendto/zendto.log(.*)?'
  echo -n 2
  semanage fcontext --add -s system_u -t httpd_sys_content_t '/var/zendto/rrd(/.*)?'
  echo 1
fi
restorecon -F -R /var/zendto
shout ' '

shout Setting file contexts for /opt/zendto
if [ "$OSVER" -le "5" ]; then
  HTTPDRW='httpd_sys_script_rw_t'
else
  HTTPDRW='httpd_sys_rw_content_t'
fi
# These 4 are now under /var/zendto.
#semanage fcontext --add -s system_u -t $HTTPDRW '/opt/zendto/templates_c(/.*)?'
#echo -n 10
#semanage fcontext --add -s system_u -t $HTTPDRW '/opt/zendto/cache(/.*)?'
#echo -n 9
#semanage fcontext --add -s system_u -t $HTTPDRW '/opt/zendto/myzendto.templates_c(/.*)?'
#echo -n 8
#semanage fcontext --add -s system_u -t $HTTPDRW '/opt/zendto/library(/.*)?'
#echo -n 7
semanage fcontext --add -s system_u -t httpd_sys_content_t '/opt/zendto/config(/.*)?'
echo -n 6
semanage fcontext --add -s system_u -t httpd_sys_content_t '/opt/zendto/lib(/.*)?'
echo -n 5
semanage fcontext --add -s system_u -t httpd_sys_content_t '/opt/zendto/templates(/.*)?'
echo -n 4
semanage fcontext --add -s system_u -t httpd_sys_content_t '/opt/zendto/www(/.*)?'
echo -n 3
semanage fcontext --add -s system_u -t httpd_sys_content_t '/opt/zendto/myzendto.templates(/.*)?'
echo -n 2
semanage fcontext --add -s system_u -t httpd_sys_content_t '/opt/zendto/myzendto.www(/.*)?'
echo 1
restorecon -F -R /opt/zendto
shout ' '

shout Setting file context for ZendTo nightly statistics cron job in /etc/cron.d
semanage fcontext --add -s system_u -t system_cron_spool_t /etc/cron.d/zendto
pause 2
restorecon -v -F -R /etc/cron.d

shout Resetting file context for other places we have touched:
shout Sendmail and Postfix: /etc/mail and /etc/postfix
pause 2
restorecon -v -i -F -R /etc/mail /etc/postfix
shout PHP: /etc/php.ini /etc/php.d
pause 2
restorecon -v -i -F -R /etc/php.ini /etc/php.d
shout Apache: /etc/httpd/conf.d
pause 2
restorecon -v -i -F -R /etc/httpd/conf.d
shout ClamAV: /etc/clamd.conf /etc/clamd.d
pause 2
restorecon -v -i -F -R /etc/clamd.conf /etc/clamd.d

shout
shout SELinux has been configured: Apache, ZendTo, email, PHP, Clamd
shout

exit 0

