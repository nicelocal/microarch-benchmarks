#!/bin/bash -ex


if [ "$CH_ARCH" != "" ]; then
    pacman --noconfirm -S git cmake ccache python3 ninja nasm yasm gawk lsb-release wget gnupg curl clang lld
    export CC=clang
    export CXX=clang++

    cd /mongo
    python3 -m venv python3-venv --prompt mongo
    source python3-venv/bin/activate
    
    python3 -m pip --no-use-pep517 install 'poetry==1.5.1'
    python3 -m poetry install --no-root --sync

    python3 buildscripts/scons.py install-mongod
    ninja -f opt.ninja -j 200 install-devcore
    
    exit 0
fi

if which pacman &>/dev/null; then
    useradd test
    mkdir /home/test
    chown test /home/test
    pacman -S --noconfirm curl openssl chrpath krb5

    for f in mongodb-tools-bin mongosh-bin mongodb-bin; do
        git clone https://aur.archlinux.org/$f.git
        cd $f && chown -R test . && su test -c "makepkg --skippgpcheck -s"
        pacman --noconfirm -U *tar.zst
        cd ..
    done
elif which swupd &>/dev/null; then
    # Clear linux
    wget https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel93-8.0.1.tgz
    tar -xf mongodb-linux-x86_64-rhel93-8.0.1.tgz
    cp mongodb-linux-x86_64-rhel93-8.0.1/bin/* /usr/bin
else
    wget https://repo.mongodb.org/apt/ubuntu/dists/noble/mongodb-org/8.0/multiverse/binary-amd64/mongodb-org-server_8.0.1_amd64.deb
    dpkg -i mongodb-org-server_8.0.1_amd64.deb
fi
