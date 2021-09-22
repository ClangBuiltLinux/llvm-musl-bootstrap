set -eu

MUSL_URL=git://git.musl-libc.org/musl

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
  # TODO: something better than this...like if we updated musl.
  if [[ -d sysroot/usr/local/include ]]; then
    if [[ -n "$(find sysroot/usr/local/include -type f | wc -l)" ]]; then
      return
    fi;
  fi;

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

get_or_fetch_musl
build_musl
