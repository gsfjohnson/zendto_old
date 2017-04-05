#!/bin/bash

# Rebuild PHP with SQLite+IMAP (if not already included) and big-uploads support.

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
shout 'Add IMAP support (if not already there) and'
shout '"big-uploads" support (uploads greater than 2GB) to PHP.'
shout
shout =================================================================
shout
pause

# Don't try to add SQLite3 to PHP on CentOS 5, it doesn't work due to
# what looks like threading/locking problems. httpd worker processes SEGV.
if [ "$OSVER" -le "5" ]; then
  shout 'I am not going to add SQLite v2 or v3 support to PHP as you'
  shout 'are running CentOS 5 or RHEL 5. I have tested this, and while'
  shout 'it builds fine, it does not work reliably at all.'
  pause
fi

SPECPATCH=$HERE/lib/php53.spec.SQLite.patch
PECLPATCH=$HERE/lib/apc-zendto.patch

REMOVE="$(rpm -qa | grep '^php[0-9]*-common')"
if [ "x$REMOVE" = "x" ]; then
  shout Good, no PHP packages installed.
else
  shout Need to remove any existing PHP packages first,
  shout along with packages with depend on PHP, sorry.
  pause 10
  yum -y remove $REMOVE
fi
pause
shout Need to install a few extra tools.
yum -y install yum-utils rpm-build
yum -y install libmcrypt-devel
pause

mkdir -p "$SRCSTORE" && cd "$SRCSTORE" || exit 1

# Find the latest major release of PHP (5: in EPEL; 6: in CentOS; 7: in CentOS/RHEL).
if [ "$OSVER" = "5" ]; then
  NAME="$( yum whatprovides /usr/bin/php | grep -E '^php[0-9]+' | sort | tail -n 1 | cut -d- -f1 )"
  DEFPHP="php53"
else
  # CentOS/RHEL 6 and 7
  NAME="$( yum whatprovides /usr/bin/php | grep -E '^php-' | sort | tail -n 1 | cut -d- -f1 )"
  DEFPHP="php"
fi
if [ "x$NAME" = "x" ]; then
  shout I could not find the packages that provide a recent version of PHP.
  NAME="$(prompt "Prefix of PHP package names" "$DEFPHP" "$NAME")"
fi

# Find the patch for the spec file. Only for RHEL 5.
# No don't. Not for CentOS or RHEL 5 at all.
if [ "$OSVER" -le "5" ]; then
  SPECPATCH='skip'
#elif [ "$OSVER" = "5" -a ! -f "$SPECPATCH" ]; then
#  SPECPATCH="$(prompt "Patch file for PHP\'s spec file to add SQLite support" "php53.spec.SQLite.patch" "$SPECPATCH")"
fi

# Remove the old PHP and set up environment
# Get source and find the spec file
if [ "$OS" = "centos" ]; then
  # CentOS is easier!
  if [ "$OSVER" = "6" ]; then
    # CentOS 6 doesn't know where its source code is :-(
    cp -f "$HERESUB"/CentOS6/centos*repo /etc/yum.repos.d/
  fi
  yumdownloader --source "$NAME"
  # CentOS 7 has lost php-imap, so get it too
  if [ "$OSVER" -ge "7" ]; then
    yumdownloader --source php-extras
  fi
else
  # RHEL is a royal PITA.
  if [ "$OSVER" = "5" ]; then
    # RHEL5
    # You have to nick the SRPM from CentOS 5 :-(
    cp -f "$HERESUB"/RHEL5/centos*repo /etc/yum.repos.d/
    yumdownloader --enablerepo=centos-base --enablerepo=centos-updates --source "$NAME"
  elif [ "$OSVER" = "6" ]; then
    # RHEL6
    # In order to fetch sources, yumdownloader disables all your -sources
    # repos. Then it re-enables the ones whose names are the same as your
    # binary repos, but with -source added to the end of their names.
    # Sadly, RedHat call their main source repo "rhel-source" whereas the
    # main binary repo is called something like "rhel-x86_64-server-6".
    # So yumdownloader will never find it, and can't be persuaded to. AARGH!
    # And yes, I did work all that out by reading the source of yumdownloader.
    REPOID="$( yum --verbose repolist "rhel-$ARCH-server-$OSVER" 2>&1 | grep -E '^Repo-id\s*:' | sort | perl -pe 's/^.*?:\s*//;' )"
    REPOID="$(prompt "Name of your main RedHat binary yum repository" "rhel-$ARCH-server-$OSVER" "$REPOID")"
    perl -pe 's/\[rhel-(source.*?)\]/['"$REPOID"'-$1\]/;' /etc/yum.repos.d/rhel-source.repo > /etc/yum.repos.d/rhel-source.zendto.repo
    yumdownloader --source "$NAME"
  elif [ "$OSVER" -ge "7" ]; then
    # RHEL7 and upwards
    # The sources are now in CentOS, as CentOS and RH are now the same org.
    # So this is how you get sources from the CentOS git repo where
    # the source is now.

    # But we are cheating. These are the deps of php.
    # Get all the ones we can from RHEL, only the vital few from CentOS.
    cp -f "$HERESUB/RHEL7"/centos-sources.repo /etc/yum.repos.d/
    yum -y install enchant glib2-devel ncurses-devel recode tokyocabinet libX11 libX11-common libXau libxcb
    yum -y --enablerepo='centos*' install aspell aspell-devel enchant-devel libedit-devel libzip-devel recode-devel t1lib-devel tokyocabinet-devel

    yum -y install git
    git clone  https://git.centos.org/git/centos-git-common.git
    chmod +x centos-git-common/*.sh
    git clone  https://git.centos.org/git/rpms/php.git
    cd php || exit 1
    git checkout c7 # Get the CentOS 7 source for php
    PATH=$SRCSTORE/centos-git-common:"$PATH" get_sources.sh
    # Make the SRPM
    PATH=$SRCSTORE/centos-git-common:"$PATH" into_srpm.sh
    mv SRPMS/"$NAME"-*src.rpm "$SRCSTORE"/
    cd "$SRCSTORE" || exit 1
    # RHEL 7 has lost php-imap so go get it from EPEL
    yumdownloader --source php-extras
  else
    shout
    shout Unknown version of RedHat, cannot get source for PHP.
    shout Advice: Press Ctrl-Z now, get the PHP source RPM
    shout "into $SRCSTORE and then" '"fg" to continue.'
    pause 20
    shout
    shout Okay, we are carrying on...
    pause
  fi
fi
SRC="$(ls -d "$NAME"-[0-9]*.src.rpm | tail -1)"
SRC="$(prompt "php Source RPM (.src.rpm) filename" "" "$SRC")"
SPECFILE="$(rpm -qlp "$SRC" | grep '^php.*\.spec$')"
#shout php RPM spec file is called $SPECFILE

# Only need php-extras on CentOS/RHEL 7 and above
EXTRASSPECFILE=""
if [ "$OSVER" -ge "7" ]; then
  EXTRASSRC="$(ls -d php-extras-[0-9]*.src.rpm | tail -1)"
  EXTRASSRC="$(prompt "php-extras Source RPM (.src.rpm) filename" "" "$EXTRASSRC")"
  EXTRASSPECFILE="$(rpm -qlp "$EXTRASSRC" | grep '^php-extras.*\.spec$')"
  #shout php-extras RPM spec file is called $EXTRASSPECFILE
fi

# Find where the spec file is going to end up
TOPDIR="$(rpm --eval '%_topdir')"
if [ "x$TOPDIR" = "x" ]; then
  TOPDIR="$(prompt "Top-level directory for building RPMs" "/usr/src/redhat" "$TOPDIR")"
fi
shout "Build root is $TOPDIR"

# Install the SRPM and build its dependencies
shout Installing the php SRPM and all its dependencies
cd "$SRCSTORE" || exit 1
installSrpmAndDeps "$SRC" "$TOPDIR/SPECS/$SPECFILE"
cd "$TOPDIR/SPECS" || exit 1

#
# Not patching for SQLite support any more at all. It was only really
# needed on CentOS/RHEL 5, and it doesn't work there.
# SQLite (i.e. version 3 by default) is provided in 6 and 7.
#
## Patch the spec file for SQLite, if we're not skipping that step.
## Skip it on RHEL 5 or CentOS 5.
#if [ "x$SPECPATCH" = "xskip" ]; then
#  shout Skipping adding SQLite support. It does not work on your OS.
#else
#  # SPECPATCH is a full pathname.
#  shout Patching the $SPECFILE to add SQLite support.
#  #shout Patching $TOPDIR/SPECS/$SPECFILE by applying $SPECPATCH
#  patch -b $TOPDIR/SPECS/$SPECFILE < $SPECPATCH
#  pause
#fi
#cd $TOPDIR/SPECS

# Set the Release: version number in the spec file
# so we know it's a custom one for ZendTo.
shout Adding "'.zendto'" into the release version number for easy id.
perl -pi.bak -e 's/(^Release:.*?)(%\{.*$)/$1.zendto$2/;' "$SPECFILE"
if [ "x$EXTRASSPECFILE" != "x" ]; then
  perl -pi.bak -e 's/(^Release:.*?)(%\{.*$)/$1.zendto$2/;' "$EXTRASSPECFILE"
fi

# Apply all the big-uploads changes to the source and build the patch file
shout Applying all the changes to enable big-uploads support.
pause
rpmbuild -bp "$SPECFILE"
pause
cd "$TOPDIR/BUILD" || exit 1
PHPSRC="$(ls -d php* | grep -E '^php-[0-9.-]+$' | tail -1)"
if [ "x$PHPSRC" = "x" ]; then
  shout "Could not find php source directory within $TOPDIR/BUILD."
  shout It should be called something like \'php-5.3.3\'.
  PHPSRC="$(prompt "PHP source directory" "php-5.3.3" "$PHPSRC")"
fi
shout "Patching PHP source in ${PHPSRC}.new"
rm -rf "${PHPSRC}.new"
cp -pr "$PHPSRC" "${PHPSRC}.new"
cd "${PHPSRC}.new" || exit 1
chmod +x "$HERE"/lib/apply-big-uploads.sh
"${HERE}/lib/apply-big-uploads.sh"
cd "$TOPDIR/BUILD" || exit 1
diff -Naur "$PHPSRC" "${PHPSRC}.new" > "$TOPDIR/SOURCES/php-biguploads.patch"
shout And here is the resulting patch file:
shout "$( ls -l "$TOPDIR/SOURCES/php-biguploads.patch" )"
cd "$TOPDIR/SPECS" || exit 1

# Patch the spec file for the big-uploads patches
shout "Adding this patch to the $SPECFILE"
rm -rf "$TEMPFILE"
# Add the Patchxxx:line to the end of the list of such lines
LINE="$(grep -nE '^Patch[0-9]+:' "$SPECFILE" | tail -n 1 | cut -d: -f1)"
head -n "$LINE" "$SPECFILE" > "$TEMPFILE"
echo 'Patch999: php-biguploads.patch' >> $TEMPFILE
LINE=$((LINE+1))
tail -n "+$LINE" "$SPECFILE" >> "$TEMPFILE"
mv "$SPECFILE" "${SPECFILE}.bak1"
cp "$TEMPFILE" "$SPECFILE"
rm -f "$TEMPFILE"
# Add the %patch lines to the end of the list of such lines
LINE="$(grep -nE '^%patch[0-9]+' "$SPECFILE" | tail -n 1 | cut -d: -f1)"
head -n "$LINE" "$SPECFILE" > "$TEMPFILE"
echo '%patch999 -p1 -b .biguploads' >> "$TEMPFILE"
LINE=$((LINE+1))
tail -n "+$LINE" "$SPECFILE" >> "$TEMPFILE"
mv "$SPECFILE" "${SPECFILE}.bak2"
cp "$TEMPFILE" "$SPECFILE"
rm -f "$TEMPFILE"

shout
shout And now to build all the new PHP RPMs
pause

# Work out the distribution and build new RPMs
# Worked out $NAME already from what provides /usr/bin/php in yum repos
# This method uses the .spec file which may be needed in other OSes.
# NAME=`grep -E '^Name:\s*[a-z0-9.-_]+' $SPECFILE | head -n 1 | perl -pe 's/^Name:\s*([a-z0-9._-]+).*?$/$1/;'`
DIST="$(yum info "$NAME" | grep '^Release' | sed -e 's/^.*:.*\(\..*\)$/\1/')"
DIST="$(prompt "Distribution to build RPM for" ".el5_11" "$DIST")"
shout "Name of package is $NAME"
shout "Name of distribution is $DIST"
pause
if [ "x$SKIPPHP" = "xyes" ]; then
  shout 'Debug: Skipping building PHP.'
else
  if rpmbuild -ba --define "dist $DIST" "$SPECFILE"; then
    shout 'Yay! I built all the RPMs for PHP!'
  else
    shout 'Something went wrong, and the RPMs for PHP were not built'
    shout 'successfully. Please go back through the output from this'
    shout 'and try to fix what went wrong (usually something that should'
    shout 'be installed but was not).'
    shout 'Then run this script again.'
    shout 'Exiting...'
    exit 1
  fi
fi
pause

# Assuming that all worked, the RPMs are in $TOPDIR/RPMS/$ARCH
# So let's install them!
shout Now to install the ones we need
cd "$TOPDIR/RPMS/$ARCH" || exit 1
# Work out what comes after php-<extension>-....... in the RPM filenames.
SUFFIX="$(ls "$NAME"-[0-9]*."$ARCH".rpm | tail -1 | sed -e 's/^'"$NAME"'-//')"
shout "RPM filename suffix is $SUFFIX"
# These are all the extensions we want to install.
EXTENSIONS="cli common devel gd ldap mbstring mysql pdo process xml"
if [ "$OSVER" -lt "7" ]; then
  # They removed IMAP support from PHP 5.4 :-(
  EXTENSIONS="$EXTENSIONS imap"
fi
# Not trying to patch 5 (doesn't work), not trying to patch 6 (not needed).
#if [ "$OSVER" = "6" ]; then
#  # Only need these 3 on CentOS / RHEL 5. Already included after that.
#  EXTENSIONS="$EXTENSIONS mcrypt sqlite sqlite3"
#fi
# Produce a list of all the RPM files we want to install.
RPMLIST="$(
  # Add php itself
  echo "$NAME-$SUFFIX"
  # Then all its extension-packages
  for F in $EXTENSIONS
  do
    echo "$NAME-$F-$SUFFIX"
  done
)"

shout Installing the new php RPMS for these packages:
shout "$RPMLIST"
pause
# And install them.
if rpm -Uvh $RPMLIST; then
  shout 'Yay! We installed all the patched PHP rpms.'
  pause
else
  shout 'Something went wrong, and the RPMs for PHP could not be installed.'
  shout 'Please go back through the output from this'
  shout 'and try to fix what went wrong (usually something that should'
  shout 'be installed but was not).'
  shout 'Then run this script again.'
  shout 'Exiting...'
  exit 1
fi

#
# Now start on the php-extras RPM as this cannot be built at all
# until php-devel has been installed by the code above.
#

if [ "x$EXTRASSPECFILE" != "x" ]; then
  # Install the php-extras SRPM and build its dependencies
  shout Installing the php-extras SRPM and all its dependencies
  cd "$SRCSTORE" || exit 1
  installSrpmAndDeps "$EXTRASSRC" "$TOPDIR/SPECS/$EXTRASSPECFILE"
  cd "$TOPDIR/SPECS" || exit 1

  # Set the Release: version number in the spec file
  # so we know it's a custom one for ZendTo.
  shout Adding "'.zendto'" into the php-extras release version number for easy id.
  perl -pi.bak -e 's/(^Release:.*?)(%\{.*$)/$1.zendto$2/;' "$EXTRASSPECFILE"

  # And build the php-extras package, but only the imap bit of it.
  shout Now to build the php-imap module from php-extras
  if rpmbuild -bb --without=default --with=imap --define "dist $DIST" "$EXTRASSPECFILE"; then
    shout 'Yay, we now have IMAP support in PHP too!'
  else
    shout 'Something went wrong, and the RPM for php-imap was not built'
    shout 'successfully. Please go back through the output from this'
    shout 'and try to fix what went wrong (usually something that should'
    shout 'be installed but was not).'
    shout 'Then run this script again.'
    shout 'Exiting...'
    exit 1
  fi
  pause

  # Now install the php-imap RPM in RHEL/CentOS 7 and above
  cd "$TOPDIR/RPMS/$ARCH" || exit 1
  IMAPRPM="$( ls php-imap-[0-9]*."$ARCH".rpm | tail -1 )"
  if [ "x$IMAPRPM" = "x" ]; then
    shout "I could not find the php-imap...$ARCH.rpm file" ':-('
    IMAPRPM="$(prompt "php-imap RPM (.$ARCH.rpm) filename" "" "$IMAPRPM")"
  fi
  if rpm -Uvh "$IMAPRPM"; then
    shout
    shout Great, looks like the php-imap RPM installed okay.
    pause
  fi
fi
# End of php-extras

# Now there are a few other packages we need.
# php-pear is a "noarch" so doesn't need rebuilding.
shout
shout Installing php-pear
yum -y install php-pear

#
# Now do the php-pecl-apc[u] download/build/install
#

# What is the package name?
if [ "$OSVER" -ge "7" ]; then
  PECLNAME=php-pecl-apcu
else
  PECLNAME=php-pecl-apc
fi

# Fetch and install the source needed.
shout
shout Fetching and building $PECLNAME
cd "$SRCSTORE" || exit 1
yumdownloader --source $PECLNAME
SRC="$(ls -d "$PECLNAME"-*.src.rpm | tail -1)"
SRC="$(prompt "$PECLNAME SRPM (.src.rpm) filename" "" "$SRC")"
SPECFILE="$(rpm -qlp "$SRC" | grep '^'"$PECLNAME"'.*\.spec$')"
shout "SRPM file is $SRC"
shout "spec file is $SPECFILE"
if [ "x$NAME" != "xphp" ]; then
  # Cannot use installSrpm... as need to patch spec file in the middle
  rpm -Uvh "$SRC" 2> >(grep -iv 'warning:.*does not exist')
  shout "Patching $SPECFILE to fix PHP build dependencies"
  perl -pi.bak -e 's/php-devel/'"$NAME"'-devel/g if /^BuildRequires:/i;' "$TOPDIR/SPECS/$SPECFILE"
  yum -y install httpd-devel
else
  # Use nice function whenever we can
  installSrpmAndDeps "$SRC" "$TOPDIR/SPECS/$SPECFILE"
fi
cd "$TOPDIR/SPECS" || exit 1

# Set the Release: version number in the spec file
# so we know it's a custom one for ZendTo.
shout Setting its version number for easy id.
perl -pi.bak -e 's/(^Release:.*?)(%\{.*$)/$1.zendto$2/;' "$SPECFILE"

# Work out the distribution and build new RPM
shout Now to build the new $PECLNAME RPM
DIST="$(yum info "$PECLNAME" | grep '^Release' | sed -e 's/^.*:.*\(\..*\)$/\1/')"
DIST="$(prompt "Distribution to build RPM for" ".el7" "$DIST")"
shout "Name of apc package is $PECLNAME"
shout "Name of distribution is $DIST"
pause

if rpmbuild -bb --define "dist $DIST" "$SPECFILE"; then
  shout 'Yay! I built the RPM for '$PECLNAME'!'
else
  shout 'Building the RPM for '$PECLNAME' failed.'
  shout 'Do not worry, I have a patch which might fix this.'
  shout 'I will apply it and try again.'
  pause
  # Patch the spec file for the APC patch
  cp -f "$PECLPATCH" "$TOPDIR/SOURCES"
  rm -rf $TEMPFILE
  # Add the Patchxxx:line to the end of the list of such lines
  LINE="$(grep -nE '^Patch[0-9]+:' "$SPECFILE" | tail -n 1 | cut -d: -f1)"
  head -n "$LINE" "$SPECFILE" > "$TEMPFILE"
  echo 'Patch999: apc-zendto.patch' >> "$TEMPFILE"
  LINE=$((LINE+1))
  tail -n "+$LINE" "$SPECFILE" >> "$TEMPFILE"
  mv "$SPECFILE" "${SPECFILE}.bak1"
  cp "$TEMPFILE" "$SPECFILE"
  rm -f "$TEMPFILE"
  # Add the %patch lines to the end of the list of such lines
  LINE="$(grep -nE '^%patch[0-9]+' "$SPECFILE" | tail -n 1 | cut -d: -f1)"
  head -n "$LINE" "$SPECFILE" > "$TEMPFILE"
  echo '%patch999 -p1 -b .apc-zendto' >> "$TEMPFILE"
  LINE=$((LINE+1))
  tail -n "+$LINE" "$SPECFILE" >> "$TEMPFILE"
  mv "$SPECFILE" "${SPECFILE}.bak2"
  cp "$TEMPFILE" "$SPECFILE"
  rm -f "$TEMPFILE"

  if rpmbuild -bb --define "dist $DIST" "$SPECFILE"; then
    shout 'Yay! I built the RPM for '"$PECLNAME"'!'
  else
    shout 'Something went wrong, and the RPMs for '"$PECLNAME"' were'
    shout 'not built successfully. Please go back through the output from this'
    shout 'and try to fix what went wrong (usually something that should'
    shout 'be installed but was not).'
    shout 'Then run this script again.'
    shout 'Exiting...'
    exit 1
  fi
fi
pause

shout Now to install the new $PECLNAME RPM

# Assuming that all worked, the RPMs are in $TOPDIR/RPMS/$ARCH
# So let's install them!
cd "$TOPDIR/RPMS/$ARCH" || exit 1
# Work out what comes after php-pecl-apc-....... in the RPM filenames.
SUFFIX="$(ls "$PECLNAME"-[0-9]*."$ARCH".rpm | tail -1 | sed -e 's/^'"$PECLNAME"'-//')"
shout "RPM filename suffix is $SUFFIX"
if rpm -Uvh "$PECLNAME-$SUFFIX"; then
  shout 'Yay! We installed the correct '"$PECLNAME"'!'
else
  shout 'Something went wrong, and the RPM for '"$PECLNAME"' could not be installed.'
  shout 'Please go back through the output from this'
  shout 'and try to fix what went wrong (usually something that should'
  shout 'be installed but was not).'
  shout 'Then run this script again.'
  shout 'Exiting...'
  exit 1
fi

shout
shout Rebuilding PHP is all done, and you should now have the new RPMs installed.

exit 0
