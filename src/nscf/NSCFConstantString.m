/* __NSCFConstantString — the class every CFSTR literal's isa points at.
 *
 * See docs/NSCF_DESIGN.md. Two things make this class unlike the other 18:
 *
 *   1. Its instances are laid out BY THE COMPILER, not by
 *      _CFRuntimeCreateInstance, so its storage shape is the one shape in the
 *      whole surface that we do not choose. The layout below was MEASURED from
 *      a real CFSTR on macOS rather than read off a header, because the header
 *      offers two layouts behind DEPLOYMENT_RUNTIME_SWIFT and does not say
 *      which is in effect. A first version that assumed the other one
 *      segfaulted dereferencing the length as a pointer.
 *
 *   2. It is why this file exists at all. With -fconstant-cfstrings the
 *      compiler stamps every CFSTR's isa with ___CFConstantStringClassReference,
 *      and corelibs' CFRuntime.c DEFINES that symbol as a zeroed int[24]. So
 *      CF_IS_OBJC is already true for every constant string, and restoring CF's
 *      dispatch macros armed it: CF would message a zeroed array as a class.
 *
 * THE OTHER HALF, and the easy one to forget: CF's zeroed definition must be
 * DELETED, not shadowed. Two definitions in two dylibs bind CF's own constant
 * strings to the placeholder and Foundation's to this class -- constant strings
 * split in half, silently, with every symbol resolving.
 */

#import <objc/NSObject.h>
#import "../../include/NSCFType.h"   /* the shared lifetime base */
#import <objc/runtime.h>
#include <stdint.h>
#include <string.h>

#import "../../include/CFFoundationTypes.h"

/* The measured layout. isa at +0, _cfinfoa at +8, bytes at +16, length at +24 --
 * a TWO-word CFRuntimeBase. Named to match corelibs' `struct CF_CONST_STRING`,
 * whose initialiser produces exactly this and whose 0x000007c8 literal is the
 * value observed in word[1]. */
struct __CFConstStrLayout {
    uintptr_t  isa;
    uintptr_t  cfinfoa;
    uint8_t   *ptr;
    uint32_t   length;
};

/* Constant strings are 8-bit. CF's _cfinfoa carries an encoding bit, but every
 * CFSTR the compiler emits from a narrow literal is ASCII/UTF-8 bytes -- which
 * is why the field is `uint8_t *` and not `unichar *`. A wide literal produces
 * a different constant class on Darwin, not a wide __NSCFConstantString. */
#define CONST_STR(self) ((struct __CFConstStrLayout *)(self))

@interface __NSCFConstantString : __NSCFType
@end

@implementation __NSCFConstantString

/* --- the NSString primitives ------------------------------------------------
 * Everything else NSString offers is derived from these two. Keeping the
 * concrete class to the primitives is the class-cluster contract and is also
 * what makes one implementation serve both consumers: the selectors CF and
 * libswiftCore share are almost exactly this set. */

- (NSUInteger)length {
    return (NSUInteger)CONST_STR(self)->length;
}

- (unichar)characterAtIndex:(NSUInteger)index {
    /* No bounds check by design: NSString's contract is that an out-of-range
     * index is programmer error, and Darwin raises rather than returning a
     * sentinel. Raising needs NSException, which is not in this slice yet, so
     * this is deliberately left to fault loudly rather than silently return
     * garbage for an index the caller should not have passed. */
    return (unichar)CONST_STR(self)->ptr[index];
}

/* --- lifetime ---------------------------------------------------------------
 * Constant strings live in __DATA and are never deallocated. Darwin's
 * refcounting for them is a no-op, and getting this wrong is not benign: a
 * release path that reached free() would be freeing a section, not a heap
 * block. */

- (instancetype)retain { return self; }
- (oneway void)release { }
- (instancetype)autorelease { return self; }
- (NSUInteger)retainCount { return (NSUInteger)-1; }

/* --- identity ---------------------------------------------------------------
 * -hash and -isEqual: are primitives for a value type, and CF reaches them
 * through CFHash/CFEqual's typeID-free dispatch path. The hash must agree with
 * CFStringHashCString, which libswiftCore also looks up by dlsym -- so this is
 * deliberately NOT a private invention. Left unimplemented until that function
 * is available to call rather than reimplemented here, because two hash
 * functions that disagree would produce a dictionary that loses keys. */

@end

/* The symbol the compiler stamps into every constant CFString.
 *
 * `___CFConstantStringClassReference` in asm; clang emits a reference to it for
 * each __DATA,__cfstring entry. Aliasing it to the class object is what makes a
 * CFSTR a real Objective-C object.
 *
 * DEFINED HERE AS AN ALIAS, landing in the same commit as the patch that
 * deletes CF's zeroed definition (scripts/patch_cf_objc.py, patch_constant_
 * string). Neither half is correct alone, and the two failures are not
 * symmetric:
 *
 *   alias without the deletion   two definitions of one symbol in two dylibs.
 *                                Every symbol resolves and nothing complains.
 *                                CF's own constant strings bind to the zeroed
 *                                placeholder in its own image and everyone
 *                                else's bind here -- constant strings split in
 *                                half, silently.
 *   deletion without the alias   an undefined symbol in every image holding a
 *                                CFSTR. Loud, and harmless by comparison,
 *                                which is the order to prefer if they ever do
 *                                come apart.
 *
 * WHY AN ASM ALIAS AND NOT A C DEFINITION. The compiler emits a reference to
 * the raw symbol, and what it must point at is the class OBJECT itself -- the
 * address [__NSCFConstantString class] returns. A C variable holding that
 * address is one indirection too many: each CFSTR's isa would then point at a
 * pointer rather than at a class. `.set` makes the two names denote one
 * address, which is the relationship Darwin's own Foundation establishes for
 * this symbol.
 */
__asm__(".globl ___CFConstantStringClassReference\n\t"
        ".set   ___CFConstantStringClassReference, "
        "_OBJC_CLASS_$___NSCFConstantString\n");

Class __NSCFConstantStringClass(void) { return [__NSCFConstantString class]; }
