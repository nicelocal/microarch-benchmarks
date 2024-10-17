#!/bin/bash -ex

cd test-results
rm -rf merge-*

docker run --rm -v $PWD:/var/lib/phoronix-test-suite/test-results/ -it test-arch-basic phoronix-test-suite merge-results *
f=$(echo merge-*)
docker run --rm -v $PWD:/var/lib/phoronix-test-suite/test-results/ -it test-arch-basic bash -c "phoronix-test-suite result-file-to-html $f && mv /root/merge-*html /var/lib/phoronix-test-suite/test-results/merged.html"
