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
shout Configure web server and PHP
shout
shout =================================================================
shout
pause

# Set up httpd
HTTPDCONF=/etc/apache2/sites-available/001-zendto.conf
if [ -f $HTTPDCONF ]; then
  shout Looks like you already have a ZendTo website
  shout configured here. I will leave it alone.
else
  SERVERNAME="$(hostname --fqdn)"
  shout Creating http ZendTo website definition in
  shout "$HTTPDCONF"
  shout "for ServerName $SERVERNAME"
  cat <<EOHTTPD > $HTTPDCONF
<VirtualHost *:80>
  ServerName $SERVERNAME
  DocumentRoot "/opt/zendto/www"
  <Directory "/opt/zendto/www">
    Options Indexes FollowSymLinks MultiViews
    # AllowOverride controls what directives may be placed in .htaccess files.
    AllowOverride All
    # Controls who can get stuff from this server file
    #Order allow,deny
    #Allow from all
    # This is for newer Apache in RHEL/CentOS 7 and Ubuntu
    Require all granted
  </Directory>

  # Uncomment this to start getting the WebDAV support working.
  # You also need to run these 3 commands as root:
  #     a2enmod dav_fs
  #     a2enmod dav
  #     service apache2 restart
  #Alias /library /var/zendto/library
  #<Location /library>
  #        DAV on
  #        AuthUserFile /var/zendto/library.passwd
  #        AuthName "ZendTo Library"
  #        AuthType Basic
  #        Require valid-user
  #</Location>

</VirtualHost>
EOHTTPD
  chmod u=rw,go=r $HTTPDCONF
  shout Replacing the default site with the ZendTo one.
  a2ensite 001-zendto
  a2dissite 000-default
  a2enmod ssl
  a2enmod rewrite
  service apache2 restart
  shout
  shout I will leave you to setup the https one.
  shout Sorry about that.
  shout I have at least enabled the modules you will need.
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
ln -sf "/usr/share/zoneinfo/$MYTZ" /etc/localtime
pause

# Setup php.ini and /etc/php.d/apc.ini or apcu.ini
shout Configuring PHP
pause

# Set configuration in php.ini and apc.ini (5+6) or apcu.ini (7)
if [ "$OSVER" -ge "16" ]; then
  INIS="$( ls -d /etc/php/*/{cli,apache2}/php.ini )"
else
  INIS="$( ls -d /etc/php*/{cli,apache2}/php.ini )"
fi
for F in $INIS
do
  shout "Patching $F"
  cp -f "$F" "$F.zendto"
  setphpini "$F" date.timezone "$MYTZ"
  setphpini "$F" max_execution_time 7200
  setphpini "$F" max_input_time 7200
  setphpini "$F" memory_limit 300M
  setphpini "$F" error_reporting 'E_ALL & ~E_NOTICE'
  # Only do these for apache2, not cli.
  [[ "$F" =~ '/apache2/' ]] && setphpini "$F" display_errors Off
  [[ "$F" =~ '/apache2/' ]] && setphpini "$F" display_startup_errors Off
  setphpini "$F" log_errors On
  setphpini "$F" post_max_size 50000M
  setphpini "$F" file_uploads On
  setphpini "$F" upload_tmp_dir /var/zendto/incoming
  setphpini "$F" upload_max_filesize 50G
  setphpini "$F" max_file_uploads 200
  shout ' '
done

if [ "$OSVER" -ge "16" ]; then
  shout
  shout "Sorry, but the APCu module version 5 no longer has"
  shout "any of the upload progress features in it."
  shout "Previous versions will not build against PHP 7,"
  shout "and so the 'useRealProgressBar' setting in"
  shout "/opt/zendto/config/preferences.php must be set"
  shout "to FALSE to disable this feature."
  shout
  pause 10
  INIS="$( ls -d /etc/php/*/mods-available/*apcu.ini )"
else
  INIS="$( ls -d /etc/php*/mods-available/*apcu.ini )"
fi
for F in $INIS
do
  if [ -f "$F" ]; then
    shout Patching "$F"
    cp -f "$F" "$F.zendto"
    setphpini "$F" apc.ttl 7200
    setphpini "$F" apc.gc_ttl 7200
    setphpini "$F" apc.slam_defense 0
    setphpini "$F" apc.rfc1867 1
    setphpini "$F" apc.rfc1867_ttl 7200
    setphpini "$F" apc.max_file_size 50G
    shout ' '
  fi
done

if [ "$OSVER" -lt "16" ]; then
  shout Removing any rogue comment lines in PHP imap.ini
  sed -i.zendto '/^#/ d' /etc/php*/mods-available/*imap.ini
fi


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

