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
SERVERNAME="$(hostname --fqdn)"
if [ "$OSVER" -lt "14" ]; then
  HTTPDCONF=/etc/apache2/sites-available/001-zendto
  HTTPDCONFS=/etc/apache2/sites-available/001-zendto-ssl
else
  HTTPDCONF=/etc/apache2/sites-available/001-zendto.conf
  HTTPDCONFS=/etc/apache2/sites-available/001-zendto-ssl.conf
fi
if [ -f $HTTPDCONF ]; then
  shout Looks like you already have a ZendTo HTTP website
  shout configured here. I will leave it alone.
else
  shout Creating HTTP ZendTo website definition in
  shout '    '$HTTPDCONF
  shout "for ServerName $SERVERNAME"
  cat <<EOHTTPD > $HTTPDCONF
<VirtualHost *:80>
  ServerName $SERVERNAME
  DocumentRoot "/opt/zendto/www"
  <Directory "/opt/zendto/www">
    Options Indexes FollowSymLinks MultiViews
    # This controls what directives may be placed in .htaccess files
    AllowOverride All
    # Controls who can get stuff from this server file
    <IfModule !mod_authz_core.c>
      # For Apache 2.2:
      Order allow,deny
      Allow from all
    </IfModule>
    <IfModule mod_authz_core.c>
      # For Apache 2.4:
      Require all granted
    </IfModule>
    #OLD Order allow,deny
    #OLD Allow from all
    #OLD  This is for newer Apache in RHEL/CentOS 7 and Ubuntu
    #OLD Require all granted
  </Directory>

  #HTTPS# This will force http to automatically redirect to https.
  #HTTPS<IfModule mod_rewrite.c>
  #HTTPS  RewriteEngine On
  #HTTPS  RewriteCond %{HTTPS} off
  #HTTPS  RewriteRule (.*) https://%{HTTP_HOST}%{REQUEST_URI}
  #HTTPS</IfModule>

  # Uncomment this to start getting the WebDAV support working.
  # I would recommend only doing this on the https site, and
  # not on this http one unless you cannot get a https certificate.
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
fi

if [ -f $HTTPDCONFS ]; then
  shout Looks like you already have a ZendTo HTTPS website
  shout configured here. I will leave it alone.
else
  shout Creating HTTPS ZendTo website definition in
  shout '    '$HTTPDCONFS
  shout "for ServerName $SERVERNAME"
  cat <<EOHTTPDS > $HTTPDCONFS
<IfModule mod_ssl.c>

<VirtualHost *:443>
  ServerName $SERVERNAME
  DocumentRoot "/opt/zendto/www"

  # Enable SSL for this virtual host.
  SSLEngine on
  CustomLog \${APACHE_LOG_DIR}/ssl_access.log combined
  ErrorLog  \${APACHE_LOG_DIR}/ssl_error.log

  # Where your SSL certificate and private key live.
  SSLCertificateFile    /etc/ssl/certs/zendto-selfsigned-cert.pem
  SSLCertificateKeyFile /etc/ssl/private/zendto-selfsigned-key.pem

  # ZendTo: Not needed for a self-signed certificate like the
  #         sample one above. But when you setup your proper
  #         certificate, put the Certificate Authority's certificate
  #         chain in here, and of course uncomment it!
  #SSLCertificateChainFile /etc/ssl/certs/server-ca.crt

  # Uncomment 1 of these 2 when using client certificate authentication
  #SSLCACertificatePath /etc/ssl/certs/
  #SSLCACertificateFile /etc/apache2/ssl.crt/ca-bundle.crt

  # HSTS (mod_headers is required) (15768000 seconds = 6 months)
  Header always set Strict-Transport-Security "max-age=15768000"

  # SSL Protocol Adjustments for MSIE:
  # MSIE 7 and newer should be able to use keepalive
  BrowserMatch "MSIE [17-9]" ssl-unclean-shutdown

  <FilesMatch "\.php$">
    SSLOptions +StdEnvVars
  </FilesMatch>

  <Directory "/opt/zendto/www">
    Options Indexes FollowSymLinks MultiViews
    # This controls what directives may be placed in .htaccess files
    AllowOverride All
    # Controls who can get stuff from this server file
    <IfModule !mod_authz_core.c>
      # For Apache 2.2:
      Order allow,deny
      Allow from all
    </IfModule>
    <IfModule mod_authz_core.c>
      # For Apache 2.4:
      Require all granted
    </IfModule>
    #OLD Order allow,deny
    #OLD Allow from all
    #OLD  This is for newer Apache in RHEL/CentOS 7 and Ubuntu
    #OLD Require all granted
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

EOHTTPDS

  if [ "$OSVER" -lt "14" ]; then
    cat <<EOHTTPS12 >> $HTTPDCONFS
# ZendTo: For Ubuntu 12
# Generated by https://mozilla.github.io/server-side-tls/ssl-config-generator/
SSLProtocol             all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1
SSLCipherSuite          ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256
SSLHonorCipherOrder     on

</IfModule>
EOHTTPS12
  elif [ "$OSVER" -lt "16" ]; then
    cat <<EOHTTPS14 >> $HTTPDCONFS
# ZendTo: For Ubuntu 14
# Generated by https://mozilla.github.io/server-side-tls/ssl-config-generator/
SSLProtocol             all -SSLv3
SSLCipherSuite          ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS
SSLHonorCipherOrder     on
SSLCompression          off
SSLUseStapling          on
SSLStaplingResponderTimeout 5
SSLStaplingReturnResponderErrors off
SSLStaplingCache        shmcb:/var/run/ocsp(128000)

</IfModule>
EOHTTPS14
  else
    cat <<EOHTTPS16 >> $HTTPDCONFS
# ZendTo: For Ubuntu 16
# Generated by https://mozilla.github.io/server-side-tls/ssl-config-generator/
SSLProtocol             all -SSLv3
SSLCipherSuite          ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS
SSLHonorCipherOrder     on
SSLCompression          off
SSLSessionTickets       off
SSLUseStapling          on
SSLStaplingResponderTimeout 5
SSLStaplingReturnResponderErrors off
SSLStaplingCache        shmcb:/var/run/ocsp(128000)

</IfModule>
EOHTTPS16
  fi

  chmod u=rw,go=r $HTTPDCONF $HTTPDCONFS
  shout Generating a self-signed SSL key and certificate for you.
  ( echo GB; echo Hampshire; echo Southampton; echo ZendTo User Site; echo; \
    echo $SERVERNAME; echo ) | \
  openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/zendto-selfsigned-key.pem -out /etc/ssl/certs/zendto-selfsigned-cert.pem >/dev/null 2>&1
  shout Replacing the default sites with the ZendTo one
  shout and its https version.
  a2dissite 000-default >/dev/null
  a2dissite default-ssl >/dev/null
  a2ensite 001-zendto >/dev/null
  a2ensite 001-zendto-ssl >/dev/null
  shout Enabling ssl, rewrite and headers modules.
  a2enmod ssl >/dev/null
  a2enmod rewrite >/dev/null
  a2enmod headers >/dev/null
  shout
  shout 'The http and https versions of your new ZendTo site'
  shout 'will be at the addresses'
  shout '    'http://$SERVERNAME
  shout and
  shout '    'https://$SERVERNAME
  shout
  shout 'I *can* configure the http site to automatically forward'
  shout all connections to the https site.
  shout But because I have just used a self-signed certificate,
  shout your web browser will complain loudly about the security
  shout of the https site.
  shout 
  shout 'If you want to show your boss the new site, this is a bad idea'
  shout 'so say "no" to the next question.'
  shout 'But if you are building a production site, it will save you'
  shout 'doing that step yourself, so say "yes" to the next question.'
  shout
  shout Would you like me to automatically forward http
  if yesno "connections straight to the https site" "n"; then
    sed -i 's/#HTTPS//g;' $HTTPDCONF
    shout Connections to http will go straight to https.
  fi
fi

# Select the right time zone as we need it for php.ini
shout
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

# Setup php.ini
shout
shout Configuring PHP
pause

# Set configuration in php.ini
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

#OBSOLETE for versions 4.21 onwards
#OBSOLETE if [ "$OSVER" -ge "16" ]; then
#OBSOLETE  shout
#OBSOLETE  shout "Sorry, but the APCu module version 5 no longer has"
#OBSOLETE  shout "any of the upload progress features in it."
#OBSOLETE  shout "Previous versions will not build against PHP 7,"
#OBSOLETE  shout "and so the 'useRealProgressBar' setting in"
#OBSOLETE  shout "/opt/zendto/config/preferences.php must be set"
#OBSOLETE  shout "to FALSE to disable this feature."
#OBSOLETE  shout
#OBSOLETE  pause 10
#OBSOLETE  INIS="$( ls -d /etc/php/*/mods-available/*apcu.ini )"
#OBSOLETEelse
#OBSOLETE  INIS="$( ls -d /etc/php*/mods-available/*apcu.ini )"
#OBSOLETEfi
#OBSOLETEfor F in $INIS
#OBSOLETEdo
#OBSOLETE  if [ -f "$F" ]; then
#OBSOLETE    shout Patching "$F"
#OBSOLETE    cp -f "$F" "$F.zendto"
#OBSOLETE    setphpini "$F" apc.ttl 7200
#OBSOLETE    setphpini "$F" apc.gc_ttl 7200
#OBSOLETE    setphpini "$F" apc.slam_defense 0
#OBSOLETE    setphpini "$F" apc.rfc1867 1
#OBSOLETE    setphpini "$F" apc.rfc1867_ttl 7200
#OBSOLETE    setphpini "$F" apc.max_file_size 50G
#OBSOLETE    shout ' '
#OBSOLETE  fi
#OBSOLETEdone

# NEW NEW Used to say < 16
if [ "$OSVER" -eq "14" ]; then
  shout Removing any rogue comment lines in PHP imap.ini
  sed -i.zendto '/^#/ d' /etc/php*/mods-available/*imap.ini 2>/dev/null
fi

shout 'Ignore warnings about "DocumentRoot does not exist".'
service apache2 restart
shout
pause

shout
shout Your web server and PHP ini files should now be
shout configured to run ZendTo on this server.
shout As mentioned above, you will need to setup your
shout own https SSL certificate and keys.
shout To find the basic settings for ZendTo, look in
shout $HTTPDCONF
shout $HTTPDCONFS
shout

exit 0

