#
# "SystemImager"  
#
#  Copyright (C) 1999-2001 Brian Elliott Finley <brian.finley@baldguysoftware.com>
#  Copyright (C) 2002 Bald Guy Software <brian.finley@baldguysoftware.com>
#  Copyright (C) 2001-2002 Hewlett-Packard Company <dannf@fc.hp.com>
#
#  Others who have contributed to this code:
#    Sean Dague <sean@dague.net>
#
#   $Id$
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#
# Errors when running make:
#   If you encounter errors when running "make", because make couldn't find
#   certain things that it needs, and you are fortunate enough to be building
#   on a Debian system, you can issue the following command to ensure that
#   all of the proper tools are installed.
#
#   On i386: "apt-get install  gcc make patch libc6-dev libpopt-dev wget less \
#             bzip2 sgmltools-lite jadetex docbook-to-man uuid-dev ash rsync \
#             snarf host"
#   On ia64: "apt-get install  gcc make patch libc6.1-dev libc6.1-pic \
#             libpopt-dev wget less bzip2 sgmltools-lite jadetex \
#             docbook-to-man uuid-dev ash rsync snarf host"
#
# SystemImager file location standards:
#   o images will be stored in: /var/lib/systemimager/images/
#   o autoinstall scripts:      /var/lib/systemimager/scripts/
#   o override directories:     /var/lib/systemimager/overrides/
#
#   o web gui pages:            /usr/share/systemimager/web-gui/
#
#   o autoinstall kernels:      /usr/share/systemimager/boot/`arch`/
#   o initial ram disks:        /usr/share/systemimager/boot/`arch`/
#   o autoinstall binaries:     /usr/share/systemimager/boot/`arch`/
#
#   o perl libraries:           /usr/lib/systemimager/perl/
#
#   o docs:                     Use distribution appropriate location.
#                               Defaults to /usr/share/doc/systemimager/ 
#                               for installs from tarball or source.
#
#   o man pages:                /usr/share/man/man8/
#
#   o log files:                /var/log/systemimager/
#
#   o configuration files:      /etc/systemimager/
#   o rsyncd.conf:              /etc/systemimager/rsyncd.conf
#   o rsyncd init script:       /etc/init.d/systemimager
#   
#   o tftp files will be copied to the appropriate destination (as determined
#     by the local SysAdmin when running "mkbootserver".
#
#   o user visible binaries:    /usr/local/bin (default)
#     (lsimage, mkautoinstalldiskette, mkautoinstallcd)
#   o sysadmin binaries:        /usr/local/sbin (default)
#     (all other binaries)
#
# Standards for pre-defined rsync modules:
#   o scripts
#   o boot (directory that holds architecture specific directories with
#           boot files for clients)
#
# XXX include pcmcia utilities in boel-binaries tarball
#
# To do a 'standard-ssh' flavor, do a 'make WITH_SSH=1 all'
#

DESTDIR =
VERSION = $(shell cat VERSION)
FLAVOR = $(shell cat FLAVOR)

TOPDIR  := $(CURDIR)

# RELEASE_DOCS are toplevel files that should be included with all posted
# tarballs, but aren't installed onto the destination machine by default
RELEASE_DOCS = CHANGE.LOG COPYING CREDITS ERRATA README VERSION

# should we be messing with the user's PATH? -dannf
PATH = /sbin:/bin:/usr/sbin:/usr/bin:/usr/bin/X11:/usr/local/sbin:/usr/local/bin
ARCH = $(shell uname -m | sed -e s/i.86/i386/ -e s/sun4u/sparc64/ -e s/arm.*/arm/ -e s/sa110/arm/)
# Follows is a set of arch manipulations to distinguish between ppc types
ifeq ($(ARCH),ppc64)
ifneq ($(strip ls /proc/iSeries)),)
        ARCH=ppc64-iSeries
endif
endif

SUDO = $(shell if [ `id -u` != 0 ]; then `which sudo`; fi)

MANUAL_DIR = $(TOPDIR)/doc/manual_source
MANPAGE_DIR = $(TOPDIR)/doc/man
PATCH_DIR = $(TOPDIR)/patches
LIB_SRC = $(TOPDIR)/lib/SystemImager
SRC_DIR = $(TOPDIR)/src
BINARY_SRC = $(TOPDIR)/sbin

# destination directories
PREFIX = /usr
ETC  = $(DESTDIR)/etc
INITD = $(ETC)/init.d
USR = $(DESTDIR)$(PREFIX)
DOC  = $(USR)/share/doc/systemimager-doc
BIN = $(USR)/bin
SBIN = $(USR)/sbin
MAN8 = $(USR)/share/man/man8
LIB_DEST = $(USR)/lib/systemimager/perl/SystemImager
LOG_DIR = $(DESTDIR)/var/log/systemimager

INITRD_DIR = $(TOPDIR)/initrd_source

BOOT_BIN_DEST     = $(USR)/share/systemimager/boot/$(ARCH)/standard

PXE_CONF_SRC      = etc/pxelinux.cfg
PXE_CONF_DEST     = $(ETC)/systemimager/pxelinux.cfg

BINARIES := mkautoinstallcd mkautoinstalldiskette
SBINARIES := addclients cpimage getimage mkdhcpserver mkdhcpstatic mkautoinstallscript mkbootserver mvimage pushupdate rmimage mkrsyncd_conf mkclientnetboot netbootmond
CLIENT_SBINARIES  := updateclient prepareclient
COMMON_BINARIES   = lsimage

IMAGESRC    = $(TOPDIR)/var/lib/systemimager/images
IMAGEDEST   = $(DESTDIR)/var/lib/systemimager/images
WARNING_FILES = $(IMAGESRC)/README $(IMAGESRC)/CUIDADO $(IMAGESRC)/ACHTUNG
AUTOINSTALL_SCRIPT_DIR = $(DESTDIR)/var/lib/systemimager/scripts
OVERRIDES_DIR = $(DESTDIR)/var/lib/systemimager/overrides
OVERRIDES_README = $(TOPDIR)/var/lib/systemimager/overrides/README

RSYNC_STUB_DIR = $(ETC)/systemimager/rsync_stubs

CHECK_FLOPPY_SIZE = expr \`du -b $(INITRD_DIR)/initrd.img | cut -f 1\` + \`du -b $(LINUX_IMAGE) | cut -f 1\`

BOEL_BINARIES_DIR = $(TOPDIR)/tmp/boel_binaries
BOEL_BINARIES_TARBALL = $(BOEL_BINARIES_DIR).tar.gz

SI_INSTALL = $(TOPDIR)/si_install --si-prefix=$(PREFIX)
GETSOURCE = $(TOPDIR)/tools/getsource

# build everything, install nothing
PHONY += all
all:	$(BOEL_BINARIES_TARBALL) kernel $(INITRD_DIR)/initrd.img manpages

binaries: $(BOEL_BINARIES_TARBALL) kernel $(INITRD_DIR)/initrd.img

# All has been modified as docs don't build on non debian platforms
#
#all:	$(BOEL_BINARIES_TARBALL) kernel $(INITRD_DIR)/initrd.img docs manpages

# Now include the other targets
# This has to be right after all to make all the default target
include $(TOPDIR)/make.d/*.rul $(INITRD_DIR)/initrd.rul

# a complete server install
PHONY += install_server_all
install_server_all:	install_server install_common install_binaries

# a complete client install
PHONY += install_client_all
install_client_all:	install_client install_common

# install server-only architecture independent files
PHONY += install_server
install_server:	install_server_man install_configs install_server_libs \
		install_common_libs
	$(SI_INSTALL) -d $(BIN)
	$(SI_INSTALL) -d $(SBIN)
	$(foreach binary, $(BINARIES), \
		$(SI_INSTALL) -m 755 $(BINARY_SRC)/$(binary) $(BIN);)
	$(foreach binary, $(SBINARIES), \
		$(SI_INSTALL) -m 755 $(BINARY_SRC)/$(binary) $(SBIN);)
	$(SI_INSTALL) -d -m 755 $(LOG_DIR)
	$(SI_INSTALL) -d -m 755 $(BOOT_BIN_DEST)
	$(SI_INSTALL) -d -m 755 $(AUTOINSTALL_SCRIPT_DIR)
	$(SI_INSTALL) -d -m 755 $(OVERRIDES_DIR)
	$(SI_INSTALL) -m 644 $(OVERRIDES_README) $(OVERRIDES_DIR)

# no need to do this on non-i386, though this should be generalized
# somewhere else
ifeq ($(ARCH),i386)
	$(SI_INSTALL) -d -m 755 $(PXE_CONF_DEST)
	$(SI_INSTALL) -m 644 --backup --text $(PXE_CONF_SRC)/message.txt \
		$(PXE_CONF_DEST)/message.txt
	$(SI_INSTALL) -m 644 --backup $(PXE_CONF_SRC)/syslinux.cfg \
		$(PXE_CONF_DEST)/syslinux.cfg
	$(SI_INSTALL) -m 644 --backup $(PXE_CONF_SRC)/syslinux.cfg.noboot \
		$(PXE_CONF_DEST)/syslinux.cfg.noboot
	$(SI_INSTALL) -m 644 --backup $(PXE_CONF_SRC)/syslinux.cfg \
		$(PXE_CONF_DEST)/default
endif

	$(SI_INSTALL) -d -m 755 $(IMAGEDEST)
	$(SI_INSTALL) -m 644 $(WARNING_FILES) $(IMAGEDEST)
	cp -a $(IMAGEDEST)/README $(IMAGEDEST)/DO_NOT_TOUCH_THESE_DIRECTORIES

# install client-only files
PHONY += install_client
install_client: install_client_man install_client_libs install_common_libs
	mkdir -p $(ETC)/systemimager
	$(SI_INSTALL) -b -m 644 etc/updateclient.local.exclude \
	  $(ETC)/systemimager
	$(SI_INSTALL) -b -m 644 etc/client.conf \
	  $(ETC)/systemimager
	mkdir -p $(SBIN)

	$(foreach binary, $(CLIENT_SBINARIES), \
		$(SI_INSTALL) -m 755 $(BINARY_SRC)/$(binary) $(SBIN);)

# install files common to both the server and client
PHONY += install_common
install_common:	install_common_man install_common_libs
	mkdir -p $(BIN)
	$(foreach binary, $(COMMON_BINARIES), \
		$(SI_INSTALL) -m 755 $(BINARY_SRC)/$(binary) $(BIN);)

# install server-only libraries
PHONY += install_server_libs
install_server_libs:
	mkdir -p $(LIB_DEST)
	$(SI_INSTALL) -m 644 $(LIB_SRC)/Server.pm $(LIB_DEST)

# install client-only libraries
PHONY += install_client_libs
install_client_libs:
	mkdir -p $(LIB_DEST)
	$(SI_INSTALL) -m 644 $(LIB_SRC)/Client.pm $(LIB_DEST)

# install common libraries
PHONY += install_common_libs
install_common_libs:
	mkdir -p $(LIB_DEST)
	$(SI_INSTALL) -m 644 $(LIB_SRC)/Common.pm $(LIB_DEST)
	$(SI_INSTALL) -m 644 $(LIB_SRC)/Config.pm $(LIB_DEST)

# checks the sized of the i386 kernel and initrd to make sure they'll fit 
# on an autoinstall diskette
PHONY += check_floppy_size
check_floppy_size:	$(LINUX_IMAGE) $(INITRD_DIR)/initrd.img
ifeq ($(ARCH), i386)
	@### see if the kernel and ramdisk are larger than the size of a 1.44MB
	@### floppy image, minus about 10k for syslinux stuff
	@echo -n "Ramdisk + Kernel == "
	@echo -n "`$(CHECK_FLOPPY_SIZE)`"
	@[ `$(CHECK_FLOPPY_SIZE)` -lt `expr 1474560 - 10240` ] || \
	     (echo "" && \
	      echo "************************************************" && \
	      echo "Dammit.  The kernel and ramdisk are too large.  " && \
	      echo "************************************************" && \
	      exit 1)
	@echo " - ok, that should fit on a floppy"
endif

# install the initscript & config files for the server
PHONY += install_configs
install_configs:
	$(SI_INSTALL) -d $(ETC)/systemimager
	$(SI_INSTALL) -m 644 etc/systemimager.conf \
	  $(ETC)/systemimager/systemimager.conf

	mkdir -p $(RSYNC_STUB_DIR)
	$(SI_INSTALL) -b -m 644 etc/rsync_stubs/10header $(RSYNC_STUB_DIR)
	[ -f $(RSYNC_STUB_DIR)/99local ] \
		&& $(SI_INSTALL) -b -m 644 etc/rsync_stubs/99local $(RSYNC_STUB_DIR)/99local.dist~ \
		|| $(SI_INSTALL) -b -m 644 etc/rsync_stubs/99local $(RSYNC_STUB_DIR)
	$(SI_INSTALL) -b -m 644 etc/rsync_stubs/README $(RSYNC_STUB_DIR)

	[ "$(INITD)" != "" ] || exit 1
	mkdir -p $(INITD)
	$(SI_INSTALL) -b -m 755 etc/init.d/rsync $(INITD)/systemimager
	$(SI_INSTALL) -b -m 755 etc/init.d/netbootmond $(INITD)

########## END initrd ##########


########## BEGIN man pages ##########
# build all of the manpages
PHONY += manpages
manpages:
	$(MAKE) -C $(MANPAGE_DIR)

# install the manpages for the server
PHONY += install_server_man
install_server_man:
	cd $(MANPAGE_DIR) && $(MAKE) install_server_man PREFIX=$(PREFIX) $@

# install the manpages for the client
PHONY += install_client_man
install_client_man:
	cd $(MANPAGE_DIR) && $(MAKE) install_client_man PREFIX=$(PREFIX) $@

# install manpages common to the server and client
PHONY += install_common_man
install_common_man:
	cd $(MANPAGE_DIR) && $(MAKE) install_common_man PREFIX=$(PREFIX) $@

########## END man pages ##########

# installs the manual and some examples
PHONY += install_docs
install_docs: docs
	mkdir -p $(DOC)
	cp -a $(MANUAL_DIR)/html $(DOC)
	cp $(MANUAL_DIR)/*.ps $(MANUAL_DIR)/*.pdf $(DOC)
	mkdir -p $(DOC)/examples
	$(SI_INSTALL) -m 644 etc/rsyncd.conf $(DOC)/examples
	$(SI_INSTALL) -m 644 etc/init.d/rsync $(DOC)/examples

# builds the manual from SGML source
PHONY += docs
docs:
	$(MAKE) -C $(MANUAL_DIR) html ps pdf

# pre-download the source to other packages that are needed by 
# the build system
PHONY += get_source
get_source:	$(ALL_SOURCE)

PHONY += install
install: 
	@echo ''
	@echo 'Read README for installation details.'
	@echo ''

PHONY += install_binaries
install_binaries:	install_kernel initrd_install \
			install_boel_binaries_tarball

### BEGIN autoinstall binaries tarball ###
# Perhaps there could be problems here in building multiple arch's from
# a single source directory, but we'll deal with that later...  Perhaps use
# $(TOPDIR)/tmp/$(ARCH)/ instead of just $(TOPDIR)/tmp/. -BEF-
#

PHONY += install_boel_binaries_tarball
install_boel_binaries_tarball:	$(BOEL_BINARIES_TARBALL)
	$(SI_INSTALL) -m 644 $(BOEL_BINARIES_TARBALL) $(BOOT_BIN_DEST)

PHONY += boel_binaries_tarball
boel_binaries_tarball:	$(BOEL_BINARIES_TARBALL)

$(BOEL_BINARIES_TARBALL):	$(DISCOVER_BINARY) $(DISCOVER_DATA_FILES) \
				$(MKDOSFS_BINARY) $(MKE2FS_BINARY) \
				$(TUNE2FS_BINARY) $(PARTED_BINARY) \
				$(MKJFS_BINARY) $(RAIDTOOLS_BINARIES) \
				$(MKREISERFS_BINARY) $(BC_BINARY) \
				$(SFDISK_BINARY) $(MKXFS_BINARY) \
				$(OPENSSH_BINARIES) $(SRC_DIR)/modules_build-stamp
	#
	# Put binaries in the boel_binaries_tarball...
	#
	rm -fr $(BOEL_BINARIES_DIR)
	mkdir -m 755 -p $(BOEL_BINARIES_DIR)/bin
	mkdir -m 755 -p $(BOEL_BINARIES_DIR)/sbin
	install -m 755 $(BC_BINARY) $(BOEL_BINARIES_DIR)/bin/
	install -m 755 $(DISCOVER_BINARY) $(BOEL_BINARIES_DIR)/sbin/
	install -m 755 $(MKDOSFS_BINARY) $(BOEL_BINARIES_DIR)/sbin/
	install -m 755 $(MKE2FS_BINARY) $(BOEL_BINARIES_DIR)/sbin/
	install -m 755 $(TUNE2FS_BINARY) $(BOEL_BINARIES_DIR)/sbin/
	install -m 755 $(PARTED_BINARY) $(BOEL_BINARIES_DIR)/sbin/
	install -m 755 $(SFDISK_BINARY) $(BOEL_BINARIES_DIR)/sbin/
	install -m 755 $(RAIDTOOLS_BINARIES) $(BOEL_BINARIES_DIR)/sbin/
	cd $(BOEL_BINARIES_DIR)/sbin/ && ln -f raidstart raidstop
	install -m 755 $(MKREISERFS_BINARY) $(BOEL_BINARIES_DIR)/sbin/
	install -m 755 $(MKJFS_BINARY) $(BOEL_BINARIES_DIR)/sbin/
	install -m 755 $(MKXFS_BINARY) $(BOEL_BINARIES_DIR)/sbin/
ifdef WITH_SSH
	install -m 755 $(OPENSSH_BINARIES) $(BOEL_BINARIES_DIR)/sbin/
endif
	#
	# Put libraries in the boel_binaries_tarball...
	#
	#
	# Copy over any special libraries that mklibs.sh probably won't find.  
	# This should be done for any binary that causes a mklibs.sh message 
	# like this: "objcopy: : No such file or directory". -BEF-
	#
	mkdir -m 755 -p $(BOEL_BINARIES_DIR)/lib
	#
	# libparted
	rsync -av $(SRC_DIR)/$(PARTED_DIR)/libparted/.libs/libparted-*.so* \
		$(BOEL_BINARIES_DIR)/lib/
	#
	# libdiscover
	rsync -av $(SRC_DIR)/$(DISCOVER_DIR)/lib/.libs/libdiscover.so* \
		$(BOEL_BINARIES_DIR)/lib/
	strip $(BOEL_BINARIES_DIR)/lib/*
	#
	#
	# Copy over miscellaneous other files...
	#
	mkdir -m 755 -p $(BOEL_BINARIES_DIR)/usr/share/discover
	install -m 644 $(DISCOVER_DATA_FILES) $(BOEL_BINARIES_DIR)/usr/share/discover
	#
	# Use the mklibs.sh script from Debian to find and copy libraries and 
	# any soft links.  Note: This does not require PIC libraries -- it will
	# copy standard libraries if it can't find a PIC equivalent.  -BEF-
	#
	( cd $(BOEL_BINARIES_DIR) && $(TOPDIR)/initrd_source/mklibs.sh -v -d lib sbin/* lib/* )
	#
	#
	# Strip to the bones. -BEF-
	#
	strip $(BOEL_BINARIES_DIR)/bin/*
	strip $(BOEL_BINARIES_DIR)/sbin/*
	#
	#
	# install kernel modules. -BEF-
	#
	$(MAKE) -C $(LINUX_SRC) modules_install \
	    INSTALL_MOD_PATH="$(BOEL_BINARIES_DIR)"
	#
	# Tar it up, baby! -BEF-
	( cd $(BOEL_BINARIES_DIR) && tar -cv * | gzip -9 > $(BOEL_BINARIES_TARBALL) )
	# Note: This tarball should be installed to the "boot/$(ARCH)/" directory.

### END autoinstall binaries tarball ###

PHONY += source_tarball
source_tarball:	$(TOPDIR)/tmp/systemimager-source-$(VERSION).tar.bz2

$(TOPDIR)/tmp/systemimager-source-$(VERSION).tar.bz2:
	mkdir -p tmp/systemimager-source-$(VERSION)
	find . -maxdepth 1 -not -name . -not -name tmp \
	  -exec cp -a {} tmp/systemimager-source-$(VERSION) \;
	rm -rf `find tmp/systemimager-source-$(VERSION) -name CVS \
	         -type d -printf "%p "`
	$(MAKE) -C $(TOPDIR)/tmp/systemimager-source-$(VERSION) distclean
	$(MAKE) -C $(TOPDIR)/tmp/systemimager-source-$(VERSION) get_source
	cd $(TOPDIR)/tmp && tar -ch systemimager-source-$(VERSION) | bzip2 > \
	  systemimager-source-$(VERSION).tar.bz2
	@echo
	@echo "server tarball has been created in $(TOPDIR)/tmp"
	@echo

# create user-distributable tarballs for the server and the client
PHONY += tarballs
tarballs:	
	@ echo -e "\nbinary tarballs are no longer supported\n"

# create a source tarball useable for SRPM and RPM creation
PHONY += srpm_tarball
srpm_tarball:  $(TOPDIR)/tmp/systemimager-$(VERSION).tar.gz

$(TOPDIR)/tmp/systemimager-$(VERSION).tar.gz: systemimager.spec
	mkdir -p tmp/systemimager-$(VERSION)
	find . -maxdepth 1 -not -name . -not -name tmp \
	  -exec cp -a {} tmp/systemimager-$(VERSION) \;
	rm -rf `find tmp/systemimager-$(VERSION) -name CVS \
	         -type d -printf "%p "`
	cd tmp/systemimager-$(VERSION) && $(MAKE) distclean
	cd tmp/systemimager-$(VERSION) && $(MAKE) -j11 get_source
	cd tmp && tar -czf systemimager-$(VERSION).tar.gz systemimager-$(VERSION) 
	@echo
	@echo "srpm tarball has been created in $(TOPDIR)/tmp"
	@echo

# make the srpms for systemimager
PHONY += srpm
srpm: srpm_tarball
	rpm -ts tmp/systemimager-$(VERSION).tar.gz


# make the rpms for systemimager
PHONY += rpm
rpm: srpm_tarball
	rpm -tb tmp/systemimager-$(VERSION).tar.gz

# removes object files, docs, editor backup files, etc.
PHONY += clean
clean:	$(subst .rul,_clean,$(shell cd $(TOPDIR)/make.d && ls *.rul)) initrd_clean
	-$(MAKE) -C $(MANPAGE_DIR) clean
	-$(MAKE) -C $(MANUAL_DIR) clean
	-rm $(MANUAL_DIR)/images

	## where the tarballs are built
	-$(SUDO) rm -rf tmp

	## editor backups
	-find . -name "*~" -exec rm -f {} \;
	-find . -name "#*#" -exec rm -f {} \;

# same as clean, but also removes downloaded source, stamp files, etc.
PHONY += distclean
distclean:	clean initrd_distclean
	-rm -rf $(SRC_DIR) $(INITRD_SRC_DIR)

.PHONY:	$(PHONY)
