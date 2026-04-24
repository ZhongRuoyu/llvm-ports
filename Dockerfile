ARG BASE_IMAGE="buildpack-deps:latest"
FROM "${BASE_IMAGE}"

RUN set -ex; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    gnupg \
  ; \
  rm -rf /var/lib/apt/lists/*

ARG BINUTILS_VERSION
ENV BINUTILS_VERSION="${BINUTILS_VERSION}"

RUN set -ex; \
  \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    bison \
    texinfo \
  ; \
  rm -r /var/lib/apt/lists/*; \
  \
  curl -fL "https://ftpmirror.gnu.org/gnu/binutils/binutils-$BINUTILS_VERSION.tar.xz.sig" -o 'binutils.tar.xz.sig'; \
  curl -fL "https://ftpmirror.gnu.org/gnu/binutils/binutils-$BINUTILS_VERSION.tar.xz" -o 'binutils.tar.xz'; \
  export GNUPGHOME="$(mktemp -d)"; \
  # 4096R/DD9E3C4F 2017-09-18 Nick Clifton (Chief Binutils Maintainer) <nickc@redhat.com>
  gpg --batch --keyserver keyserver.ubuntu.com --recv-keys 3A24BC1E8FB409FA9F14371813FCEF89DD9E3C4F; \
  # 4096R/20DF9190 2020-03-04 Sam James <sam@gentoo.org>
  gpg --batch --keyserver keyserver.ubuntu.com --recv-keys 25A6BB88DD9B764C6B5541C2738409F520DF9190; \
  gpg --batch --verify binutils.tar.xz.sig binutils.tar.xz; \
  gpgconf --kill all || killall gpg-agent dirmngr || true; \
  rm -rf "$GNUPGHOME"; \
  mkdir -p /usr/src/binutils; \
  tar -xf binutils.tar.xz -C /usr/src/binutils --strip-components=1; \
  rm binutils.tar.xz*; \
  \
  dir="$(mktemp -d)"; \
  cd "$dir"; \
  \
  /usr/src/binutils/configure CFLAGS="-Wno-error=discarded-qualifiers"; \
  make -j "$(nproc)"; \
  make install-strip; \
  \
  cd ..; \
  \
  rm -rf "$dir" /usr/src/binutils

ARG CMAKE_VERSION
ENV CMAKE_VERSION="${CMAKE_VERSION}"

RUN set -ex; \
  \
  curl -fL "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-SHA-256.txt.asc" -O; \
  curl -fL "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-SHA-256.txt" -O; \
  curl -fL "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz" -O; \
  export GNUPGHOME="$(mktemp -d)"; \
  # 4096R/7BFB4EDA 2010-02-16 Brad King
  gpg --batch --keyserver keyserver.ubuntu.com --recv-keys CBA23971357C2E6590D9EFD3EC8FEF3A7BFB4EDA; \
  gpg --batch --verify "cmake-${CMAKE_VERSION}-SHA-256.txt.asc" "cmake-${CMAKE_VERSION}-SHA-256.txt"; \
  gpgconf --kill all || killall gpg-agent dirmngr || true; \
  rm -rf "$GNUPGHOME"; \
  sha256sum -c --ignore-missing "cmake-${CMAKE_VERSION}-SHA-256.txt"; \
  mkdir -p /usr/src/cmake; \
  tar -xf "cmake-${CMAKE_VERSION}.tar.gz" -C /usr/src/cmake --strip-components=1; \
  rm "cmake-${CMAKE_VERSION}"*; \
  \
  dir="$(mktemp -d)"; \
  cd "$dir"; \
  \
  /usr/src/cmake/bootstrap --parallel="$(nproc)"; \
  make -j "$(nproc)"; \
  make install/strip; \
  \
  cd ..; \
  \
  rm -rf "$dir" /usr/src/cmake

ENV GPG_KEYS="\
# rsa4096/345AD05D 2015-01-20 Hans Wennborg <hans@chromium.org>
  B6C8F98282B944E3B0D5C2530FC3042E345AD05D \
# rsa4096/86419D8A 2018-05-03 Tom Stellard <tstellar@redhat.com>
  474E22316ABF4785A88C6E8EA2C794A986419D8A \
# rsa3072/45D59042 2022-08-05 Tobias Hieta <tobias@hieta.se>
  D574BD5D1D0E98895E3BF90044F2485E45D59042 \
# ed25519/3F563BDC 2024-10-15 Muhammad Omair Javaid (LLVM Release Signing Key) <omair.javaid@linaro.org>
  0FB96824606D15FDD54C3D092FFC629D3F563BDC \
# ed25519/4A4F9E85 2025-09-15 Cullen Rhodes <cullen.rhodes@arm.com>
  71046D1E9C6656BDD61171873E83BABF4A4F9E85 \
# ed25519/64CACBA5 2025-09-15 Douglas Yung <douglas.yung@sony.com>
  FFB3368980F3E6BB5737145A316C56D064CACBA5"

ARG LLVM_VERSION
ENV LLVM_VERSION="${LLVM_VERSION}"

ARG EXTRA_CMAKE_ARGS

COPY patches/llvm /usr/src/llvm-project/patches
RUN set -ex; \
  \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    python3 \
    python3-setuptools \
  ; \
  rm -r /var/lib/apt/lists/*; \
  \
  curl -fL "https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/llvm-project-${LLVM_VERSION}.src.tar.xz.sig" -o 'llvm-project.tar.xz.sig'; \
  curl -fL "https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/llvm-project-${LLVM_VERSION}.src.tar.xz" -o 'llvm-project.tar.xz'; \
  export GNUPGHOME="$(mktemp -d)"; \
  for key in $GPG_KEYS; do \
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key"; \
  done; \
  gpg --batch --verify llvm-project.tar.xz.sig llvm-project.tar.xz; \
  gpgconf --kill all || killall gpg-agent dirmngr || true; \
  rm -rf "$GNUPGHOME"; \
  mkdir -p /usr/src/llvm-project; \
  tar -xf llvm-project.tar.xz -C /usr/src/llvm-project --strip-components=1; \
  rm llvm-project.tar.xz*; \
  \
  cd /usr/src/llvm-project; \
  LLVM_VERSION_MAJOR="$(echo "$LLVM_VERSION" | cut -d '.' -f 1)"; \
  LLVM_VERSION_MINOR="$(echo "$LLVM_VERSION" | cut -d '.' -f 2)"; \
  LLVM_VERSION_PATCH="$(echo "$LLVM_VERSION" | cut -d '.' -f 3)"; \
  # [nfc] Fix missing include
  # https://github.com/llvm/llvm-project/commit/b498303066a63a203d24f739b2d2e0e56dca70d1
  if [ "$LLVM_VERSION_MAJOR" -ge 8 -a "$LLVM_VERSION_MAJOR" -lt 12 ]; then \
    curl -fL "https://github.com/llvm/llvm-project/commit/b498303066a63a203d24f739b2d2e0e56dca70d1.patch" | patch -p1; \
  fi; \
  # [Support] Add missing <cstdint> header to Signals.h
  # https://github.com/llvm/llvm-project/commit/ff1681ddb303223973653f7f5f3f3435b48a1983
  if [ "$LLVM_VERSION_MAJOR" -lt 14 ] || \
    [ "$LLVM_VERSION_MAJOR" -eq 14 -a "$LLVM_VERSION_MINOR" -eq 0 -a "$LLVM_VERSION_PATCH" -lt 5 ]; then \
    curl -fL "https://github.com/llvm/llvm-project/commit/ff1681ddb303223973653f7f5f3f3435b48a1983.patch" | patch -p1; \
  fi; \
  # [sanitizer] Remove crypt and crypt_r interceptors
  # https://github.com/llvm/llvm-project/commit/d7bead833631486e337e541e692d9b4a1ca14edd
  if [ "$LLVM_VERSION_MAJOR" -ge 12 -a "$LLVM_VERSION_MAJOR" -lt 15 ]; then \
    patch -p1 < patches/backports/12.0.1/compiler-rt-remove-crypt-and-crypt_r-interceptors.patch; \
  elif [ "$LLVM_VERSION_MAJOR" -ge 15 -a "$LLVM_VERSION_MAJOR" -lt 17 ]; then \
    curl -fL "https://github.com/llvm/llvm-project/commit/d7bead833631486e337e541e692d9b4a1ca14edd.patch" | patch -p1; \
  fi; \
  # [Clang] Fix build with GCC 14 on ARM
  if [ "$LLVM_VERSION_MAJOR" -eq 17 ]; then \
    curl -fL "https://src.fedoraproject.org/rpms/clang/raw/f2215348e79ce1534141b0bbc5d4771ce580ddea/f/0001-Clang-Fix-build-with-GCC-14-on-ARM.patch" | patch -p1; \
  fi; \
  # Extend GCC workaround to GCC < 8.4 for llvm::iterator_range ctor (#82643)
  # https://github.com/llvm/llvm-project/commit/7f71fa909a10be182b82b9dfaf0fade6eb84796c
  if [ "$LLVM_VERSION_MAJOR" -eq 17 ]; then \
    curl -fL "https://github.com/llvm/llvm-project/commit/7f71fa909a10be182b82b9dfaf0fade6eb84796c.patch" | patch -p1; \
  fi; \
  # Fix remaining build failures with GCC 8.3 (#83266)
  # https://github.com/llvm/llvm-project/commit/a9304edf20756dd63f896a98bad89e9eac54aebd
  if [ "$LLVM_VERSION_MAJOR" -eq 18 ]; then \
    curl -fL "https://github.com/llvm/llvm-project/commit/a9304edf20756dd63f896a98bad89e9eac54aebd.patch" | patch -p1; \
  fi; \
  # [ADT] Add <cstdint> to SmallVector (#101761)
  # https://github.com/llvm/llvm-project/commit/7e44305041d96b064c197216b931ae3917a34ac1
  if [ "$LLVM_VERSION_MAJOR" -lt 19 ]; then \
    curl -fL "https://github.com/llvm/llvm-project/commit/7e44305041d96b064c197216b931ae3917a34ac1.patch" | patch -p1; \
  fi; \
  # [AMDGPU] Include <cstdint> in AMDGPUMCTargetDesc (#101766)
  # https://github.com/llvm/llvm-project/commit/8f39502b85d34998752193e85f36c408d3c99248
  if [ "$LLVM_VERSION_MAJOR" -ge 12 -a "$LLVM_VERSION_MAJOR" -lt 19 ]; then \
    curl -fL "https://github.com/llvm/llvm-project/commit/8f39502b85d34998752193e85f36c408d3c99248.patch" | patch -p1; \
  fi; \
  # [LLDB] Add <cstdint> to AddressableBits (#102110)
  # https://github.com/llvm/llvm-project/commit/bb59f04e7e75dcbe39f1bf952304a157f0035314
  if [ "$LLVM_VERSION_MAJOR" -eq 18 ]; then \
    curl -fL "https://github.com/llvm/llvm-project/commit/bb59f04e7e75dcbe39f1bf952304a157f0035314.patch" | patch -p1; \
  fi; \
  # adds missing header, removes Bazel unnecessary dependency (#110932)
  # https://github.com/llvm/llvm-project/commit/41eb186fbb024898bacc2577fa3b88db0510ba1f
  if [ "$LLVM_VERSION_MAJOR" -eq 18 ]; then \
    patch -p1 < patches/backports/18.1.8/mlir-include-cstdint.patch; \
  elif [ "$LLVM_VERSION_MAJOR" -eq 19 ]; then \
    patch -p1 < patches/backports/19.1.7/mlir-include-cstdint.patch; \
  fi; \
  # [MLIR] Add missing include (NFC)
  # https://github.com/llvm/llvm-project/commit/101109fc5460d5bb9bb597c6ec77f998093a6687
  if [ "$LLVM_VERSION_MAJOR" -ge 10 -a "$LLVM_VERSION_MAJOR" -lt 20 ]; then \
    curl -fL "https://github.com/llvm/llvm-project/commit/101109fc5460d5bb9bb597c6ec77f998093a6687.patch" | patch -p1; \
  fi; \
  # Add missing include to X86MCTargetDesc.h (#123320)
  # https://github.com/llvm/llvm-project/commit/7abf44069aec61eee147ca67a6333fc34583b524
  if [ "$LLVM_VERSION_MAJOR" -ge 11 -a "$LLVM_VERSION_MAJOR" -lt 19 ]; then \
    patch -p1 < patches/backports/11.1.0/llvm-include-cstdint.patch; \
  elif [ "$LLVM_VERSION_MAJOR" -eq 19 ]; then \
    curl -fL "https://github.com/llvm/llvm-project/commit/7abf44069aec61eee147ca67a6333fc34583b524.patch" | patch -p1; \
  fi; \
  # [sanitizer_common] Remove interceptors for deprecated struct termio (#137403)
  # https://github.com/llvm/llvm-project/commit/59978b21ad9c65276ee8e14f26759691b8a65763
  if [ "$LLVM_VERSION_MAJOR" -ge 12 -a "$LLVM_VERSION_MAJOR" -lt 20 ] || \
    [ "$LLVM_VERSION_MAJOR" -eq 20 -a "$LLVM_VERSION_MINOR" -eq 1 -a "$LLVM_VERSION_PATCH" -lt 6 ]; then \
    curl -fL "https://github.com/llvm/llvm-project/commit/59978b21ad9c65276ee8e14f26759691b8a65763.patch" | patch -p1; \
  fi; \
  # Remove reference to obsolete termio ioctls
  # https://github.com/llvm/llvm-project/commit/c99b1bcd505064f2e086e6b1034ce0b0c91ea5b9
  if [ "$LLVM_VERSION_MAJOR" -ge 12 -a "$LLVM_VERSION_MAJOR" -lt 21 ]; then \
    patch -p1 < patches/backports/12.0.1/compiler-rt-termio-ioctls.patch; \
  fi; \
  if [ "$LLVM_VERSION_MAJOR" -ge 13 ]; then \
    patch -p1 < patches/13.0.1/compiler-rt-include-cstdint.patch; \
  fi; \
  if [ "$LLVM_VERSION_MAJOR" -ge 14 -a "$LLVM_VERSION_MAJOR" -lt 17 ]; then \
    patch -p1 < patches/14.0.6/mlir-linalg-include-cstdint.patch; \
  fi; \
  if [ "$LLVM_VERSION_MAJOR" -ge 13 -a "$LLVM_VERSION_MAJOR" -lt 16 ]; then \
    patch -p1 < patches/13.0.1/mlir-lsp-server-include-cstdint.patch; \
  elif [ "$LLVM_VERSION_MAJOR" -ge 16 ]; then \
    patch -p1 < patches/16.0.6/mlir-lsp-server-include-cstdint.patch; \
  fi; \
  \
  dir="$(mktemp -d)"; \
  cd "$dir"; \
  \
  cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;lld;lldb;mlir;polly" \
    -DLLVM_ENABLE_RUNTIMES="compiler-rt;libcxx;libcxxabi;libunwind;openmp" \
    -DLLVM_BUILD_LLVM_DYLIB=ON \
    -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_INCLUDE_TOOLS=ON \
    -DLLVM_INCLUDE_UTILS=ON \
    # https://github.com/llvm/llvm-project/issues/55517
    -DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON \
    ${EXTRA_CMAKE_ARGS} \
    /usr/src/llvm-project/llvm \
  ; \
  cmake --build . -j "$(nproc)"; \
  cmake --install . --strip; \
  \
  cd ..; \
  \
  rm -rf "$dir" /usr/src/llvm-project

RUN set -ex; \
  if [ -d "/usr/local/lib/$(llvm-config --host-target)/c++" ]; then \
    echo "/usr/local/lib/$(llvm-config --host-target)/c++" > /etc/ld.so.conf.d/000-libc++.conf; \
  else \
    echo "/usr/local/lib/$(llvm-config --host-target)" > /etc/ld.so.conf.d/000-libc++.conf; \
  fi; \
  ldconfig -v
