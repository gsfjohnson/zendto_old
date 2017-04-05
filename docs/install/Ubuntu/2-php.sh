#!/bin/bash

# Rebuild PHP with big-uploads support.

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
shout 'If not already supported, add "big-uploads" support'
shout '(uploads greater than 2GB) to PHP.'
shout
shout =================================================================
shout
pause

# Find the major version of PHP they have installed
# Nothing to do in PHP 7 and beyond!
PHPVER="$( dpkg -l | awk '{ print $2 }' | grep -E '^php[0-9.]+-common' | sed -e 's/^[a-zA-Z]*\([0-9.]*\).*$/\1/' )"
if [ "x$PHPVER" = "x" ]; then
  # PHP not installed, so we're going to simulate an install first
  # php-tidy is just a random module that they probably won't have.
  PHPVER="$( apt-get -s install php5-tidy 2>/dev/null | \
             grep -E '^(Inst|Conf)\s+php[0-9.]+-tidy' | \
             tail -1 | \
             sed -e 's/^[a-zA-Z]*\s*php\([^-]*\)-.*$/\1/' )"
fi
if [ "x$PHPVER" = "x" ]; then
  # PHP not installed, so we're going to simulate an install first
  # php-tidy is just a random module that they probably won't have.
  PHPVER="$( apt-get -s install php7.0-tidy | \
             grep -E '^(Inst|Conf)\s+php[0-9.]+-tidy' | \
             tail -1 | \
             sed -e 's/^[a-zA-Z]*\s*php\([^-]*\)-.*$/\1/' )"
fi
if [ "x$PHPVER" = "x" ]; then
  shout I cannot work out what version of PHP you will use.
  PHPDEF='5'
  [ "$OSVER" -gt "14" ] && PHPDEF='7.0'
  PHPVER="$( prompt "PHP version number" "$PHPDEF" "$PHPDEF" )"
fi
# Now have the whole version including any .0 or whatever
# So strip off anything after the first dot
PHPMAJOR="$( echo "$PHPVER" | sed -e 's/\..*$//' )"
if [ "$PHPMAJOR" -ge "7" ]; then
  shout 'Great news!'
  shout "You are using, or will use, version $PHPVER of PHP,"
  shout "so there is no rebuilding needed."
  shout "All I am going to do is install the PHP packages I need."
  pause
  apt-get -y install libapache2-mod-php php-common php php-cli \
          php-sqlite3 php-readline php-ldap php-intl php-gd    \
          php-enchant php-curl php-json php-imap php-mbstring
#APC           php-enchant php-curl php-json php-apcu php-imap php-mbstring
  shout ' '
  shout And enable them.
#APC   for MOD in curl enchant json sqlite3 gd imap ldap apcu pdo readline intl mbstring
  for MOD in curl enchant json sqlite3 gd imap ldap pdo readline intl mbstring
  do
    phpenmod -v ALL -s ALL "$MOD"
  done
  shout You should now have the PHP packages installed.
  exit 0
fi

PHPCOMMON="$(dpkg -l | awk '{ print $2 }' | grep '^php[.0-9]*-common$' | head -1)"
if [ "x$PHPCOMMON" = "x" ]; then
  shout Good, no PHP packages installed.
else
  shout I need to remove any existing PHP packages first,
  shout along with packages with depend on PHP, sorry:
  apt-cache rdepends --installed --recurse "$PHPCOMMON" | \
  grep '^  ' | grep -v ':' | sort | uniq | \
  while read p; do
    shout '  '${p}
    if [ "x$p" = "xzendto" ]; then
      shout '    This should not destroy your ZendTo configuration,'
      shout '    but I STRONGLY advise pressing Ctrl-C to stop now'
      shout '    and take a backup if you have not already done so.'
    fi
  done
  shout
  shout I am about to remove all those packages.
  pause 20
  apt-get -y remove $PHPCOMMON
fi
pause

if [ -d "$SRCSTORE" ]; then
  shout Deleting the contents of "$SRCSTORE"
  shout so I get a clean build.
  pause
  rm -rf "$SRCSTORE"
fi
mkdir -p "$SRCSTORE" && cd "$SRCSTORE" || exit 1

# Find the latest major release of PHP (5: in EPEL; 6: in CentOS; 7: in CentOS/RHEL).
shout Installing apt-file
apt-get -y install apt-file
shout Updating apt-file
apt-file --non-interactive update >/dev/null
shout Working out PHP package name prefix
NAME="$( apt-file --package-only -x find '^/usr/bin/php[\d.]*$' | sed -e 's/-.*$//' )"
if [ "x$NAME" = "x" ]; then
  shout I could not work out the packages that provide PHP.
  NAME="$(prompt "Prefix of PHP package names" "php5" "$NAME")"
fi

# Fetch PHP source and find where it was put
shout "Fetching $NAME source"
apt-get -y source "$NAME"
# Get the last php5-... directory name in alphabetical order
PHPSRCDIR="$( find "$NAME"-* -maxdepth 0 -type d -print0 | xargs -0 ls -d | tail -1 )"
while [ ! -d "$PHPSRCDIR/debian" ]; do
  shout 'Bother, I cannot find the "debian" directory within '"$PHPSRCDIR"
  PHPSRCDIR="$( prompt "Name of $NAME source directory within $SRCDIR" "php5-5.5.9+dfsg" "$PHPSRCDIR" )"
done

# Need to remove mysql-server from dependencies,
# but install it temporarily so the build process works.
export DEBIAN_FRONTEND=noninteractive
if dpkg-query -s mysql-server >/dev/null 2>&1; then
  shout mysql-server is already installed, so I will remember to leave it there.
  REMOVEMYSQL='no'
else
  shout Need to temporarily install mysql-server for the PHP tests.
  shout I will remove it again at the end.
  pause
  apt-get -y install mysql-server
  REMOVEMYSQL='yes'
fi
# And need to make sure it's stopped
if [ "$OSVER" -lt "16" ]; then
  shout Stopping MySQL
  service mysql stop 2>/dev/null
fi


shout Remove mysql-server from the PHP dependency list
sed -i.zendto -e '/^\s*mysql-server,\s*$/ d' "$PHPSRCDIR/debian/control"
shout And let mysqld through AppArmor for PHP tests
chmod go+x ~
echo "$SRCSTORE"'/** rw,' >> /etc/apparmor.d/local/usr.sbin.mysqld
/etc/init.d/apparmor reload

#U12-APACHE24 if [ "$OSVER" -lt "14" ]; then
#U12-APACHE24   APACHEVER="$( apache2 -v | grep -i version | perl -ne 'm/Apache\/(\d+\.\d+)\./i && print "$1"' )"
#U12-APACHE24   if [ "x$APACHEVER" != "x2.2" ]; then
#U12-APACHE24     shout 'You are installing a new Apache on Ubuntu 12,'
#U12-APACHE24     shout 'so I need to install apache2-dev and remove'
#U12-APACHE24     shout 'dependencies on Apache 2.2.'
#U12-APACHE24     apt-get -y install apache2-dev
#U12-APACHE24     sed -i.zendto '/apache2\.2/ d; s/--with-openssl/--with-openssl --disable-phar/' "$PHPSRCDIR/debian/rules"
#U12-APACHE24     sed -i.zendto 's/apache2-prefork-dev,/apache2-dev,/' "$PHPSRCDIR/debian/control"
#U12-APACHE24     shout
#U12-APACHE24   fi
#U12-APACHE24 fi

shout Get all the build dependencies
pause
mk-build-deps --install --remove --tool 'apt-get --assume-yes --no-install-recommends' "$PHPSRCDIR/debian/control"
#APC apt-get download "${NAME}-json" "${NAME}-apcu" # apt-get install this as it has deps ${NAME}-imap
if [ "$OSVER" -gt "12" ]; then
  apt-get download "${NAME}-json"
fi
apt-get download "${NAME}-imap" # NEW NEW
cd "$PHPSRCDIR" || exit 1

# Patch the source
shout Now to patch the source
chmod +x "$HERE"/lib/apply-big-uploads.sh
export QUILT_PATCHES=debian/patches # NEW NEW
quilt push -a
quilt new zendto-big-uploads
quilt shell "$HERE"/lib/apply-big-uploads.sh
if ! grep -q '^mysqld=.*user=root' debian/setup-mysql.sh; then
  shout And fix a bug in the way they start mysqld for testing # NEW NEW
  shout '(This may take several seconds)' # NEW NEW
  quilt shell sed -i 's/^\(mysqld=.*\)" *$/\1 --user=root"/' debian/setup-mysql.sh # NEW NEW
fi
#U12-APACHE24 if [ "$OSVER" -lt "14" -a "x$APACHEVER" != "x2.2" ]; then
#U12-APACHE24   shout 'You are installing a new Apache on Ubuntu 12,'
#U12-APACHE24   shout 'so a patch for the PHP OpenSSL code is needed.'
#U12-APACHE24   shout '(This may take several seconds)'
#U12-APACHE24   quilt shell patch -p0 -i "$HERE"/lib/xp_ssl.c.SSLv2v3.patch
#U12-APACHE24 fi
debchange --nmu Enabled uploads greater than 2GB for ZendTo.

# Build it!
shout Now to build PHP. This will take time. Get a coffee.
pause
if fakeroot debian/rules binary; then # NEW NEW
  shout ' '
  shout 'Yay! We rebuilt PHP!'
else
  shout ' '
  shout 'Oh dear, building PHP failed. I am going to need help.'
  shout 'Please try to fix whatever was wrong and re-run this script'.
  shout 'Exiting...'
  exit 1
fi

# Clean up the mess we left
shout Cleaning up temporary AppArmor settings
cd .. || exit 1
REX="$( echo "$SRCSTORE" | sed -e 's/[^a-zA-Z0-9._-]/./g' )"
sed -ie "/^${REX}/ d" /etc/apparmor.d/local/usr.sbin.mysqld
if [ "x$REMOVEMYSQL" = "xno" ]; then
  shout 'mysql-server was already installed by someone else.'
  shout 'It is not needed on a new ZendTo installation.'
  shout 'It is only needed if you are migrating from an existing'
  shout 'ZendTo installation that used MySQL as its database'
  shout 'and kept the database data on the ZendTo server itself.'
  if yesno "Would you like me to remove mysql-server" "y"; then
    REMOVEMYSQL='yes'
  fi
fi
if [ "x$REMOVEMYSQL" = "xyes" ]; then
  shout Removing MySQL
  apt-get -y purge mysql-server
  apt-get -y autoremove
fi
chmod go-x ~
/etc/init.d/apparmor reload

#
# Work out what deb packages we actually want/need to install
#
shout "Studying the $NAME .deb packages we have built"

# Needed to be able to use | in the case statement below
shopt -s extglob

# Find all the relevant .deb files that have been built since the
# source tree was last modified.
ALLDEBS="$( find *.deb -maxdepth 0 \( -name "$NAME"'*' -o -name 'php-pear*' -o -name 'libapache2-mod-php5*' \) -newer "$PHPSRCDIR" -type f -print0 | xargs -0 ls -t )"
# These few will be older than the php5 build dir, but need them
#APC for EMODS in json apcu; do
#APC   # Find the newest .deb file in each case
#APC   ALLDEBS="$ALLDEBS $( ls -t "$NAME"-${EMODS}_*.deb | head -1 )"
#APC done
if [ "$OSVER" -gt "12" ]; then
  # Also need json on Ubuntu 14
  ALLDEBS="$ALLDEBS $( ls -t "$NAME"-json_*.deb | head -1 )"
fi

# Now from that list of all the relevant ones, find what we want
PHPDEBS=''
for F in $ALLDEBS
do
  echo "Studying $F ..."
  case $F in
    (php-pear*)
      PHPDEBS="$PHPDEBS $F"
      ;;
#APC     (php5-@(sqlite|mysqlnd|readline|mbstring|ldap|intl|gd|enchant|curl|cli|common|json|apcu)_*)
    (php5-@(sqlite|mysqlnd|readline|mbstring|ldap|intl|gd|enchant|curl|cli|common|json)_*)
      PHPDEBS="$PHPDEBS $F"
      ;;
    (libapache2-mod-php5filter*)
      :
      ;;
    (libapache2-mod-php5*)
      PHPDEBS="$PHPDEBS $F"
      ;;
  esac
done

shout Want to install these .deb files:
shout $(echo $PHPDEBS | sed -e 's/ /\n/')
pause
shout
dpkg --install $PHPDEBS
shout And imap which we can just install with apt
apt-get -y install "${NAME}-imap"
if [ "$OSVER" -gt "12" ]; then
  shout And enable the PHP extensions they provide.
  shout 'Do not worry about any sqlite or mbstring "ini file"'
  shout 'warnings, as we will be using sqlite3 and not sqlite.'
  #APC for MOD in sqlite mysqlnd readline ldap intl gd enchant curl json apcu imap mbstring
  for MOD in sqlite mysqlnd readline ldap intl gd enchant curl json imap mbstring
  do
    "${NAME}enmod" -s ALL "$MOD"
  done
fi

shout
shout Rebuilding PHP is all done, and you should now have the new packages installed.

exit 0
