set -eu

LINUX_URL=https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git

function update_linux () {
  pushd linux
  git fetch --depth 1
  git reset --hard origin/master
  popd
}

function fetch_linux () {
  git clone --depth=1 $LINUX_URL --branch master --single-branch
}

function get_or_fetch_linux_kernel () {
  if [[ -d linux ]]; then
    update_linux
  else
    fetch_linux
  fi;
}

function build_kernel_headers () {
  SYSROOT=$(readlink -f sysroot)

  pushd linux
  make LLVM=1 INSTALL_HDR_PATH=$SYSROOT/usr/local mrproper headers_install -j$(nproc)
  popd
}

get_or_fetch_linux_kernel
build_kernel_headers
