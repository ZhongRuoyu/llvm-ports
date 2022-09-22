# LLVM Ports

This project ports the [LLVM Project](https://llvm.org/) to recent Debian
and Ubuntu releases.

## Images

The ports are available as Docker images at
[Docker Hub](https://hub.docker.com/r/zhongruoyu/llvm-ports). They also come
with the Debian/Ubuntu release's default [GCC](https://gcc.gnu.org/), and the
latest releases of [GNU Binutils](https://www.gnu.org/software/binutils/)
(currently version 2.39) and [CMake](https://cmake.org/) (currently version
3.24.2).

The image tags are in the format of `version-codename`, where `version` is the
LLVM release version, and `codename` is the codename of the Debian/Ubuntu
release. For example, tag `15.0.1-jammy` refers to the image with LLVM 15.0.1
on Ubuntu 22.04 (Jammy Jellyfish).

The following LLVM releases are available:

| LLVM release | versions as appeared in tags |
| ------------ | ---------------------------- |
| LLVM 15.0.1  | `15`, `15.0`, `15.0.1`       |
| LLVM 14.0.6  | `14`, `14.0`, `14.0.6`       |
| LLVM 13.0.1  | `13`, `13.0`, `13.0.1`       |
| LLVM 12.0.1  | `12`, `12.0`, `12.0.1`       |
| LLVM 11.1.0  | `11`, `11.1`, `11.1.0`       |

The following Debian/Ubuntu releases are available:

| Release                        | codename as appeared in tags |
| ------------------------------ | ---------------------------- |
| Debian 11 (Bullseye)           | `bullseye`                   |
| Debian 10 (Buster)             | `buster`                     |
| Ubuntu 22.04 (Jammy Jellyfish) | `jammy`                      |
| Ubuntu 20.04 (Focal Fossa)     | `focal`                      |
| Ubuntu 18.04 (Bionic Beaver)   | `bionic`                     |

All images provide the [LLVM Core](https://llvm.org/) libraries,
[Clang](https://clang.llvm.org/),
[Extra Clang Tools](https://clang.llvm.org/extra/index.html),
[Flang](https://flang.llvm.org/docs/), [LLD](https://lld.llvm.org/),
[LLDB](https://lldb.llvm.org/), [MLIR](https://mlir.llvm.org/),
[Polly](https://polly.llvm.org/), [compiler-rt](https://compiler-rt.llvm.org/),
[libc++](https://libcxx.llvm.org/), [libc++ ABI](https://libcxxabi.llvm.org/),
libunwind, and [OpenMP](https://openmp.llvm.org/).

See [here](https://hub.docker.com/r/zhongruoyu/llvm-ports/tags) for a complete
list of tags.

## License

This project is licensed under the [GPL-3.0 License](LICENSE).