#!/bin/sh -xe

TYPE=$1

export PTS_SILENT_MODE=1
export TEST_RESULTS_NAME=$TYPE

phoronix-test-suite benchmark $2 << EOF
$TYPE
$TYPE
$TYPE
Y
n
EOF