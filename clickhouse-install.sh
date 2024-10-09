#!/bin/bash -ex


if [ "$CH_ARCH" != "" ]; then
    pacman --noconfirm -S rustup git cmake ccache python3 ninja nasm yasm gawk lsb-release wget gnupg curl clang lld
    export CC=clang
    export CXX=clang++

    export CFLAGS="-march=$CH_ARCH -O3 -pipe -fno-plt -fexceptions \
            -Wp,-D_FORTIFY_SOURCE=3 -Wformat -Werror=format-security \
            -fstack-clash-protection -fcf-protection"
    export CXXFLAGS="$CFLAGS -Wp,-D_GLIBCXX_ASSERTIONS"
    export LDFLAGS="-Wl,-O1 -Wl,--sort-common -Wl,--as-needed -Wl,-z,relro -Wl,-z,now \
            -Wl,-z,pack-relative-relocs"
    export LTOFLAGS="-flto=auto"
    export RUSTFLAGS="-C target-cpu=$CH_ARCH"

    rustup default stable

    cd /ClickHouse
    mkdir build
    cmake -S . -B build
    cmake --build build
    cmake --build build --target clickhouse
    exit 0
fi

if which pacman &>/dev/null; then
    pacman -S --noconfirm sudo
elif which swupd &>/dev/null; then
    # Clear linux
    swupd bundle-add sudo
else
    apt-get install sudo
fi

curl https://clickhouse.com/ | sh
./clickhouse install
