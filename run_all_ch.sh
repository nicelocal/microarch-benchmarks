#!/bin/bash -ex

#git pull

if [ "$1" == "" ]; then rm -rf test-results;fi

cmds=""

docker build clickhouse -f clickhouse/Dockerfile-clickhouse-build --build-arg BASE=test-arch-basic -t ch-test-arch

docker build clickhouse -f clickhouse/Dockerfile-clickhouse-build --build-arg BASE=test-alhp-v4-native --build-arg CH_ARCH=native -t ch-test-alhp-v4-native
cmds="docker run --rm -v $PWD/test-results:/var/lib/phoronix-test-suite/test-results/ -it ch-test-alhp-v4-native /run.sh ch-test-alhp-v4-native clickhouse; $cmds"

for f in php/Dockerfile.*; do
    type=$(echo $f | sed 's/.*\.//g')
    if [ "$1" != "" ] && [ "$1" != "$type" ]; then continue; fi
    if [ "ubuntu-ondrej" == "$type" ]; then continue; fi
    
    a=$(grep ARCH $f | sed 's/.* //')
    if [ "$a" != "" ]; then
        if [ "$f" != 'Dockerfile.alhp-v4' ]; then
            docker build clickhouse -f clickhouse/Dockerfile-clickhouse-copy --build-arg BASE=test-$type-native --build-arg COPY_FROM=ch-test-alhp-v4-native -t ch-test-$type-native
            cmds="docker run --rm -v $PWD/test-results:/var/lib/phoronix-test-suite/test-results/ -it ch-test-$type-native sh -xec '/run.sh ch-test-$type-native clickhouse'; $cmds"
        fi

        docker build clickhouse -f clickhouse/Dockerfile-clickhouse-build --build-arg BASE=test-$type-native --build-arg CH_ARCH=$a -t ch-test-$type-$a
        cmds="docker run --rm -v $PWD/test-results:/var/lib/phoronix-test-suite/test-results/ -it ch-test-$type-$a sh -xec '/run.sh ch-test-$type-$a clickhouse'; $cmds"
    fi

    docker build clickhouse -f clickhouse/Dockerfile-clickhouse --build-arg BASE=test-$type-basic -t ch-test-$type
    cmds="docker run --rm -v $PWD/test-results:/var/lib/phoronix-test-suite/test-results/ -it ch-test-$type sh -xec '/run.sh ch-test-$type-basic clickhouse'; $cmds"
done

wait


sleep 10

bash -xec "$cmds"

if [ "$1" == "" ]; then ./merge.sh;fi
