%define version 4.26
%define release 2
%define name    zendto

%define is_fedora %(test -e /etc/fedora-release && echo 1 || echo 0)

Name:        %{name}
Version:     %{version}
Release:     %{release}
Summary:     Web-based File Transfer and Storage System
Group:       Networking/WWW
License:     GPL
Vendor:      Julian Field www.zend.to
Packager:    Julian Field <ZendTo@Zend.To>
URL:         http://zend.to/
AutoReq:     no
Requires:    httpd, /usr/sbin/clamd
Source:      ZendTo-%{version}-%{release}.tgz
BuildRoot:   %{_tmppath}/%{name}-root
BuildArchitectures: noarch

%description
ZendTo is a web-based package that allows for the easy transfer of large
files both into and out of your organisation, without users outside
your organisation needing any usernames or passwords to be able to send
files to you. It also of couse allows your own internal users to send
files to anyone with an email address. All submissions are scanned for
viruses but are otherwise unrestricted.

It cannot be used by external users to distribute files to other external
users, and therefore cannot be abused to distribute illegal software or
other files outside of your organisation. It also cannot be abused by
outside spammers to automatically "spam" everyone in your organisation
with file notifications.

It is specifically designed to look after itself once installed and
maintain itself automatically. Customising the user interface is very
simply done by editing templates.

It is very easy to use, and is effectively a modern web-based replacement
for old "anonymous ftp" methods.

It also includes an additional package MyZendTo which is rather like
an easy web-based filestore, in which you can send files to other people
if you wish to, but they are primarily there for your own use.
%prep

%build

%install
mkdir -p $RPM_BUILD_ROOT
mkdir -p ${RPM_BUILD_ROOT}/opt
tar xzf ${RPM_SOURCE_DIR}/ZendTo-%{version}-%{release}.tgz -C ${RPM_BUILD_ROOT}/opt
mv ${RPM_BUILD_ROOT}/opt/ZendTo-%{version}-%{release} ${RPM_BUILD_ROOT}/opt/zendto
rm -rf ${RPM_BUILD_ROOT}/opt/zendto/docs/{rpm,debian,upgrade}
rm -rf ${RPM_BUILD_ROOT}/opt/zendto/templates-v3
chmod +x     ${RPM_BUILD_ROOT}/opt/zendto/sbin/UPGRADE/*php
chmod +x     ${RPM_BUILD_ROOT}/opt/zendto/sbin/UPGRADE/*sh
chmod +x     ${RPM_BUILD_ROOT}/opt/zendto/bin/*php
chmod +x     ${RPM_BUILD_ROOT}/opt/zendto/bin/upgrade*

mkdir -p ${RPM_BUILD_ROOT}/var/zendto
chgrp apache ${RPM_BUILD_ROOT}/var/zendto
chmod g+w ${RPM_BUILD_ROOT}/var/zendto

mkdir -p ${RPM_BUILD_ROOT}/etc/cron.d
cat > ${RPM_BUILD_ROOT}/etc/cron.d/zendto <<EOF3
5 0 * * * root /usr/bin/php /opt/zendto/sbin/cleanup.php /opt/zendto/config/preferences.php >/dev/null 2>&1
1 1 * * * root /usr/bin/php /opt/zendto/sbin/rrdInit.php /opt/zendto/config/preferences.php 2>&1 | /bin/grep -iv 'illegal attempt to update using time'
3 3 * * * root /usr/bin/php /opt/zendto/sbin/rrdUpdate.php /opt/zendto/config/preferences.php 2>&1 | grep -v '^[0-9]*x[0-9]*$'
EOF3

mkdir -p ${RPM_BUILD_ROOT}/etc/profile.d
echo '[ -f /opt/zendto/config/preferences.php ] && export ZENDTOPREFS=/opt/zendto/config/preferences.php' > ${RPM_BUILD_ROOT}/etc/profile.d/zendto.sh
echo '# zendto initialization script (csh)' > ${RPM_BUILD_ROOT}/etc/profile.d/zendto.csh
echo 'if ( -f /opt/zendto/config/preferences.php ) then' >> ${RPM_BUILD_ROOT}/etc/profile.d/zendto.csh
echo '  setenv ZENDTOPREFS /opt/zendto/config/preferences.php' >> ${RPM_BUILD_ROOT}/etc/profile.d/zendto.csh
echo 'endif' >> ${RPM_BUILD_ROOT}/etc/profile.d/zendto.csh
chmod a+rx ${RPM_BUILD_ROOT}/etc/profile.d/zendto.sh
chmod a+rx ${RPM_BUILD_ROOT}/etc/profile.d/zendto.csh

%clean
rm -rf ${RPM_BUILD_ROOT}

%pre

%post
# Construct /var/zendto
if [ \! -d /var/zendto/ ]; then
  mkdir -p /var/zendto
  chown root:apache /var/zendto
  chmod 0775 /var/zendto
fi
for F in incoming dropoffs rrd library cache templates_c myzendto.templates_c
do
  if [ \! -d /var/zendto/$F/ ]; then
    mkdir -p /var/zendto/$F
    chown apache:apache /var/zendto/$F
    chmod 0755 /var/zendto/$F
  fi
done
if [ \! -f /var/zendto/zendto.log ]; then
  :> /var/zendto/zendto.log
  chown apache:apache /var/zendto/zendto.log
  chmod u=rw,g=rw,o=r /var/zendto/zendto.log
fi
for F in cache templates_c myzendto.templates_c
do
  :> /var/zendto/$F/This.Dir.Must.Be.Writeable.By.Apache
  chown apache:apache /var/zendto/$F/This.Dir.Must.Be.Writeable.By.Apache
  chmod u=rw,g=rw,o=r /var/zendto/$F/This.Dir.Must.Be.Writeable.By.Apache
done
cp /opt/zendto/www/images/notfound.png /var/zendto/rrd/notfound.png
chmod a+r /var/zendto/rrd/notfound.png

# Clean the caches in case Smarty has been upgraded
rm -f /var/zendto/cache/*php >/dev/null 2>&1
rm -f /var/zendto/templates_c/*php >/dev/null 2>&1
rm -f /var/zendto/myzendto.templates_c/*php >/dev/null 2>&1

# Remove obsolete caches in case they are still there
rm -rf /opt/zendto/cache >/dev/null 2>&1
rm -rf /opt/zendto/templates_c >/dev/null 2>&1
rm -rf /opt/zendto/myzendto.templates_c >/dev/null 2>&1

if systemctl --version >/dev/null 2>&1; then
  systemctl reload crond.service
else
  service crond reload
fi

if [ $1 = 1 ]; then
  # We are being installed, not upgraded (that would be 2)
  # See postun for the post-upgrade script.
  echo
  echo For technical support, please go to http://zend.to.
  echo
fi

%preun
if [ $1 = 0 ]; then
  # We are being deleted, not upgraded
  if systemctl --version >/dev/null 2>&1; then
    systemctl reload crond.service
  else
    service crond reload
  fi
  echo 'You can delete all the files created by ZendTo with the command'
  echo 'rm -rf /var/zendto'
fi
exit 0

%postun
if [ "$1" -ge "1" ]; then
  # We are being upgraded or replaced, not deleted
  # Clean the caches in case Smarty has been upgraded
  rm -f /var/zendto/templates_c/*php >/dev/null 2>&1
  rm -f /var/zendto/myzendto.templates_c/*php >/dev/null 2>&1
  rm -f /var/zendto/cache/*php >/dev/null 2>&1
  if systemctl --version >/dev/null 2>&1; then
    systemctl reload crond.service
  else
    service crond reload
  fi
  echo 'Please ensure your /opt/zendto/config/* files are up to date.'
  echo
  echo 'To help you, there are tools for upgrading the preferences.php and
  echo 'zendto.conf files.'
  echo 'Simply run'
  echo '    /opt/zendto/bin/upgrade_preferences_php'
  echo 'and'
  echo '    /opt/zendto/bin/upgrade_zendto_conf'
  echo 'and they will show you how to use them.'
  echo
fi
exit 0

%files
%attr(755,root,root) %dir /opt/zendto
/opt/zendto/lib
/opt/zendto/www
/opt/zendto/sql
/opt/zendto/myzendto.www
%config(noreplace) %attr(755,root,root)     %dir /opt/zendto/www/css
%config(noreplace) %attr(644,root,root)     /opt/zendto/www/css/local.css
%config(noreplace) %attr(755,root,root)     %dir /opt/zendto/www/images/swish
%config(noreplace) %attr(755,root,root)     %dir /opt/zendto/myzendto.www/css
%config(noreplace) %attr(644,root,root)     /opt/zendto/myzendto.www/css/local.css
%config(noreplace) %attr(644,root,root)     /opt/zendto/www/images/email-logo.png

%doc /opt/zendto/docs
%doc /opt/zendto/README
%doc /opt/zendto/GPL.txt
%doc /opt/zendto/ChangeLog


%attr(755,root,root) %dir /opt/zendto/config
%config(noreplace) %attr(644,root,apache) /opt/zendto/config/zendto.conf
%config(noreplace) %attr(640,root,apache) /opt/zendto/config/preferences.php
%config(noreplace) %attr(644,root,apache) /opt/zendto/config/internaldomains.conf

%attr(755,root,root) %dir /opt/zendto/templates
%config(noreplace) %attr(644,root,root) /opt/zendto/templates/about.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/templates/claimid_box.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/templates/delete.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/templates/dropoff_email.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/templates/dropoff_email_html.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/templates/dropoff_list.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/templates/email_footer_html.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/templates/email_header_html.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/templates/email_logo_html.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/templates/error.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/templates/footer.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/templates/functions.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/templates/header.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/templates/login.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/templates/logout.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/templates/log.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/templates/main_menu.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/templates/new_dropoff.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/templates/no_download.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/templates/pickupcheck.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/templates/pickup_email.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/templates/pickup_email_html.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/templates/pickup_list_all.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/templates/pickup_list.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/templates/progress.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/templates/request_email.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/templates/request_email_html.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/templates/request_sent.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/templates/request.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/templates/resend.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/templates/security.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/templates/show_dropoff.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/templates/stats.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/templates/unlock.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/templates/verify_email.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/templates/verify_email_html.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/templates/verify_sent.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/templates/verify.tpl

%attr(755,root,root) %dir /opt/zendto/myzendto.templates
%config(noreplace) %attr(644,root,root) /opt/zendto/myzendto.templates/about.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/myzendto.templates/claimid_box.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/myzendto.templates/delete.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/myzendto.templates/dropoff_email.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/myzendto.templates/error.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/myzendto.templates/footer.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/myzendto.templates/functions.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/myzendto.templates/header.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/myzendto.templates/log.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/myzendto.templates/login.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/myzendto.templates/logout.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/myzendto.templates/new_dropoff.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/myzendto.templates/no_download.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/myzendto.templates/pickup_email.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/myzendto.templates/pickup_list_all.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/myzendto.templates/pickup_list.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/myzendto.templates/progress.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/myzendto.templates/show_dropoff.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/myzendto.templates/stats.tpl
%config(noreplace) %attr(644,root,root) /opt/zendto/myzendto.templates/unlock.tpl

%attr(755,root,root) %dir /opt/zendto/sbin
%attr(755,root,root) /opt/zendto/sbin/cleanup.php
%attr(755,root,root) /opt/zendto/sbin/stats.php
%attr(755,root,root) /opt/zendto/sbin/genCookieSecret.php
%attr(755,root,root) /opt/zendto/sbin/rrdInit.php
%attr(755,root,root) /opt/zendto/sbin/rrdUpdate.php
%attr(755,root,root) /opt/zendto/sbin/setphpini.pl

%attr(755,root,root) %dir /opt/zendto/sbin/UPGRADE
%doc /opt/zendto/sbin/UPGRADE/README.FIRST.txt
%attr(755,root,root) /opt/zendto/sbin/UPGRADE/addAuthTable.php
%attr(755,root,root) /opt/zendto/sbin/UPGRADE/addLoginlogTable.php
%attr(755,root,root) /opt/zendto/sbin/UPGRADE/addNotesColumn.sh
%attr(755,root,root) /opt/zendto/sbin/UPGRADE/addReqTable.php
%attr(755,root,root) /opt/zendto/sbin/UPGRADE/addUserTable.php
%attr(755,root,root) /opt/zendto/sbin/UPGRADE/addRegexpsTable.php
%attr(755,root,root) /opt/zendto/sbin/UPGRADE/fixDropoffTable.php
%attr(755,root,root) /opt/zendto/sbin/UPGRADE/upgrade_preferences_php
%attr(755,root,root) /opt/zendto/sbin/UPGRADE/upgrade_zendto_conf

%attr(755,root,root) %dir /opt/zendto/bin
%attr(755,root,root) /opt/zendto/bin/adduser.php
%attr(755,root,root) /opt/zendto/bin/deleteuser.php
%attr(755,root,root) /opt/zendto/bin/listusers.php
%attr(755,root,root) /opt/zendto/bin/setpassword.php
%attr(755,root,root) /opt/zendto/bin/setquota.php
%attr(755,root,root) /opt/zendto/bin/unlockuser.php
%attr(755,root,root) /opt/zendto/bin/upgrade_preferences_php
%attr(755,root,root) /opt/zendto/bin/upgrade_zendto_conf
%doc /opt/zendto/bin/README.txt

/etc/cron.d/zendto
%attr(755,root,root) /etc/profile.d/zendto.sh
%attr(755,root,root) /etc/profile.d/zendto.csh

%changelog
* Mon Apr 03 2017 Jules Field <jules@zend.to>
- Added upgrade_zendto_conf
* Tue Mar 14 2017 Jules Field <jules@zend.to>
- Added new HTML email templates
* Thu Dec 22 2016 Jules Field <jules@zend.to>
- Added upgrade_preferences_php
* Sun Dec 18 2016 Jules Field <jules@zend.to>
- Added internaldomains.conf
* Fri Dec 16 2016 Jules Field <jules@zend.to>
- Moved cache, templates_c to /var/zendto
* Mon Nov 28 2016 Jules Field <jules@zend.to>
- Don't package old templates-v3
* Sat Nov 26 2016 Jules Field <jules@zend.to>
- Fixing it up for new release 4.19
* Thu Dec 08 2011 Julian Field <jules@zend.to>
- Added var library directory
* Thu Aug 11 2011 Julian Field <jules@zend.to>
- Added files for Resend functionality
* Sat Jul 16 2011 Julian Field <jules@zend.to>
- Updated UI for MyZendTo, including quota support
* Fri Apr 15 2011 Julian Field <jules@zend.to>
- Added more dependencies, wish CentOS would release v6!
* Wed Mar 30 2011 Julian Field <jules@zend.to>
- Moved existing templates to templates-v3 and added new templates
* Mon Feb 21 2011 Julian Field <jules@zend.to>
- Added "Send a Request"
* Wed Feb 09 2011 Julian Field <jules@zend.to>
- Added progress bars
* Fri Aug 06 2010 Julian Field <jules@zendto.com>
- Added profile.d files
* Tue Jul 27 2010 Julian Field <jules@zendto.com>
- Added addLoginlogTable.php and unlockuser.php
* Sat Jul 24 2010 Julian Field <jules@zendto.com>
- Added MyZendTo application to the package
* Sun Jul 18 2010 Julian Field <jules@zendto.com>
- Added zendto/bin and all Local Authenticator files
* Thu Jul 08 2010 Julian Field <jules@zendto.com>
- 1st edition

