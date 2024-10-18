#!/bin/bash -ex


if [ "$CH_ARCH" != "" ]; then
    pacman --noconfirm -Suy
    pacman --noconfirm -S git cmake ccache python3 pyenv python-pip ninja nasm yasm gawk lsb-release wget gnupg curl clang lld
    export CC=clang
    export CXX=clang++

    pacman -S --noconfirm pyenv
    eval "$(pyenv init --path)"
    pyenv install 3.10
    pyenv global 3.10

    cd /mongo

    wget https://raw.githubusercontent.com/mongodb/mongo/ac3e53404ffcae1fc0fb40d4853832d0106e1fb5/poetry.lock -O poetry.lock
    wget https://raw.githubusercontent.com/mongodb/mongo/ac3e53404ffcae1fc0fb40d4853832d0106e1fb5/pyproject.toml -O pyproject.toml

    export PYTHON_KEYRING_BACKEND=keyring.backends.null.Keyring

    python3 -m venv .venv --prompt mongo
    source .venv/bin/activate
    python3 -m pip install 'poetry==1.5.1'
    until python3 -m poetry add distlib; do :; done
    until python3 -m poetry install --no-root --sync; do :; done

    echo 'CCFLAGS="-march='$CH_ARCH'"' > custom.vars
    python3 buildscripts/scons.py install-mongod --disable-warnings-as-errors --variables-files=custom.vars --experimental-optimization='*'
    mv build/install/bin/* /usr/bin/
    
    mkdir -p /data/db

    exit 0
fi

if which pacman &>/dev/null; then
    pacman --noconfirm -Suy
    pacman --noconfirm -S screen

    useradd test || true
    mkdir -p /home/test
    chown test /home/test
    pacman -S --noconfirm curl openssl chrpath krb5

    for f in mongodb-tools-bin mongosh-bin mongodb-bin; do
        git clone https://aur.archlinux.org/$f.git
        cd $f && chown -R test . && su test -c "makepkg --skippgpcheck -s"
        pacman --noconfirm -U *tar.zst
        cd ..
    done
elif [ -f /usr/bin/swupd ]; then
    # Clear linux
    swupd bundle-add sysadmin-basic

    curl -L https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel93-8.0.1.tgz -o m.tgz
    tar -xf m.tgz
    cp mongodb-linux-x86_64-rhel93-8.0.1/bin/* /usr/bin
    rm m.tgz
else
    curl -L https://repo.mongodb.org/apt/ubuntu/dists/noble/mongodb-org/8.0/multiverse/binary-amd64/mongodb-org-server_8.0.1_amd64.deb -o m.deb
    dpkg -i m.deb
    rm m.deb
    apt-get update && apt-get -y install screen
fi


mkdir -p /data/db
