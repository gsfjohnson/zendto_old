Name: zendto
Version: 4.26
Release: 2
Summary: Web-based File Transfer and Storage System
Group: Networking/WWW
License: GPL
URL: http://zend.to/
Source0: ZendTo-%{version}-%{release}.tgz
BuildArch: noarch
BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX) 
#BuildRequires: 
Requires: php
Requires: php-pdo
Requires: php-ldap

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
%setup -q -n ZendTo-%{version}-%{release}

%build

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/opt/zendto
cp -rp * $RPM_BUILD_ROOT/opt/zendto

cd $RPM_BUILD_ROOT
find . -type f |sed -e 's/^\.//' > $RPM_BUILD_DIR/file.list.%{name}
find . -type l | sed -e 's,^\.,\%attr(-\,root\,root) ,' >> $RPM_BUILD_DIR/file.list.%{name}

%clean
rm -rf $RPM_BUILD_ROOT

%files -f ../file.list.%{name}
%defattr(-,root,root,-)

