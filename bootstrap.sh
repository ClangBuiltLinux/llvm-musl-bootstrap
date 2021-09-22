set -eu

LLVM_URL=https://github.com/llvm/llvm-project.git

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
  #rm -rf sysroot
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

function build_libunwind () {
  SYSROOT=$(readlink -f sysroot)
  RESOURCE=$(readlink -f sysroot/usr/local)
  CC=$(which clang)
  CXX=$(which clang++)

  mkdir -p llvm-project/libunwind/build
  pushd llvm-project/libunwind/build
  cmake -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_CXX_COMPILER=$CXX \
    -D CMAKE_CXX_COMPILER_TARGET=x86_64-unknown-linux-musl \
    -D CMAKE_C_COMPILER=$CC \
    -D CMAKE_C_COMPILER_TARGET=x86_64-unknown-linux-musl \
    -D CMAKE_SHARED_LINKER_FLAGS=-resource-dir=$RESOURCE \
    -D LIBUNWIND_ENABLE_STATIC=NO \
    -D LIBUNWIND_USE_COMPILER_RT=YES \
    -D LIBUNWIND_INCLUDE_DOCS=NO \
    -D LLVM_ENABLE_PROJECTS="libunwind" \
    -D LLVM_TARGETS_TO_BUILD="X86;" \
    -G Ninja \
    -S ..
  ninja libunwind.so
  DESTDIR=$SYSROOT ninja install
  popd
}

get_or_fetch_llvm
bootstrap_compiler_rt
./kernel.sh
./musl.sh
build_libunwind
