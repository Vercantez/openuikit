// tagged_pointers.m -- differential probe for docs/STATUS.md 4.1 / UNIMPLEMENTED B0.
//
// Registers a class for tag 1, hand-builds the corresponding MSB-tagged bit
// pattern, and asks the runtime what class it is and what a message to it
// returns. Compile and run the SAME source on both sides.
//
//   macOS 26.1 / arm64, system objc4 :  class=TR   dispatch=42   exit 0
//   Ubuntu 24.04 / aarch64, this port:  class=(nil)              SIGSEGV
//
//   macOS:  clang -isysroot $(xcrun --sdk macosx --show-sdk-path) \
//                 -target arm64-apple-macos13 -O0 -fno-objc-arc \
//                 -Wno-objc-root-class tagged_pointers.m -o t -lobjc
//   Linux:  clang -target aarch64-unknown-linux-gnu -O0 \
//                 -fobjc-runtime=macosx-10.15 -fno-objc-arc -Wno-objc-root-class \
//                 -I<builddir>/include tagged_pointers.m -o t \
//                 -L<builddir> -lobjc -Wl,-rpath,<builddir>
//
// Note: the tag bits are constructed by hand because _objc_makeTaggedPointer
// is an inline in the private objc-internal.h, not an exported symbol, on
// either platform. Applying objc_debug_taggedpointer_obfuscator to the whole
// word makes BOTH sides crash, so the raw form above is the one that
// discriminates.

#include <stdio.h>
#include <stdint.h>
#include <objc/runtime.h>
#include <objc/message.h>
extern uintptr_t objc_debug_taggedpointer_mask;
extern void _objc_registerTaggedPointerClass(int tag, Class cls);
@interface TR { Class isa; } @end
@implementation TR
+ (int)answer { return 1; }
- (int)answer { return 42; }
@end
int main(void){ setvbuf(stdout,NULL,_IONBF,0);
  printf("mask=0x%lx\n", (unsigned long)objc_debug_taggedpointer_mask);
  _objc_registerTaggedPointerClass(1 /*OBJC_TAG_1*/, objc_getClass("TR"));
  // Construct a tagged pointer: MSB tagging -> bit63 set, tag in bits 60..62
  uintptr_t p = (1UL<<63) | ((uintptr_t)1 << 60) | (0x1234UL << 4);
  id obj = (id)p;
  printf("isTagged=%s\n", (p & objc_debug_taggedpointer_mask) ? "yes":"no");
  Class c = object_getClass(obj);
  printf("class=%s\n", c ? class_getName(c) : "(nil)");
  int a = ((int(*)(id,SEL))objc_msgSend)(obj, sel_registerName("answer"));
  printf("dispatch=%d\n", a);
  return 0;
}
