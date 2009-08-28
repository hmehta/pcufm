#!/bin/bash
# simple script to download and build perl Curses-module

modname=Curses
pkgver=1.27
pkgname=$modname-$pkgver.tgz
source=http://search.cpan.org/CPAN/authors/id/G/GI/GIRAFFED/$pkgname
user=$(whoami)
 
if [ ! "$user" == "root" ]; then
	echo "must be ran as root"
 	exit 1
fi

if [ $(ldconfig -p|grep -c curses) -le 0 ]; then
	echo "libncurses not found, please install"
	exit 1
fi

if [ -f "$pkgname"]; then
	echo "$pkgname already exists"
else
	echo "retrieving source"
	wget $source
fi

echo "unpacking"
tar xzf $pkgname

echo "building"
cd $modname-$pkgver

# install module in vendor directories
perl Makefile.PL INSTALLDIRS=vendor || return 1
make || return 1
make install || return 1

echo "all done"
