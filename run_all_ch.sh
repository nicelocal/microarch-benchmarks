#!/bin/bash -ex

#git pull

if [ "$1" == "" ]; then rm -rf test-results;fi

cmds=""

for f in Dockerfile.*; do
    type=$(echo $f | sed 's/.*\.//g')
    if [ "$1" != "" ] && [ "$1" != "$type" ]; then continue; fi
    
    docker build . -f Dockerfile-clickhouse --build-arg BASE=test-$type-no-lto -t ch-test-$type
    cmds="docker run --rm -v $PWD/test-results:/var/lib/phoronix-test-suite/test-results/ -it ch-test-$type /run.sh ch-test-$type phpbench; $cmds"

    if grep ARCH $f; then
        docker build . -f Dockerfile-clickhouse --build-arg BASE=test-$type-no-lto-native --build-arg ARCH=native -t ch-test-$type-native
        cmds="docker run --rm -v $PWD/test-results:/var/lib/phoronix-test-suite/test-results/ -it ch-test-$type-native /run.sh ch-test-$type-native phpbench; $cmds"
    fi
done

wait


sleep 10

bash -xec "$cmds"

if [ "$1" == "" ]; then ./merge.sh;fi
