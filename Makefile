#!/usr/bin/make -f

## generic deb build script version 0.6

DESTDIR ?= /

all:
	@echo "make all is not required."

dist:
	./make-helper.bsh dist

dist-build-dep::
	@sudo apt-get update
	@grep Build-Depends: debian/control | cut -d: -f 2- |\
	    sed -e 's/ *, */\n/g'| cut -d'(' -f 1 |tr -d " " |\
	    xargs sudo apt-get install -y

manpages:
	./make-helper.bsh manpages

uch:
	./make-helper.bsh uch

install:
	./make-helper.bsh install

deb-pkg: dist-build-dep
	./make-helper.bsh deb-pkg ${ARGS}

deb-pkg-signed: dist-build-dep
	./make-helper.bsh deb-pkg-signed ${ARGS}

deb-pkg-install:
	./make-helper.bsh deb-pkg-install ${ARGS}

deb-pkg-source:
	./make-helper.bsh deb-pkg-source ${ARGS}

deb-install:
	./make-helper.bsh deb-install

deb-icup:
	./make-helper.bsh deb-icup

deb-remove:
	./make-helper.bsh deb-remove

deb-purge:
	./make-helper.bsh deb-purge

deb-clean:
	./make-helper.bsh deb-clean

deb-cleanup:
	./make-helper.bsh deb-cleanup

dput-ubuntu-ppa:
	./make-helper.bsh dput-ubuntu-ppa

clean:
	./make-helper.bsh clean

distclean:
	./make-helper.bsh distclean

checkout:
	./make-helper.bsh checkout

installcheck:
	./make-helper.bsh installcheck

installsim:
	./make-helper.bsh installsim

uninstallcheck:
	./make-helper.bsh uninstallcheck

uninstall:
	./make-helper.bsh uninstall

uninstallsim:
	./make-helper.bsh uninstallsim

deb-chl-bumpup:
	./make-helper.bsh deb-chl-bumpup

help:
	./make-helper.bsh help

