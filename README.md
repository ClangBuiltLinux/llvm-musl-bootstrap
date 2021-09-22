A set of (poorly-written) shell scripts to demonstrate building LLVM against
musl.

This code is for demonstration purposes only; it should be used only as
reference for cleaner build systems.

An explicit goal is to try to keep the CMAKE variables as explicit in the
sources as possible.

This work is heavily derived and derived entirely from Saleem Abdulrasool's
(@compnerd)
[gist](https://gist.github.com/compnerd/ebbc625a359d1d3e292e1fd2007ecb52).

### Sysroot

Builds a sysroot that looks like:
```
sysroot
└── usr
    └── local
        ├── include
        │   ├── ...
        └── lib
            ├── crt1.o
            ├── crtbeginS.o -> linux/clang_rt.crtbegin-x86_64.o
            ├── crtendS.o -> linux/clang_rt.crtend-x86_64.o
            ├── crti.o
            ├── crtn.o
            ├── ld-musl-x86_64.so.1 -> libc.so
            ├── libc++abi.so -> libc++abi.so.1
            ├── libc++abi.so.1 -> libc++abi.so.1.0
            ├── libc++abi.so.1.0
            ├── libcrypt.a
            ├── libc.so
            ├── libc++.so.1 -> libc++.so.1.0
            ├── libc++.so.1.0
            ├── libdl.a
            ├── libm.a
            ├── libpthread.a
            ├── libresolv.a
            ├── librt.a
            ├── libunwind.so -> libunwind.so.1
            ├── libunwind.so.1 -> libunwind.so.1.0
            ├── libunwind.so.1.0
            ├── libutil.a
            ├── libxnet.a
            ├── linux
            │   ├── clang_rt.crtbegin-x86_64.o
            │   ├── clang_rt.crtend-x86_64.o
            │   └── libclang_rt.builtins-x86_64.a
            ├── rcrt1.o
            └── Scrt1.o
```

### License
```
Copyright 2021 The ClangBuiltLinux project contributors

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
