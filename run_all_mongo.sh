#!/bin/bash -ex

#git pull

if [ "$1" == "" ]; then rm -rf test-results;fi

cmds=""

docker build mongo -f mongo/Dockerfile-mongo-build --build-arg BASE=test-arch-no-lto-basic -t mongo-test-arch

docker build mongo -f mongo/Dockerfile-mongo-build --build-arg BASE=test-alhp-v4-no-lto-native --build-arg CH_ARCH=native -t mongo-test-alhp-v4-native
cmds="docker run --rm -v $PWD/test-results:/var/lib/phoronix-test-suite/test-results/ -it mongo-test-alhp-v4-native /run.sh mongo-test-alhp-v4-native mongo; $cmds"

for f in php/Dockerfile.*; do
    type=$(echo $f | sed 's/.*\.//g')
    if [ "$1" != "" ] && [ "$1" != "$type" ]; then continue; fi
    if [ "ubuntu-ondrej" == "$type" ]; then continue; fi

    a=$(grep ARCH $f | sed 's/.* //')
    if [ "$a" != "" ]; then
        if [ "$f" != 'Dockerfile.alhp-v4']; then
            docker build mongo -f mongo/Dockerfile-mongo-copy --build-arg BASE=test-$type-no-lto-native --build-arg COPY_FROM=ch-test-alhp-v4-native -t mongo-test-$type-native
            cmds="docker run --rm -v $PWD/test-results:/var/lib/phoronix-test-suite/test-results/ -it mongo-test-$type-native /run.sh mongo-test-$type-native mongo; $cmds"
        fi

        docker build mongo -f mongo/Dockerfile-mongo-build --build-arg BASE=test-$type-no-lto-native --build-arg CH_ARCH=$a -t mongo-test-$type-$a
        cmds="docker run --rm -v $PWD/test-results:/var/lib/phoronix-test-suite/test-results/ -it mongo-test-$type-$a /run.sh mongo-test-$type-$a mongo; $cmds"
    fi

    docker build mongo -f mongo/Dockerfile-mongo --build-arg BASE=test-$type-no-lto-basic -t mongo-test-$type
    cmds="docker run --rm -v $PWD/test-results:/var/lib/phoronix-test-suite/test-results/ -it mongo-test-$type /run.sh mongo-test-$type mongo; $cmds"
done

wait


sleep 10

bash -xec "$cmds"

if [ "$1" == "" ]; then ./merge.sh;fi
