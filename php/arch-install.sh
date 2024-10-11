#!/bin/bash -e

if [ "$1" == "no-lto" ]; then
    sed 's/-flto=auto/-fno-lto/g' -i /etc/makepkg.conf

    useradd customtest
    cd /tmp
    if [ "$2" == "arch" ]; then
        echo "MAKEFLAGS=-j$(nproc)" >>/etc/makepkg.conf
        su customtest -c "git clone https://gitlab.archlinux.org/archlinux/packaging/packages/php --depth 1"
        cd php
    else
        su customtest -c "git clone https://github.com/CachyOS/CachyOS-PKGBUILDS --depth 1"
        cd CachyOS-PKGBUILDS/php
        if [ "$3" != "native" ]; then
            sed "s/-march=native/-march=$2/g" -i /etc/makepkg.conf
        fi
    fi
    sed 's/--disable-gcc-global-regs//g' -i PKGBUILD
    source PKGBUILD && pacman -S --noconfirm --needed --asdeps "${makedepends[@]}" "${depends[@]}"
    su customtest -c "makepkg --skippgp --nocheck"
    pacman -U --noconfirm *tar.zst
else
    pacman -S --noconfirm php
fi
