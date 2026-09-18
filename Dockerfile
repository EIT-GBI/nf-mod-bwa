ARG DEBIAN_VERSION=13-slim
ARG BWA_VERSION=0.7.18
ARG BWA_SHA256=194788087f7b9a77c0114aa481b2ef21439f6abab72488c83917302e8d0e7870
# Keep these in step with the samtools module's own Dockerfile. BWA_MEM pipes
# into `samtools sort`, so a pipeline running BWA_MEM and SAMTOOLS_* gets two
# images, and they should not disagree about which samtools they carry.
ARG SAMTOOLS_VERSION=1.23.1
ARG SAMTOOLS_SHA256=32266198a4bc6a6df395d8526688c9697d9c8e472f888c749fdde2e08ea88dd2
ARG HTSLIB_VERSION=1.23.1
ARG HTSLIB_SHA256=f8a3f36effeec38f043c53ab1f2d9ed45064f14205c5ef8e3c815763b90803c4

# builder #####################################################################

FROM debian:${DEBIAN_VERSION} AS builder

ARG BWA_VERSION
ARG BWA_SHA256
ARG BWA_URL="https://github.com/lh3/bwa/archive/refs/tags/v${BWA_VERSION}.tar.gz"
ARG SAMTOOLS_VERSION
ARG SAMTOOLS_SHA256
ARG SAMTOOLS_URL="https://github.com/samtools/samtools/releases/download/${SAMTOOLS_VERSION}/samtools-${SAMTOOLS_VERSION}.tar.bz2"
ARG HTSLIB_VERSION
ARG HTSLIB_SHA256
ARG HTSLIB_URL="https://github.com/samtools/htslib/releases/download/${HTSLIB_VERSION}/htslib-${HTSLIB_VERSION}.tar.bz2"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        libbz2-dev \
        libcurl4-openssl-dev \
        libdeflate-dev \
        liblzma-dev \
        libncurses-dev \
        libssl-dev \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/build

# BWA_MEM pipes straight into `samtools sort`, so samtools ships alongside bwa
# here rather than the pipeline having to stage a second container.
RUN curl -fsSL --retry 3 -o "htslib.tar.bz2" "${HTSLIB_URL}" \
    && echo "${HTSLIB_SHA256}  htslib.tar.bz2" | sha256sum -c - \
    && tar -xjf htslib.tar.bz2 \
    && cd "htslib-${HTSLIB_VERSION}" \
    && ./configure \
        --prefix=/opt/bwa \
        --enable-libcurl \
        --enable-s3 \
        --enable-gcs \
    && make -j"$(nproc)" \
    && make install

RUN curl -fsSL --retry 3 -o "samtools.tar.bz2" "${SAMTOOLS_URL}" \
    && echo "${SAMTOOLS_SHA256}  samtools.tar.bz2" | sha256sum -c - \
    && tar -xjf samtools.tar.bz2 \
    && cd "samtools-${SAMTOOLS_VERSION}" \
    && ./configure \
        --prefix=/opt/bwa \
        --with-htslib=/opt/bwa \
        LDFLAGS="-Wl,-rpath,/opt/bwa/lib" \
    && make -j"$(nproc)" all \
    && make install

# bwa has no configure step; its Makefile drops the binary in the source root.
RUN curl -fsSL --retry 3 -o "bwa.tar.gz" "${BWA_URL}" \
    && echo "${BWA_SHA256}  bwa.tar.gz" | sha256sum -c - \
    && tar -xzf bwa.tar.gz \
    && cd "bwa-${BWA_VERSION}" \
    && make -j"$(nproc)" \
    && install -Dm755 bwa /opt/bwa/bin/bwa \
    && strip /opt/bwa/bin/* /opt/bwa/lib/libhts.so.* || true

# runtime #####################################################################

FROM debian:${DEBIAN_VERSION} AS runtime

ARG DEBIAN_VERSION
ARG BWA_VERSION

LABEL org.opencontainers.image.title="bwa" \
    org.opencontainers.image.description="bwa, with samtools for the sort step, on debian:${DEBIAN_VERSION}" \
    org.opencontainers.image.version="${BWA_VERSION}" \
    org.opencontainers.image.source="https://github.com/lh3/bwa" \
    org.opencontainers.image.licenses="GPL-3.0"

ENV DEBIAN_FRONTEND=noninteractive \
    PATH=/opt/bwa/bin:${PATH} \
    LC_ALL=C.UTF-8

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        libbz2-1.0 \
        libcurl4 \
        libdeflate0 \
        liblzma5 \
        libncursesw6 \
        procps \
        libssl3 \
        zlib1g \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

COPY --from=builder /opt/bwa /opt/bwa

# No ENTRYPOINT: Nextflow invokes the container as `/bin/bash -c ...`, and an
# ENTRYPOINT of ["bwa"] turns that into `bwa /bin/bash`, which fails with:
# [main] unrecognized command '/bin/bash'
CMD ["bwa"]
