ARG BASE

FROM $BASE

RUN curl -L https://github.com/phoronix-test-suite/phoronix-test-suite/releases/download/v10.8.4/phoronix-test-suite-10.8.4.tar.gz | tar -xvz && \
cd phoronix-test-suite* && \
./install-sh


ADD user-config.xml /etc/phoronix-test-suite.xml
ADD run.sh /