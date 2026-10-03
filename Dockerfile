# RepairFuzz -- repair-driven greybox fuzzing (ISSTA 2026)
#
# OPTIONAL. RepairFuzz does not need a container: ./scripts/setup.sh builds it
# natively, and that is the normal path (verified on Ubuntu 20.04/LLVM 10 and
# Ubuntu 24.04/LLVM 18). This image exists for people who want a disposable
# fuzzing sandbox, a reproducible CI environment, or a look at the tool
# without installing an LLVM toolchain.
#
# It pins Ubuntu 20.04 -- the environment the paper's experiments used -- and
# builds AFL++ (patched), grmtools/CPCT+ (patched) and the repair mutators.
# It does NOT build any target to fuzz; bring your own.
#
#   docker build -t repairfuzz .
#   docker run -it --rm repairfuzz
#
# On the host, before fuzzing:
#   echo core | sudo tee /proc/sys/kernel/core_pattern
#
FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive
ENV PIP_ROOT_USER_ACTION=ignore

# Toolchain. Ubuntu 20.04 ships LLVM 10, which gives AFL++'s "LLVM basic mode":
# enough for afl-clang-fast instrumentation, and what the paper's experiments
# used. The llvm-14 line is attempted first (and falls back) to match the
# artefact's own Dockerfile; LLVM 13+ would enable AFL++'s full LLVM mode.
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential curl ca-certificates git make cmake automake \
        flex bison python3-dev python3-setuptools python3-pip \
        libglib2.0-dev libpixman-1-dev cpio \
    && apt-get install -y --no-install-recommends \
        lld-14 llvm-14 llvm-14-dev clang-14 \
       || apt-get install -y --no-install-recommends lld llvm llvm-dev clang \
    && apt-get install -y --no-install-recommends \
        "gcc-$(gcc --version | head -n1 | sed 's/\..*//;s/.* //')-plugin-dev" \
        "libstdc++-$(gcc --version | head -n1 | sed 's/\..*//;s/.* //')-dev" \
    && rm -rf /var/lib/apt/lists/*

# Rust (grmtools and the repair mutators are Rust).
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain stable \
    && ln -s /root/.cargo/bin/* /usr/local/bin/

WORKDIR /repairfuzz
COPY . /repairfuzz

# Fetch + patch + build AFL++ and grmtools, then build every repair mutator
# for the corpus grammars. Building all variants would take considerably
# longer; use scripts/build-mutator.sh for the others.
RUN ./scripts/setup.sh \
    && ./scripts/build-mutator.sh lua  corpus \
    && ./scripts/build-mutator.sh ruby corpus \
    && ./scripts/build-mutator.sh js   corpus \
    && ./scripts/build-mutator.sh php  corpus \
    && ./scripts/build-repair-cli.sh lua corpus

CMD ["/bin/bash"]
