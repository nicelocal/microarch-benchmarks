#!/bin/bash -ex

#git pull

if [ "$1" == "" ]; then rm -rf test-results;fi

cmds=""

for f in Dockerfile.*; do
    type=$(echo $f | sed 's/.*\.//g')
    if [ "$1" != "" ] && [ "$1" != "$type" ]; then continue; fi
    
    grep "ARG TYPE" $f && {
        TYPES="no-lto lto"
        VARIANTS="basic native"
    } || {
        TYPES="no-lto"
        VARIANTS="basic"
    }
    for LTO in $TYPES; do
        for NATIVE in $VARIANTS; do
            if [ "$NATIVE" == "native" ] && [ "$LTO" == "lto" ]; then continue; fi
            {
                docker build . --build-arg TYPE=$LTO --build-arg NATIVE=$NATIVE -f $f -t test-$type-$LTO-$NATIVE-base
                docker build . --build-arg BASE=test-$type-$LTO-$NATIVE-base -t test-$type-$LTO-$NATIVE

                if [ "$LTO" == "lto" ]; then
                    docker build . --build-arg BASE=test-$type-$LTO-$NATIVE --build-arg ARCH=$ARCH -f Dockerfile-clickhouse -t test-ch-$type-$LTO-$NATIVE
                fi
            } &
            #cmds="docker run --rm -v $PWD/test-results:/var/lib/phoronix-test-suite/test-results/ -it test-$type-$LTO-$NATIVE /run.sh $type-$LTO-$NATIVE phpbench; $cmds"

            if [ "$LTO" == "lto" ]; then
                cmds="docker run --rm -v $PWD/test-results:/var/lib/phoronix-test-suite/test-results/ -it test-ch-$type-$LTO-$NATIVE /run.sh ch-$type-$LTO-$NATIVE clickhouse; $cmds"
            fi
        done
    done
done

wait


sleep 10

bash -xec "$cmds"

if [ "$1" == "" ]; then ./merge.sh;fi
