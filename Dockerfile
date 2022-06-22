FROM ubuntu:20.04 as builder

ENV PATH=${PATH}:/opt/rx-elf-gcc/bin TZ=UTC

RUN set -x \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && apt-get update \
    && apt-get install --yes --no-install-recommends \
        build-essential \
        libgmp-dev \
        libmpfr-dev \
        libmpc-dev \
        libncurses-dev \
        texinfo \
        flex \
        bison \
        file \
        patch \
        unzip \
        wget \
        ca-certificates

RUN set -x \
    && mkdir -p /ws \
    && cd /ws \
    && wget "https://llvm-gcc-renesas.com/downloads/d.php?f=rx/gcc/8.3.0.202202-gnurx/gcc-8.3.0.zip" -O gcc.zip \
    && wget "https://llvm-gcc-renesas.com/downloads/d.php?f=rx/newlib/8.3.0.202202-gnurx/newlib-4.1.0.zip" -O newlib.zip \
    && wget "https://llvm-gcc-renesas.com/downloads/d.php?f=rx/binutils/8.3.0.202202-gnurx/binutils-2.36.1.zip" -O binutils.zip \
    && wget "https://llvm-gcc-renesas.com/downloads/d.php?f=rx/gdb/8.3.0.202202-gnurx/gdb-7.8.2.zip" -O gdb.zip \
    && unzip -q ./binutils.zip \
    && unzip -q ./gcc.zip \
    && unzip -q ./newlib.zip \
    && unzip -q ./gdb.zip \
    && mv ./binutils-* ./binutils \
    && mv ./gcc-* ./gcc \
    && mv ./newlib-* ./newlib \
    && mv ./gdb-* ./gdb \
    && chmod -R +x ./binutils \
    && chmod -R +x ./gcc \
    && chmod -R +x ./newlib \
    && chmod -R +x ./gdb

RUN set -x \
    && sed -i -Ee "s/WARN_FLAGS='.+'/WARN_FLAGS='-w'/g" /ws/gcc/libstdc++-v3/configure

RUN set -x \
    && cd /ws \
    && mkdir build-binutils \
    && cd build-binutils \
    && ../binutils/configure --target=rx-elf --prefix=/opt/rx-elf-gcc --disable-nls --disable-werror \
    && make \
    && make install-strip

RUN set -x \
    && cd /ws \
    && mkdir build-gcc \
    && cd build-gcc \
    && ../gcc/configure --target=rx-elf --prefix=/opt/rx-elf-gcc --disable-nls --disable-werror --enable-languages=c,c++ --disable-shared --enable-lto --with-newlib \
       --disable-libstdcxx-pch \
    && make all-gcc \
    && make install-strip-gcc

RUN set -x \
    && cd /ws \
    && mkdir build-newlib \
    && cd build-newlib \
    && ../newlib/configure --target=rx-elf --prefix=/opt/rx-elf-gcc --disable-nls --disable-werror \
    && make \
    && make install

RUN set -x \
    && cd /ws \
    && cd build-gcc \
    && make \
    && make install-strip

RUN set -x \
    && cd /ws \
    && mkdir build-gdb \
    && cd build-gdb \
    && ../gdb/configure --target=rx-elf --prefix=/opt/rx-elf-gcc --disable-nls --disable-werror \
    && make \
    && make install \
    && strip --strip-unneeded /opt/rx-elf-gcc/bin/rx-elf-gdb \
    && strip --strip-unneeded /opt/rx-elf-gcc/bin/rx-elf-run

FROM ubuntu:20.04

COPY --from=builder \
    /opt/rx-elf-gcc \
    /opt/rx-elf-gcc

RUN set -x \
    && apt-get update \
    && apt-get install --yes --no-install-recommends \
        make \
        git \
        srecord \
        libgmp10 \
        libmpc3 \
        libmpfr6 \
        libncurses6 \
    && mkdir /src \
    && apt-get clean \
    && rm -rf m -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV PATH=${PATH}:/opt/rx-elf-gcc/bin

VOLUME /src
WORKDIR /src
