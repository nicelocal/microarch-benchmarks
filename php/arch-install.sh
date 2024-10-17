#!/bin/bash -e

ARCH=$1
NATIVE=$2

if [ "$NATIVE" == "basic" ]; then
    pacman -S --noconfirm php
    exit 0
fi

sed 's/-flto=auto/-fno-lto/g' -i /etc/makepkg.conf
useradd customtest
mkdir /home/customtest 
chown -R customtest /home/customtest
cd /tmp

if [ "$ARCH" == "arch" ]; then
    echo "MAKEFLAGS=-j$(nproc)" >>/etc/makepkg.conf
    su customtest -c "git clone https://gitlab.archlinux.org/archlinux/packaging/packages/php --depth 1"
    cd php
    ARCH=x86-64
else
    su customtest -c "git clone https://github.com/CachyOS/CachyOS-PKGBUILDS --depth 1"
    cd CachyOS-PKGBUILDS/php
fi

if [ "$NATIVE" == "native" ]; then
    ARCH=native
fi

sed "s/-march=native/-march=$ARCH/g" -i /etc/makepkg.conf

source PKGBUILD && pacman -S --noconfirm --needed --asdeps "${makedepends[@]}" "${depends[@]}"
su customtest -c "makepkg --skippgp --nocheck"
pacman -U --noconfirm *tar.zst
