set -eu

cat << EOF > test.c
#include <stdio.h>
int main() { puts("hello world"); }
EOF

# -fuse-ld: use LLD rather than BFD.
# -rtlib: use compiler-rt rather than libgcc.
# -Xlinker --dynamic-linker: use musl's dynamic loader as the program
#                            interperter.
# --target: use musl rather than glibc.
# -resource-dir: use our compiler-rt builtins.
# --sysroot: use our libc headers
clang test.c \
  -fuse-ld=lld \
  -rtlib=compiler-rt \
  -Xlinker --dynamic-linker=sysroot/usr/local/lib/ld-musl-x86_64.so.1 \
  --target=x86_64-unknown-linux-musl \
  -resource-dir=sysroot/usr/local \
  --sysroot=sysroot/usr/local

./a.out
rm -f test.c a.out
