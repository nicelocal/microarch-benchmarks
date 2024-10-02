#!/bin/bash -ex

if which pacman &>/dev/null; then
    pacman --noconfirm -S rustup git cmake ccache python3 ninja nasm yasm gawk lsb-release wget gnupg curl
    export CC=clang-18
    export CXX=clang++-18

    export CFLAGS="-march=$1 -O3 -pipe -fno-plt -fexceptions \
            -Wp,-D_FORTIFY_SOURCE=3 -Wformat -Werror=format-security \
            -fstack-clash-protection -fcf-protection"
    export CXXFLAGS="$CFLAGS -Wp,-D_GLIBCXX_ASSERTIONS"
    export LDFLAGS="-Wl,-O1 -Wl,--sort-common -Wl,--as-needed -Wl,-z,relro -Wl,-z,now \
            -Wl,-z,pack-relative-relocs"
    export LTOFLAGS="-flto=auto"
    export RUSTFLAGS="target-cpu=$1"

    rustup default stable
    source "$HOME/.cargo/env"

    git clone --recursive --shallow-submodules https://github.com/ClickHouse/ClickHouse.git

    cd ClickHouse
    mkdir build
    cmake -S . -B build
    cmake --build build
    cmake --build build --target clickhouse
elif which swupd &>/dev/null; then
    # Clear linux
else
    curl https://clickhouse.com/ | sh
fi