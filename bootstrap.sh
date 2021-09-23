set -eu

LLVM_URL=https://github.com/llvm/llvm-project.git

function update_llvm () {
  pushd llvm-project
  # hack for https://reviews.llvm.org/D97572.
  git fetch --depth 1 origin 3a6365a439ede4b7c65076bb42b1b7dbf72216b5
  #git checkout FETCH_HEAD
  #git fetch --depth 1
  git reset --hard FETCH_HEAD
  popd
}

function fetch_llvm () {
  #git clone --depth=1 $LLVM_URL --branch main --single-branch
  mkdir llvm-project
  pushd llvm-project
  git init
  git remote add origin $LLVM_URL
  git fetch --depth 1 origin 3a6365a439ede4b7c65076bb42b1b7dbf72216b5
  git checkout FETCH_HEAD
  popd
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
    #-D COMPILER_RT_BUILD_CRT=YES \
  ninja compiler-rt
  DESTDIR=$SYSROOT ninja install
  popd
}

function build_libunwind () {
  SYSROOT=$(readlink -f sysroot)
  RESOURCE=$(readlink -f sysroot/usr/local)
  CC=$(which clang)
  CXX=$(which clang++)

  # - LIBUNWIND_COMPILE_FLAGS: flags used to compile libunwind
  # - LIBUNWIND_LINK_FLAGS: flags used to link libunwind
  # - LIBUNWIND_LIBRARIES: libraries to link libunwind to.
  rm -rf llvm-project/libunwind/build #
  mkdir -p llvm-project/libunwind/build
  pushd llvm-project/libunwind/build
  cmake -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_CXX_COMPILER=$CXX \
    -D CMAKE_CXX_COMPILER_TARGET=x86_64-unknown-linux-musl \
    -D CMAKE_C_COMPILER=$CC \
    -D CMAKE_C_COMPILER_TARGET=x86_64-unknown-linux-musl \
    -D CMAKE_SHARED_LINKER_FLAGS=-resource-dir=$RESOURCE \
    -D LIBUNWIND_ENABLE_STATIC=NO \
    -D LIBUNWIND_INCLUDE_DOCS=NO \
    -D LIBUNWIND_USE_COMPILER_RT=YES \
    -D LLVM_TARGETS_TO_BUILD="X86;" \
    -D LIBUNWIND_TARGET_TRIPLE=x86_64-unknown-linux-musl \
    -D LIBUNWIND_SYSROOT=$RESOURCE \
    -D CMAKE_REQUIRED_FLAGS="-rtlib=compiler-rt -resource-dir=$RESOURCE" \
    --debug-trycompile \
    -G Ninja \
    -S ..
    #-D CMAKE_REQUIRED_LINK_OPTIONS="-rtlib=compiler-rt;-resource-dir=$RESOURCE" \
    #-D CMAKE_EXE_LINKER_FLAGS="-Xlinker --dynamic-linker=$RESOURCE/lib/ld-musl-x86_64.so.1" \
    #-D LIBUNWIND_COMPILE_FLAGS="-Xlinker --dynamic-linker=$RESOURCE/lib/ld-musl-x86_64.so.1" \
    #-D LIBUNWIND_LINK_FLAGS="-Xlinker --dynamic-linker=$RESOURCE/lib/ld-musl-x86_64.so.1" \
    #-D LIBUNWIND_LINK_FLAGS="--sysroot=$RESOURCE" \
    #-D CMAKE_CXX_COMPILER_WORKS=YES \
    #-D CMAKE_EXE_LINKER_FLAGS="-nostdlib" \
    #-D LLVM_ENABLE_PROJECTS="libunwind" \
    #-D CMAKE_EXE_LINKER_FLAGS="-resource-dir=$RESOURCE --sysroot=$RESOURCE" \
  ninja libunwind.so
  DESTDIR=$SYSROOT ninja install
  popd
}

# Saleem: c++abi is the libc equivalent for c++: it is the language runtime;
# libc++ is the C++ standard library
function build_libcxxabi () {
  SYSROOT=$(readlink -f sysroot/)
  RESOURCE=$(readlink -f sysroot/usr/local)
  LIBCXX=$(readlink -f llvm-project/libcxx)
  CC=$(which clang)
  CXX=$(which clang++)

  # TODO: a hack
  pushd sysroot/usr/local/lib
  if [[ ! -e crtbeginS.o ]]; then
    ln -s linux/clang_rt.crtbegin-x86_64.o crtbeginS.o
  fi
  if [[ ! -e crtendS.o ]]; then
    ln -s linux/clang_rt.crtend-x86_64.o crtendS.o
  fi
  popd

  #rm -rf llvm-project/libcxxabi/build #
  mkdir -p llvm-project/libcxxabi/build
  pushd llvm-project/libcxxabi/build
  # TODO: link with lld
  cmake -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_CXX_COMPILER_WORKS=YES \
    -D CMAKE_CXX_COMPILER=$CXX \
    -D CMAKE_CXX_COMPILER_TARGET=x86_64-unknown-linux-musl \
    -D CMAKE_C_COMPILER=$CC \
    -D CMAKE_C_COMPILER_TARGET=x86_64-unknown-linux-musl \
    -D LIBCXXABI_ENABLE_STATIC=NO \
    -D LIBCXXABI_LIBCXX_INCLUDES=$LIBCXX/include \
    -D LIBCXXABI_LIBCXX_PATH=$LIBCXX \
    -D LIBCXXABI_TARGET_TRIPLE=x86_64-unknown-linux-musl \
    -D LIBCXXABI_USE_COMPILER_RT=YES \
    -D LIBCXXABI_USE_LLVM_UNWINDER=YES \
    -D LIBCXXABI_SYSROOT=$RESOURCE \
    -D LIBCXXABI_SUPPORTS_NOSTDLIBXX_FLAG=NO \
    -D CMAKE_EXE_LINKER_FLAGS="-rtlib=compiler-rt -resource-dir=$RESOURCE --sysroot=$RESOURCE" \
    -G Ninja \
    -S ..
    #-D CMAKE_SHARED_LINKER_FLAGS=-resource-dir=$RESOURCE \
    #-D LLVM_ENABLE_PROJECTS="libcxxabi" \
    #-D LLVM_TARGETS_TO_BUILD="X86;" \
    # -D CMAKE_CXX_COMPILER_WORKS=YES seems like a hack, but we can't test
    # what we haven't built yet.
    #--debug-trycompile \
  ninja libc++abi.so
  DESTDIR=$SYSROOT ninja install
  popd
}

function build_libcxx () {
  CC=$(which clang)
  CXX=$(which clang++)
  SYSROOT=$(readlink -f sysroot/)
  RESOURCE=$(readlink -f sysroot/usr/local)

  #rm -rf llvm-project/libcxx/build #
  mkdir -p llvm-project/libcxx/build
  pushd llvm-project/libcxx/build

  # TODO: link with lld
  cmake \
    -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_CXX_COMPILER=$CXX \
    -D CMAKE_CXX_COMPILER_TARGET=x86_64-unknown-linux-musl \
    -D CMAKE_CXX_COMPILER_WORKS=YES \
    -D CMAKE_C_COMPILER=$CC \
    -D CMAKE_C_COMPILER_TARGET=x86_64-unknown-linux-musl \
    -D LIBCXX_ENABLE_STATIC=NO \
    -D LIBCXX_CXX_ABI=libcxxabi \
    -D LIBCXX_TARGET_TRIPLE=x86_64-unknown-linux-musl \
    -D LIBCXX_SYSROOT=$SYSROOT/usr/local \
    -D LIBCXX_HAS_MUSL_LIBC=YES \
    -D LIBCXX_USE_COMPILER_RT=YES \
    -D LIBCXX_INCLUDE_BENCHMARKS=NO \
    -D CMAKE_EXE_LINKER_FLAGS="-rtlib=compiler-rt -resource-dir=$RESOURCE --sysroot=$RESOURCE" \
    -D LIBCXX_SUPPORTS_NOSTDLIBXX_FLAG=NO \
    -G Ninja \
    -S ..
    # TODO: should we add LIBCXX_BUILTINS_LIBRARY="${SYSROOT}/usr/local/lib/linux/libclang_rt.builtins-x86_64.a"
    # as per @compnerd?
    #--debug-trycompile \
    #-D CMAKE_C_COMPILER_WORKS=YES \
    #-D LIBCXX_LINK_FLAGS="-stdlib=libc++" \
    #-D LIBCXX_LINK_FLAGS="-nodefaultlibs -lc -rtlib=compiler-rt" \
  ninja libc++.so
  DESTDIR=$SYSROOT ninja install-cxx install-cxx-headers

  popd
}

get_or_fetch_llvm
bootstrap_compiler_rt
./kernel.sh
./musl.sh
build_libunwind
build_libcxxabi
build_libcxx

# Fangrui says try:
# -DLLVM_HOST_TRIPLE= 
