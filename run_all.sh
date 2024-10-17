#!/bin/bash -ex

#git pull

if [ "$1" == "" ]; then rm -rf test-results;fi

cmds=""

cd php

for f in Dockerfile.*; do
    type=$(echo $f | sed 's/.*\.//g')
    if [ "$1" != "" ] && [ "$1" != "$type" ]; then continue; fi
    
    grep "ARG NATIVE" $f && {
        VARIANTS="basic native"
    } || {
        VARIANTS="basic"
    }
    for NATIVE in $VARIANTS; do
        {
            docker build . --build-arg NATIVE=$NATIVE -f $f -t test-$type-$NATIVE-base
            docker build . --build-arg BASE=test-$type-$NATIVE-base -t test-$type-$NATIVE
        } &
        cmds="docker run --rm -v $PWD/../test-results:/var/lib/phoronix-test-suite/test-results/ -it test-$type-$NATIVE /run.sh $type-$NATIVE phpbench; $cmds"
    done
done

wait


sleep 10

bash -xec "$cmds"

if [ "$1" == "" ]; then ../merge.sh;fi
