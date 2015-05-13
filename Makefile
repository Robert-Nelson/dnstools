FILES=adauth adupdate.spec adupdate.sysconfig COPYING gennsupd.pl Makefile nm-adupdate Readme.md
ARCHIVE_NAME:=$(shell rpm --qf "%{name}-%{version}" --specfile adupdate.spec)
ARCHIVE_DIR:=/tmp/$(ARCHIVE_NAME)

dist:
	[ -d "$(ARCHIVE_DIR)" ] && rm -rf "$(ARCHIVE_DIR)" || true
	mkdir $(ARCHIVE_DIR)
	cp -p $(FILES) $(ARCHIVE_DIR)
	tar -C /tmp -cjf $(ARCHIVE_NAME).tar.bz2 $(ARCHIVE_NAME)
	rm -rf $(ARCHIVE_DIR)
	
install:
	install -m 0755 -o root -g root -d $(DESTDIR)$(SBINDIR)
	install -m 0700 -o root -g root adauth gennsupd.pl $(DESTDIR)$(SBINDIR)
	install -m 0755 -o root -g root -d $(DESTDIR)$(SYSCONFDIR)/NetworkManager/dispatcher.d/pre-down.d
	install -m 0700 -o root -g root nm-adupdate $(DESTDIR)$(SYSCONFDIR)/NetworkManager/dispatcher.d/40-nm-adupdate
	install -m 0700 -o root -g root nm-adupdate $(DESTDIR)$(SYSCONFDIR)/NetworkManager/dispatcher.d/pre-down.d/40-nm-adupdate
	install -m 0755 -o root -g root -d $(DESTDIR)$(SYSCONFDIR)/sysconfig
	install -m 0744 -o root -g root adupdate.sysconfig $(DESTDIR)$(SYSCONFDIR)/sysconfig/adupdate
