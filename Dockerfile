FROM ubuntu:artful AS dockerized-swift

LABEL de.openreply.version=0.0.1 \
      de.openreply.swift=4.1.2 \
      org.label-schema.vendor="openreply GmbH, Bremen, Germany"

ARG SWIFT_RELEASE=swift-4.1.2
ARG LIBRESSL_VERSION=2.7.3

RUN apt-get update && \
    apt-get install --no-install-recommends -y \
        clang \
        libicu-dev \
        curl \
        libpython2.7 \
        libicu57 \
        libbsd0 \
        libxml2 \
        zlib1g-dev \
        build-essential \
        software-properties-common \
        pkg-config \
        locales \
        libblocksruntime0 && \
    rm -rf /var/lib/apt/lists/* \
    locale-gen en_US.UTF-8 && \
    dpkg-reconfigure locales

RUN curl -k http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-${LIBRESSL_VERSION}.tar.gz -o libressl-${LIBRESSL_VERSION}.tar.gz && \
    tar -xzvf libressl-${LIBRESSL_VERSION}.tar.gz && \
    cd libressl-${LIBRESSL_VERSION} && \
    ./configure && \
    make && \
    make install && \
    ldconfig && \
    cd .. && \
    rm -Rf libressl-${LIBRESSL_VERSION}

RUN curl -k https://swift.org/builds/${SWIFT_RELEASE}-release/ubuntu1610/${SWIFT_RELEASE}-RELEASE/${SWIFT_RELEASE}-RELEASE-ubuntu16.10.tar.gz -o ${SWIFT_RELEASE}-RELEASE-ubuntu16.10.tar.gz && \
    tar zxf ${SWIFT_RELEASE}-RELEASE-ubuntu16.10.tar.gz -C / --strip-components=1  && \
    rm -Rf ${SWIFT_RELEASE}-RELEASE-ubuntu16.10.tar.gz

# script to allow mapping framepointers on linux
RUN mkdir -p $HOME/.scripts && \
    curl -k https://raw.githubusercontent.com/apple/swift/master/utils/symbolicate-linux-fatal -o $HOME/.scripts/symbolicate-linux-fatal && \
    chmod 755 $HOME/.scripts/symbolicate-linux-fatal && \
    echo 'export PATH="$HOME/.scripts:$PATH"' >> $HOME/.profile

ONBUILD ARG STAGE=release
ONBUILD ENV SWIFT_STAGE $STAGE
ONBUILD ADD . /opt/srv
ONBUILD WORKDIR /opt/srv
ONBUILD RUN swift build --configuration $SWIFT_STAGE

