# `libcxx-src/include` — libc++'s PRIVATE source headers

Not part of libc++abi. These are `libcxx/src/include/*.h` from the same
LLVM 18.1.8 tree, and libc++abi includes them by that exact spelling —
`#include "include/atomic_support.h"` in `cxa_exception.cpp`,
`#include "include/refstring.h"` in `stdlib_stdexcept.cpp`. Upstream's CMake
puts `${LIBCXX_SOURCE_DIR}/src` on the include path to satisfy them, so the
directory here is shaped to be used the same way: `-I vendor/libcxxabi/libcxx-src`.

**This is `libcxx/src`, and it is NOT `libcxx/include`.** The distinction is
load-bearing: putting libc++'s PUBLIC header directory on the path shadows the
sysroot's libc++ headers and yields a `_LIBCPP_VERSION` mismatch against
everything else in the tree — a trap foundation-scope hit on the same code and
passed on. `libcxx/src` carries none of the public headers, so it cannot shadow
anything.
