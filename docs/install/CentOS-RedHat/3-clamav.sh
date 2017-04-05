#!/bin/bash

# Install ClamAV with SELinux support

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
shout 'Install and configure ClamAV (and SELinux if enabled)'
shout
shout =================================================================
shout
pause

# Install the RPMs we need
shout Installing ClamAV RPMs
if [ "$OSVER" -le "6" ]; then
  # 5 and 6
  yum -y install clamav clamav-db clamd
  # So apache can run clamdscan
  usermod -a -G clam apache
  # So clamd and clamdscan can read files created by apache
  usermod -a -G apache clam
  CLAMDCONF=/etc/clamd.conf
else
  # 7 and above
  yum -y install clamav clamav-scanner-systemd clamav-update
  # So freshclam can notify clamd an update has happened
  groupmems --group clamscan --add clamupdate
  # So apache can run clamdscan
  groupmems --group clamscan --add apache
  # So clamd and clamdscan can read files created by apache
  groupmems --group apache --add clamscan
  CLAMDCONF=/etc/clamd.d/scan.conf
  ln -sf $CLAMDCONF /etc/clamd.conf
fi
pause

shout Fixing ClamAV configuration files

# Edit clamd.conf:
# 1. Comment out the Example line
# 2. Uncomment the LocalSocket line
shout 1. Enable clamd and enable LocalSocket option
perl -pi.zendto -e 's/^Example\s*$/#Example/i; s/^#\s*(LocalSocket\s+.)/$1/i;' $CLAMDCONF

# Edit freshclam.conf
# 1. Comment out the Example line
# 2. Fix the NotifyClamd line
shout 2. Enable freshclam and enable NotifyClamd option
perl -pi.zendto -e 's/^Example\s*$/#Example/i; s/^#?(NotifyClamd).*$/NotifyClamd \/etc\/clamd.conf/i;' /etc/freshclam.conf

# Edit /etc/sysconfig/freshclam (doesn't appear in 5 or 6)
if [ -f /etc/sysconfig/freshclam ]; then
  shout 3. Enable freshclam to work at all
  perl -pi.zendto -e 's/^(FRESHCLAM_DELAY=)/#$1/;' /etc/sysconfig/freshclam
fi

if [ "$OSVER" -ge "7" ]; then
  #
  # On 7 and upwards only, we have systemd instead of init
  #
  # Create the systemd service for the freshclam daemon
  if [ ! -f /usr/lib/systemd/system/clam-freshclam.service ]; then
    shout Creating systemd service for freshclam daemon
    cat <<EOSERVICE > /usr/lib/systemd/system/clam-freshclam.service
# Run the freshclam as daemon
[Unit]
Description = freshclam scanner
After = network.target
After = clamd@scan.service
Wants = clamd@scan.service
[Service]
Type = forking
ExecStart = /usr/bin/freshclam -d -c 4
Restart = on-failure
PrivateTmp = true
[Install]
WantedBy=multi-user.target
EOSERVICE
  fi
  # Tell SELinux what to do
  if [ "$SELINUX" = "enabled" ]; then
    shout Setting SELinux flags so clamd can work.
    shout antivirus_can_scan_system = 1
    setsebool -P antivirus_can_scan_system 1
    shout clamd_use_jit 1
    setsebool -P clamd_use_jit 1
  fi
  # Enable and start both services
  shout 'Enabling and starting clamd (clamd@scan) and freshclam (clam-freshclam) systemd services'
  systemctl enable clamd@scan
  systemctl enable clam-freshclam
  systemctl start clamd@scan
  systemctl start clam-freshclam
else
  #
  # 5 and 6: simple init setup
  #
  if [ "$SELINUX" = "enabled" ]; then
    # There is no SELinux module for clamd
    # so roll our own
    shout 'Installing package for building policy modules'
    yum -y install selinux-policy-devel
    shout 'Need to build our own clamd_local policy module'
    rm -rf "$TEMPFILE"
    mkdir -p "$TEMPFILE"
    cp "$HERE"/lib/clamd_local.te "$TEMPFILE"/clamd_local.te
    pushd "$TEMPFILE"
    make -f /usr/share/selinux/devel/Makefile clamd_local.pp
    shout 'And install it'
    if semodule -i clamd_local.pp; then
      shout 'Good, clamd can now use its JIT compiler.'
    else
      shout 'Module failed to install. The source of the module'
      shout 'is in lib/clamd_local.te so you will have to build'
      shout 'and install it yourself if you want to make clamd'
      shout 'work fastest.'
      pause
    fi
    popd >/dev/null
    rm -rf "$TEMPFILE"
    # Tell SELinux what to do
    if [ "$SELINUX" = "enabled" -a "$OSVER" -gt "5" ]; then
      shout Setting SELinux flag so clamd can work.
      shout antivirus_can_scan_system = 1
      setsebool -P antivirus_can_scan_system 1
    fi
    # Obsolete: 2016-12-01 superceded by manually written policy module above.
    #shout Trying to force generation of clamd error to auto-construct SELinux module
    ## Force generation of the error
    #service clamd restart >/dev/null 2>&1
    #REPORTNUM="$(aureport --avc --start yesterday | grep -i 'clamd.*execmem.*denied' | tail -1 | awk '{ print $NF }')"
    #if [ "x$REPORTNUM" = "x" ]; then
    #  shout clamd did not complain, no need to generate an SELinux module
    #else
    #  # Generate and install a new SELinux module for clamd
    #  shout Generating new SELinux policy module for clamd
    #  WHERE="/etc/selinux/$SELINUXPOLICY/modules/active/modules"
    #  shout in $WHERE
    #  if [ ! -d "$WHERE" ]; then
    #    shout Cannot find where to put the new SELinux module
    #    WHERE="$(prompt "Where can I store the new SELinux module" "/etc/selinux" "$WHERE")"
    #  fi
    #  pushd "$WHERE"
    #  ausearch -a $REPORTNUM | audit2allow -M clamd
    #  shout Installing and activating new SELinux policy module for clamd
    #  semodule -i clamd.pp
    #  popd >/dev/null
    #fi
  fi
  # Enable and start clamd
  shout
  shout Ignore warnings about the virus database being old,
  shout I am just about to fix that.
  pause
  chkconfig clamd on
  service clamd restart
  shout
  shout 'Do not worry if the next bit (updating Clam signatures)'
  shout 'takes a while and a few attempts. It will get there in the end.'
  freshclam
  # freshclam: nightly cron job and log rotation setup for us by the RPM
  shout 'freshclam will be run automatically every night,'
  shout 'and log rotation is also already configured.'
fi

shout
shout ClamAV has been setup for you to work with ZendTo.
shout

exit 0

