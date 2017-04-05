#!/bin/bash

# Install and setup httpd for ZendTo

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
shout Configure web server
shout
shout =================================================================
shout
pause

# Set up httpd
HTTPDCONF=/etc/httpd/conf.d/zendto.conf
if [ -f $HTTPDCONF ]; then
  shout Looks like you already have a ZendTo website
  shout configured here. I will leave it alone.
else
  SERVERNAME="$(hostname --fqdn)"
  shout Creating http ZendTo website definition in
  shout $HTTPDCONF
  shout "for ServerName $SERVERNAME"
  if [ "$OSVER" -lt "7" ]; then
    cat <<EOHTTPD > $HTTPDCONF
<VirtualHost *:80>
  ServerName $SERVERNAME
  DocumentRoot "/opt/zendto/www"
  <Directory "/opt/zendto/www">
    Options Indexes FollowSymLinks MultiViews
    # AllowOverride controls what directives may be placed in .htaccess files.
    AllowOverride All
    # Controls who can get stuff from this server file
    Order allow,deny
    Allow from all
    # This is for newer Apache in RHEL/CentOS 7
    #Require all granted
  </Directory>
</VirtualHost>
EOHTTPD
  else
    cat <<EOHTTP2 > $HTTPDCONF
<VirtualHost *:80>
  ServerName $SERVERNAME
  DocumentRoot "/opt/zendto/www"
  <Directory "/opt/zendto/www">
    Options Indexes FollowSymLinks MultiViews
    # AllowOverride controls what directives may be placed in .htaccess files.
    AllowOverride All
    # Controls who can get stuff from this server file
    Require all granted
    # This is for old Apache before RHEL/CentOS 7
    #Order allow,deny
    #Allow from all
  </Directory>
</VirtualHost>
EOHTTP2
  fi
  shout
  shout I will leave you to setup the https one.
  shout Sorry about that.
  pause 7
fi

# Select the right time zone as we need it for php.ini
shout I need to know which timezone you are in.
shout
pause
MYTZ="$(tzselect | tail -1)"
echo "$MYTZ"
echo
shout "Thank you, got your time zone as $MYTZ"
shout "Setting your /etc/localtime to $MYTZ"
ln -sf /usr/share/zoneinfo/"$MYTZ" /etc/localtime
pause

# Setup php.ini and /etc/php.d/apc.ini or apcu.ini
shout Configuring PHP
pause

# Set configuration in php.ini and apc.ini (5+6) or apcu.ini (7)
F=/etc/php.ini
shout Patching $F
cp -f $F $F.zendto
setphpini $F date.timezone "$MYTZ"
setphpini $F max_execution_time 7200
setphpini $F max_input_time 7200
setphpini $F memory_limit 300M
setphpini $F error_reporting 'E_ALL & ~E_NOTICE'
setphpini $F display_errors Off
setphpini $F display_startup_errors Off
setphpini $F log_errors On
setphpini $F post_max_size 50000M
setphpini $F file_uploads On
setphpini $F upload_tmp_dir /var/zendto/incoming
setphpini $F upload_max_filesize 50G
setphpini $F max_file_uploads 200

for F in apc apcu
do
  G="/etc/php.d/${F}.ini"
  if [ -f $G ]; then
    shout Patching $G
    cp -f $G $G.zendto
    setphpini $G ${F}.ttl 7200
    setphpini $G ${F}.gc_ttl 7200
    setphpini $G ${F}.slam_defense 0
    setphpini $G ${F}.rfc1867 1
    setphpini $G ${F}.rfc1867_ttl 7200
    setphpini $G ${F}.max_file_size 50G
  fi
done

shout
shout Your web server and PHP ini files should now be
shout configured to run ZendTo on this server.
shout As mentioned above, you will need to setup your
shout own https website, along with the necessary SSL
shout certificate and keys.
shout To find the basic settings for ZendTo, look in
shout $HTTPDCONF
shout

exit 0

