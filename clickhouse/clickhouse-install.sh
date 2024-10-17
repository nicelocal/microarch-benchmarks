#!/bin/bash -ex


if [ "$CH_ARCH" != "" ]; then
    pacman -Suy
    pacman --noconfirm -S rustup git cmake ccache python3 ninja nasm yasm gawk lsb-release wget gnupg curl clang lld
    export CC=clang
    export CXX=clang++

    rustup default stable

    sed "s/march=native/march=$CH_ARCH/g" -i /ClickHouse/cmake/cpu_features.cmake

    cd /ClickHouse
    mkdir build
    cmake -DARCH_NATIVE=ON -S . -B build
    cmake --build build
    cmake --build build --target clickhouse
    cmake --install build
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

LATEST_VERSION=24.8.5.115
export LATEST_VERSION

case $(uname -m) in
  x86_64) ARCH=amd64 ;;
  aarch64) ARCH=arm64 ;;
  *) echo "Unknown architecture $(uname -m)"; exit 1 ;;
esac

for PKG in clickhouse-common-static clickhouse-common-static-dbg clickhouse-server clickhouse-client clickhouse-keeper
do
  curl -fO "https://packages.clickhouse.com/tgz/stable/$PKG-$LATEST_VERSION-${ARCH}.tgz" \
    || curl -fO "https://packages.clickhouse.com/tgz/stable/$PKG-$LATEST_VERSION.tgz"
done

tar -xzvf "clickhouse-common-static-$LATEST_VERSION-${ARCH}.tgz" \
  || tar -xzvf "clickhouse-common-static-$LATEST_VERSION.tgz"
"clickhouse-common-static-$LATEST_VERSION/install/doinst.sh"

tar -xzvf "clickhouse-common-static-dbg-$LATEST_VERSION-${ARCH}.tgz" \
  || tar -xzvf "clickhouse-common-static-dbg-$LATEST_VERSION.tgz"
"clickhouse-common-static-dbg-$LATEST_VERSION/install/doinst.sh"

tar -xzvf "clickhouse-server-$LATEST_VERSION-${ARCH}.tgz" \
  || tar -xzvf "clickhouse-server-$LATEST_VERSION.tgz"
"clickhouse-server-$LATEST_VERSION/install/doinst.sh" configure
/etc/init.d/clickhouse-server start

tar -xzvf "clickhouse-client-$LATEST_VERSION-${ARCH}.tgz" \
  || tar -xzvf "clickhouse-client-$LATEST_VERSION.tgz"
"clickhouse-client-$LATEST_VERSION/install/doinst.sh"
