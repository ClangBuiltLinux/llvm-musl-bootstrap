set -eu

LLVM_URL=https://github.com/llvm/llvm-project.git
MUSL_URL=git://git.musl-libc.org/musl

function update_llvm () {
  pushd llvm-project
  git fetch --depth 1
  git reset --hard origin/main
  popd
}

function fetch_llvm () {
  git clone --depth=1 $LLVM_URL --branch main --single-branch
}

function get_or_fetch_llvm () {
  if [[ -d llvm-project ]]; then
    update_llvm
  else
    fetch_llvm
  fi;
}

function bootstrap_compiler_rt () {
  rm -rf sysroot
  mkdir -p sysroot
  SYSROOT=$(readlink -f sysroot)
  CC=$(which clang)
  CXX=$(which clang++)

  #rm -rf llvm-project/compiler-rt/build
  mkdir -p llvm-project/compiler-rt/build
  pushd llvm-project/compiler-rt/build
  cmake -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_CXX_COMPILER=$CXX \
    -D CMAKE_CXX_COMPILER_TARGET=x86_64-unknown-linux-musl \
    -D CMAKE_C_COMPILER=$CC \
    -D CMAKE_C_COMPILER_TARGET=x86_64-unknown-linux-musl \
    -D COMPILER_RT_BUILD_LIBFUZZER=NO \
    -D COMPILER_RT_BUILD_MEMPROF=NO \
    -D COMPILER_RT_BUILD_ORC=NO \
    -D COMPILER_RT_BUILD_PROFILE=NO \
    -D COMPILER_RT_BUILD_SANITIZERS=NO \
    -D COMPILER_RT_BUILD_XRAY=NO \
    -D COMPILER_RT_DEFAULT_TARGET_TRIPLE=x86_64-unknown-linux-musl \
    -D LLVM_ENABLE_PROJECTS="compiler-rt;" \
    -D LLVM_TARGETS_TO_BUILD="X86;" \
    -G Ninja \
    -S ..
    #-D CMAKE_INSTALL_LIBDIR=lib \
    #-D CMAKE_INSTALL_PREFIX=woof \
    #-D COMPILER_RT_INSTALL_PATH=woof \
    #-D COMPILER_RT_INSTALL_LIBRARY_DIR=woof \
  ninja compiler-rt
  DESTDIR=$SYSROOT ninja install
  popd
}

function update_musl () {
  pushd musl
  git fetch --depth 1
  git reset --hard origin/master
  popd
}

function fetch_musl () {
  git clone --depth=1 $MUSL_URL --branch master --single-branch
}

function get_or_fetch_musl () {
  if [[ -d musl ]]; then
    update_musl
  else
    fetch_musl
  fi;
}

function build_musl () {
  BUILTINS=$(readlink -f sysroot/usr/local/lib/linux/libclang_rt.builtins-x86_64.a)
  CC=$(which clang)
  SYSROOT=$(readlink -f sysroot)
  rm -rf musl/build
  mkdir -p musl/build
  pushd musl/build
  LIBCC=$BUILTINS CC=$CC ../configure \
    --prefix=/usr/local/ \
    --host=x86_64-unknown-linux-musl \
    --syslibdir=/usr/local/lib \
    --disable-static

  make -j$(nproc) AR=llvm-ar RANLIB=llvm-ranlib
  make DESTDIR=$SYSROOT install-libs install-headers -j$(nproc)

  # TODO: hack
  pushd $SYSROOT/usr/local/lib
  ln -sf libc.so ld-musl-x86_64.so.1
  popd
  popd
  ./test_lib.sh
}

#get_or_fetch_llvm
bootstrap_compiler_rt
./kernel.sh
#get_or_fetch_musl
build_musl
