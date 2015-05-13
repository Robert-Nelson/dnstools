Name:		adupdate
Version:	0.9.1
Release:	1%{?dist}
BuildArch:	noarch
Summary:	Active Directory Update

License:	GPL
URL:		https://github.com/open-sw/adupdate
Source:		https://github.com/open-sw/adupdate/releases/download/v%{version}/%{name}-%{version}.tar.bz2

Requires:	NetworkManager, samba-common, tdb-tools, krb5-workstation

Buildroot:	%{_tmppath}/%{name}-%{version}-root

%define enable_debug_packages	0

%description
These scripts automatically update an Active Directory Domain Controller whenever the IP address(es)
change.  It uses the machine account registered using Samba to perform secure updates.

%prep
%setup -q

%build

%install
rm -rf $RPM_BUILD_ROOT
%make_install SBINDIR=%{_sbindir} SYSCONFDIR=%{_sysconfdir}

%files
%doc Readme.md COPYING
%config(noreplace) %attr(0744, root, root) %{_sysconfdir}/sysconfig/adupdate
%attr(0700, root, root) %{_sysconfdir}/NetworkManager/dispatcher.d/40-nm-adupdate
%attr(0700, root, root) %{_sysconfdir}/NetworkManager/dispatcher.d/pre-down.d/40-nm-adupdate
%attr(0700, root, root) %{_sbindir}/adauth
%attr(0700, root, root) %{_sbindir}/gennsupd.pl

%changelog
* Wed May 13 2015 Robert Nelson <robertn@the-nelsons.org>
- Initial version

* Wed May 13 2015 Robert Nelson <robertn@the-nelsons.org>
- Update script locations during install
