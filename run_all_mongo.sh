#!/bin/bash -ex

#git pull

if [ "$1" == "" ]; then rm -rf test-results;fi

cmds=""

docker build mongo -f mongo/Dockerfile-mongo-build --build-arg BASE=test-arch-basic -t mongo-test-arch

docker build mongo -f mongo/Dockerfile-mongo-build --build-arg BASE=test-alhp-v4-native --build-arg CH_ARCH=native -t mongo-test-alhp-v4-native

cmds="docker run --rm -v $PWD/test-results:/var/lib/phoronix-test-suite/test-results/ -it mongo-test-alhp-v4-native sh -xec 'screen -d -m mongod; /run.sh mongo-test-alhp-v4-native pts/mongobench'; $cmds"

for f in php/Dockerfile.*; do
    type=$(echo $f | sed 's/.*\.//g')
    if [ "$1" != "" ] && [ "$1" != "$type" ]; then continue; fi
    if [ "ubuntu-ondrej" == "$type" ]; then continue; fi

    a=$(grep ARCH $f | sed 's/.* //')
    if [ "$a" != "" ]; then
        if [ "$f" != 'Dockerfile.alhp-v4' ]; then
            docker build mongo -f mongo/Dockerfile-mongo-copy --build-arg BASE=test-$type-native --build-arg COPY_FROM=mongo-test-alhp-v4-native -t mongo-test-$type-native
            cmds="docker run --rm -v $PWD/test-results:/var/lib/phoronix-test-suite/test-results/ -it mongo-test-$type-native sh -xec 'screen -d -m mongod; /run.sh mongo-test-$type-native pts/mongobench'; $cmds"
        fi

        if [ "$a" != "x86-64" ]; then
            docker build mongo -f mongo/Dockerfile-mongo-build --build-arg BASE=test-$type-native --build-arg CH_ARCH=$a -t mongo-test-$type-$a
            cmds="docker run --rm -v $PWD/test-results:/var/lib/phoronix-test-suite/test-results/ -it mongo-test-$type-$a sh -xec 'screen -d -m mongod; /run.sh mongo-test-$type-$a pts/mongobench'; $cmds"
        fi
    fi

    docker build mongo -f mongo/Dockerfile-mongo --build-arg BASE=test-$type-basic -t mongo-test-$type
    cmds="docker run --rm -v $PWD/test-results:/var/lib/phoronix-test-suite/test-results/ -it mongo-test-$type sh -xec 'screen -d -m mongod; /run.sh mongo-test-$type-basic pts/mongobench'; $cmds"
done

sleep 10

mkdir -p test-results

bash -xec "$cmds"

if [ "$1" == "" ]; then ./merge.sh;fi
