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
SERVERNAME="$(hostname --fqdn)"
CONFD=/etc/httpd/conf.d
HTTPDCONF=$CONFD/zendto.conf
HTTPDCONFS=$CONFD/zendto-ssl.conf
SSLCONF=$CONFD/ssl.conf
if [ -f $HTTPDCONF ]; then
  shout Looks like you already have a ZendTo website
  shout configured here. I will leave it alone.
else
  shout Creating http ZendTo website definition in
  shout $HTTPDCONF
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
  if [ -f "$SSLCONF" ]; then
    shout and commenting out default HTTPS site definition.
    sed -i '/^<VirtualHost /,/^<\/VirtualHost/ s/^/#ZendTo /' "$SSLCONF"
  fi

  cat <<EOHTTPDS > $HTTPDCONFS
<IfModule mod_ssl.c>

<VirtualHost *:443>
  ServerName $SERVERNAME
  DocumentRoot "/opt/zendto/www"

  # Enable SSL for this virtual host.
  SSLEngine on
  CustomLog logs/ssl_access_log combined
  ErrorLog  logs/ssl_error_log
  LogLevel warn

  # Where your SSL certificate and private key live.
  SSLCertificateFile    /etc/pki/tls/certs/zendto-selfsigned-cert.pem
  SSLCertificateKeyFile /etc/pki/tls/private/zendto-selfsigned-key.pem

  # ZendTo: Not needed for a self-signed certificate like the
  #         sample one above. But when you setup your proper
  #         certificate, put the Certificate Authority's certificate
  #         chain in here, and of course uncomment it!
  #SSLCertificateChainFile /etc/pki/tls/certs/server-chain.crt

  # Uncomment this when using client certificate authentication
  #SSLCACertificateFile /etc/pki/tls/certs/ca-bundle.crt

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

  if [ "$OSVER" -lt "6" ]; then
    cat <<EOHTTPS5 >> $HTTPDCONFS
# ZendTo: For CentOS / RedHat 5
# Generated by https://mozilla.github.io/server-side-tls/ssl-config-generator/
SSLProtocol             all -SSLv2 -SSLv3
SSLCipherSuite          ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS
SSLHonorCipherOrder     on

</IfModule>
EOHTTPS5
  elif [ "$OSVER" -eq "6" ]; then
    cat <<EOHTTPS6 >> $HTTPDCONFS
# ZendTo: For CentOS / RedHat 6
# Generated by https://mozilla.github.io/server-side-tls/ssl-config-generator/
SSLProtocol             all -SSLv2 -SSLv3
SSLCipherSuite          ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS
SSLHonorCipherOrder     on

</IfModule>
EOHTTPS6
  else
    cat <<EOHTTPS7 >> $HTTPDCONFS
# ZendTo: For CentOS / RedHat 7
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
EOHTTPS7
  fi

  chmod u=rw,go=r $HTTPDCONF $HTTPDCONFS
  shout Generating a self-signed SSL key and certificate for you.
  ( echo GB; echo Hampshire; echo Southampton; echo ZendTo User Site; echo; \
    echo $SERVERNAME; echo ) | \
  openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -keyout /etc/pki/tls/private/zendto-selfsigned-key.pem -out /etc/pki/tls/certs/zendto-selfsigned-cert.pem >/dev/null 2>&1

  shout Enabling ssl, rewrite and headers modules.
  CONFFILE=/etc/httpd/conf/httpd.conf
  for M in ssl rewrite headers
  do
    if [ "$OSVER" -lt "7" ]; then
      # CentOS 5 and 6
      if grep -q '^ *LoadModule .*mod_'$M'.so' $CONFFILE /etc/httpd/conf.d/*.conf; then
        :
      else
        # We have to edit httpd.conf directly
        # Find the line number of the last "LoadModule" line
        LINE="$( grep -n '^LoadModule ' $CONFFILE | tail -1 | cut -d: -f1 )"
        if [ "x$LINE" = "x" ]; then
          shout Sorry, I cannot find the LoadModule lines in your $CONFFILE.
          shout You will need to check mod_$M is enabled yourself.
          shout It most likely is already.
        else
          sed -i $LINE' a \\LoadModule '$M'_module modules/mod_'$M'.so' $CONFFILE
        fi
      fi
    else
      # CentOS 7 has a conf.modules.d directory
      if grep -q '^ *LoadModule .*mod_'$M'.so' /etc/httpd/conf.modules.d/*.conf; then
        :
      else
        echo "LoadModule ${M}_module modules/mod_${M}.so" >> /etc/httpd/conf.modules.d/zendto.conf
      fi
    fi
  done

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
ln -sf /usr/share/zoneinfo/"$MYTZ" /etc/localtime
pause

# Setup php.ini and /etc/php.d/apc.ini or apcu.ini
shout
shout Configuring PHP
pause

# Set configuration in php.ini
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

#APC for F in apc apcu
#APC do
#APC   G="/etc/php.d/${F}.ini"
#APC   if [ -f $G ]; then
#APC     shout Patching $G
#APC     cp -f $G $G.zendto
#APC     setphpini $G ${F}.ttl 7200
#APC     setphpini $G ${F}.gc_ttl 7200
#APC     setphpini $G ${F}.slam_defense 0
#APC     setphpini $G ${F}.rfc1867 1
#APC     setphpini $G ${F}.rfc1867_ttl 7200
#APC     setphpini $G ${F}.max_file_size 50G
#APC   fi
#APC done

shout
shout Your web server and PHP ini files should now be
shout configured to run ZendTo on this server.
shout As mentioned above, you will need to setup your
shout own https SSL certificate and keys.
shout To find the basic settings for ZendTo, look in
shout '    '$HTTPDCONF
shout '    '$HTTPDCONFS
shout

exit 0

