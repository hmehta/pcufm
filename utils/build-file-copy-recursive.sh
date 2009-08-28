#!/bin/bash
# simple script to download and build perl File-Copy-Recursive-module

modname=File-Copy-Recursive
pkgver=0.38
pkgname=$modname-$pkgver.tar.gz
source=http://search.cpan.org/CPAN/authors/id/D/DM/DMUEY/$pkgname
user=$(whoami)

echo "user: $user"

if [ ! "$user" == "root" ]; then
	echo "must be ran as root"
	exit 1
fi

if [ -f "$pkgname" ]; then
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
perl Makefile.PL INSTALLDIRS=vendor || exit 1
make || exit 1
make install || exit 1

echo "all done"
