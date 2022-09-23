ARG BASE_IMAGE_TAG
FROM buildpack-deps:${BASE_IMAGE_TAG}

ARG BINUTILS_VERSION
ENV BINUTILS_VERSION ${BINUTILS_VERSION}

RUN set -ex; \
    \
    # 4096R/DD9E3C4F 2017-09-18 Nick Clifton (Chief Binutils Maintainer) <nickc@redhat.com>
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys 3A24BC1E8FB409FA9F14371813FCEF89DD9E3C4F; \
    \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        bison \
        texinfo \
    ; \
    rm -r /var/lib/apt/lists/*; \
    \
    curl -fL "ftp://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VERSION.tar.xz.sig" -o 'binutils.tar.xz.sig'; \
    curl -fL "ftp://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VERSION.tar.xz" -o 'binutils.tar.xz'; \
    gpg --batch --verify binutils.tar.xz.sig binutils.tar.xz; \
    mkdir -p /usr/src/binutils; \
    tar -xf binutils.tar.xz -C /usr/src/binutils --strip-components=1; \
    rm binutils.tar.xz*; \
    \
    dir="$(mktemp -d)"; \
    cd "$dir"; \
    \
    /usr/src/binutils/configure; \
    make -j "$(nproc)"; \
    make install-strip; \
    \
    cd ..; \
    \
    rm -rf "$dir" /usr/src/binutils

ARG CMAKE_VERSION
ENV CMAKE_VERSION ${CMAKE_VERSION}

RUN set -ex; \
    \
    # 4096R/7BFB4EDA 2010-02-16 Brad King
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys CBA23971357C2E6590D9EFD3EC8FEF3A7BFB4EDA; \
    \
    curl -fL "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-SHA-256.txt.asc" -O; \
    curl -fL "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-SHA-256.txt" -O; \
    curl -fL "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz" -O; \
    gpg --batch --verify "cmake-${CMAKE_VERSION}-SHA-256.txt.asc" "cmake-${CMAKE_VERSION}-SHA-256.txt"; \
    sha256sum -c --ignore-missing "cmake-${CMAKE_VERSION}-SHA-256.txt"; \
    tar -xf "cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz" -C /usr/local --strip-components=1; \
    rm "cmake-${CMAKE_VERSION}"*

ENV GPG_KEYS \
# 4096R/345AD05D 2015-01-20 Hans Wennborg <hans@chromium.org>
    B6C8F98282B944E3B0D5C2530FC3042E345AD05D \
# 4096R/86419D8A 2018-05-03 Tom Stellard <tstellar@redhat.com>
    474E22316ABF4785A88C6E8EA2C794A986419D8A \
# 3072R/45D59042 2022-08-05 Tobias Hieta <tobias@hieta.se>
    D574BD5D1D0E98895E3BF90044F2485E45D59042

RUN set -ex; \
    for key in $GPG_KEYS; do \
        gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key"; \
    done

ARG LLVM_VERSION
ENV LLVM_VERSION ${LLVM_VERSION}

ARG CMAKE_BUILD_TYPE
ARG EXTRA_CMAKE_ARGS

RUN set -ex; \
    \
    curl -fL "https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/llvm-project-${LLVM_VERSION}.src.tar.xz.sig" -o 'llvm-project.tar.xz.sig'; \
    curl -fL "https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/llvm-project-${LLVM_VERSION}.src.tar.xz" -o 'llvm-project.tar.xz'; \
    gpg --batch --verify llvm-project.tar.xz.sig llvm-project.tar.xz; \
    mkdir -p /usr/src/llvm-project; \
    tar -xf llvm-project.tar.xz -C /usr/src/llvm-project --strip-components=1; \
    rm llvm-project.tar.xz*; \
    \
    cd /usr/src/llvm-project; \
    if [ "$(echo "${LLVM_VERSION}" | cut -d '.' -f 1)" -lt 12 ]; then \
        # [nfc] Fix missing include
        curl -fL "https://github.com/llvm/llvm-project/commit/b498303066a63a203d24f739b2d2e0e56dca70d1.patch" | git apply; \
    fi; \
    \
    dir="$(mktemp -d)"; \
    cd "$dir"; \
    \
    cmake \
        -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}" \
        -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;lld;lldb;mlir;polly" \
        -DLLVM_ENABLE_RUNTIMES="compiler-rt;libcxx;libcxxabi;libunwind;openmp" \
        -DLLVM_BUILD_LLVM_DYLIB=ON \
        # https://github.com/llvm/llvm-project/issues/55517
        -DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON \
        ${EXTRA_CMAKE_ARGS} \
        /usr/src/llvm-project/llvm \
    ; \
    cmake --build . -j "$(nproc)"; \
    cmake --build . --target install; \
    \
    cd ..; \
    rm -rf "$dir" /usr/src/llvm-project

RUN set -ex; \
    if [ -d '/usr/local/lib/x86_64-unknown-linux-gnu/c++' ]; then \
        echo '/usr/local/lib/x86_64-unknown-linux-gnu/c++' > /etc/ld.so.conf.d/000-libc++.conf; \
    else \
        echo '/usr/local/lib/x86_64-unknown-linux-gnu' > /etc/ld.so.conf.d/000-libc++.conf; \
    fi; \
    ldconfig -v
