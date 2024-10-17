#!/bin/bash -ex

#git pull

if [ "$1" == "" ]; then rm -rf test-results;fi

cmds=""

docker build mongo -f mongo/Dockerfile-mongo-build --build-arg BASE=test-arch-basic -t mongo-test-arch

docker build mongo -f mongo/Dockerfile-mongo-build --build-arg BASE=test-alhp-v4-native --build-arg CH_ARCH=native -t mongo-test-alhp-v4-native
cmds="docker run --rm -v $PWD/test-results:/var/lib/phoronix-test-suite/test-results/ -it mongo-test-alhp-v4-native 'screen -d -m mongod; /run.sh mongo-test-alhp-v4-native pymongo-inserts'; $cmds"

for f in php/Dockerfile.*; do
    type=$(echo $f | sed 's/.*\.//g')
    if [ "$1" != "" ] && [ "$1" != "$type" ]; then continue; fi
    if [ "ubuntu-ondrej" == "$type" ]; then continue; fi

    a=$(grep ARCH $f | sed 's/.* //')
    if [ "$a" != "" ]; then
        if [ "$f" != 'Dockerfile.alhp-v4']; then
            docker build mongo -f mongo/Dockerfile-mongo-copy --build-arg BASE=test-$type-native --build-arg COPY_FROM=ch-test-alhp-v4-native -t mongo-test-$type-native
            cmds="docker run --rm -v $PWD/test-results:/var/lib/phoronix-test-suite/test-results/ -it mongo-test-$type-native 'screen -d -m mongod; /run.sh mongo-test-$type-native pymongo-inserts'; $cmds"
        fi

        docker build mongo -f mongo/Dockerfile-mongo-build --build-arg BASE=test-$type-native --build-arg CH_ARCH=$a -t mongo-test-$type-$a
        cmds="docker run --rm -v $PWD/test-results:/var/lib/phoronix-test-suite/test-results/ -it mongo-test-$type-$a 'screen -d -m mongod; /run.sh mongo-test-$type-$a pymongo-inserts'; $cmds"
    fi

    docker build mongo -f mongo/Dockerfile-mongo --build-arg BASE=test-$type-basic -t mongo-test-$type
    cmds="docker run --rm -v $PWD/test-results:/var/lib/phoronix-test-suite/test-results/ -it mongo-test-$type 'screen -d -m mongod; /run.sh mongo-test-$type pymongo-inserts'; $cmds"
done

wait


sleep 10

bash -xec "$cmds"

if [ "$1" == "" ]; then ./merge.sh;fi
