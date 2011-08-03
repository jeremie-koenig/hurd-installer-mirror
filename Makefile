mir = mirror
dist = dists/unstable
arch = hurd-i386

all:
	$(RM) stamps/mirror
	$(MAKE) stamps/release

stamps/mirror:
	apt-mirror mirror.list
	/var/spool/apt-mirror/var/clean.sh
	touch $@

#ALWAYS:

#override.%:
#	wget -O $@.gz http://ftp.debian.org/debian/indices/$@.gz
#	gunzip -f $@.gz

$(mir)/$(dist)/main/binary-$(arch)/Packages: \
		override.sid.main stamps/mirror
	(cd $(mir) && dpkg-scanpackages . $(CURDIR)/$<) > $@.n
	mv $@.n $@

$(mir)/$(dist)/main/debian-installer/binary-$(arch)/Packages: \
		override.sid.main.debian-installer stamps/mirror
	(cd $(mir) && dpkg-scanpackages -tudeb . $(CURDIR)/$<) > $@.n
	mv $@.n $@

$(mir)/$(dist)/main/source/Sources: stamps/mirror
	(cd $(mir) && dpkg-scansources .) > $@.n
	mv $@.n $@

%.gz: %
	gzip -9 < $< > $@.n
	mv $@.n $@

stamps/packages: \
	$(mir)/$(dist)/main/binary-$(arch)/Packages.gz \
	$(mir)/$(dist)/main/debian-installer/binary-$(arch)/Packages.gz \
	$(mir)/$(dist)/main/source/Sources.gz

#stamps/generate: apt-ftparchive.conf stamps/mirror
#	apt-ftparchive generate $<
#	touch $@

%/Release: stamps/packages #stamps/generate
	apt-ftparchive -c apt-ftparchive.conf release $(shell dirname $@) > $@.n
	mv $@.n $@

%.gpg: %
	$(RM) $@.n
	gpg -ab -o $@.n $<
	mv $@.n $@

stamps/release: $(mir)/$(dist)/Release.gpg
