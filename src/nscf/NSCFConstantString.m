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

/* CF's OWN __CFStringEncodingIsSupersetOfASCII, not a copy of it. It is
 * CF_INLINE in ForFoundationOnly.h:246, so it comes in by include or not at
 * all; reimplementing its thirty-line switch here would be a second answer to
 * a question CF already answers, free to drift from the one CF uses. Requires
 * the CF source tree on the include path (-I .../CoreFoundation/include). */
#include "ForFoundationOnly.h"

typedef unsigned long CFHashCode;

/* Loud, naming itself and the value that reached it, on fd 2. A method that
 * returned a plausible-but-wrong answer here would be read by CF as a normal
 * result -- see the comment on -_getCString:maxLength:encoding:. */
extern long write(int, const void *, unsigned long);
extern void abort(void);
static void __NSCFConstantStringUnimplemented(const char *what, unsigned long v) {
    char b[320];
    unsigned long n = 0;
    const char *p = "UNIMPLEMENTED (__NSCFConstantString): ";
    while (p[n]) { b[n] = p[n]; n++; }
    for (unsigned long i = 0; what[i] && n < sizeof b - 32; i++) b[n++] = what[i];
    b[n++] = ' '; b[n++] = '('; b[n++] = '0'; b[n++] = 'x';
    for (int s = 28; s >= 0; s -= 4) {
        unsigned d = (unsigned)((v >> s) & 0xF);
        b[n++] = (char)(d < 10 ? '0' + d : 'a' + d - 10);
    }
    b[n++] = ')'; b[n++] = '\n';
    (void)!write(2, b, n);
    abort();
}
extern CFTypeID   CFStringGetTypeID(void);
extern CFHashCode CFStringHashCString(const uint8_t *bytes, CFIndex len);
extern CFIndex    CFStringGetLength(CFStringRef);
extern unichar    CFStringGetCharacterAtIndex(CFStringRef, CFIndex);

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

/* --- THE THREE SELECTORS CF DISPATCHES TYPE-ID-FREE ------------------------
 *
 * CF's typeID-FREE dispatch (CFTYPE_OBJC_FUNCDISPATCH, five sites in
 * CFRuntime.c) tests `isa != __CFISAForTypeID(typeID_of(obj))`. For a constant
 * string the isa is __NSCFConstantString, baked into __DATA by the .set alias
 * at compile time, while CFString's slot holds __NSCFString. THEY CAN NEVER
 * MATCH -- the isa is fixed before any registration exists to match it.
 *
 * So constant strings take the ObjC branch of EVERY such dispatch, always, and
 * these three are not optional: without them CFGetTypeID(CFSTR("x")),
 * CFEqual and CFHash on a constant string all die with "unrecognized selector".
 * Measured, not predicted -- that was the state before this block.
 *
 * NONE OF THEM MAY CALL THE CF FUNCTION THAT DISPATCHED TO THEM. That is what
 * turned the crash into a 90-second hang when -hash was first added on the
 * shared base: -hash calling CFHash closes the loop. Each is written to reach
 * only entry points that cannot dispatch back. */

/* CFStringGetTypeID() takes no object, so it cannot dispatch. Returning the
 * constant directly would work too, but this stays correct if CF renumbers. */
- (CFTypeID)_cfTypeID { return CFStringGetTypeID(); }

/* CFStringHashCString takes RAW BYTES, not an object -- no receiver, no
 * dispatch, no cycle. And it is CF's OWN hash function, so agreement with
 * CFHash on a dynamic string of equal content is by construction rather than
 * by a reimplementation that has to be kept in step. That was the objection
 * recorded here when this was first left unimplemented; a byte-taking entry
 * point answers it. Constant strings are 8-bit, which is what this expects. */
- (CFHashCode)hash {
    return CFStringHashCString(CONST_STR(self)->ptr, (CFIndex)CONST_STR(self)->length);
}

/* Length-then-characters, deliberately, rather than CFEqual or CFStringCompare.
 * CFEqual is the function that dispatched here, so calling it cycles.
 * CFStringCompare dispatches -compare:, which this class does not implement,
 * so it would trade a hang for a crash. CFStringGetLength and
 * CFStringGetCharacterAtIndex use the typeID-TAKING dispatch: for a dynamic
 * string it resolves false and runs natively, and for another constant string
 * it dispatches -length / -characterAtIndex:, both of which exist above and
 * neither of which re-enters -isEqual:. Terminating by construction. */
- (BOOL)isEqual:(id)other {
    if (!other) return NO;
    if (other == self) return YES;
    CFStringRef o = (CFStringRef)other;
    CFIndex n = (CFIndex)CONST_STR(self)->length;
    if (CFStringGetLength(o) != n) return NO;
    for (CFIndex i = 0; i < n; i++) {
        if ((unichar)CONST_STR(self)->ptr[i] != CFStringGetCharacterAtIndex(o, i)) return NO;
    }
    return YES;
}

/* --- THE FAST-CONTENTS SELECTORS -------------------------------------------
 *
 * DISCOVERED BY EXECUTION, not by reading the 151-selector list. Driving
 * tests/t18_bundle_identity.c under machorun made CF name what it wanted, one
 * abort at a time; the list said which selectors EXIST, not which are REACHED,
 * and 80 of the 151 are unimplemented while this path needs a handful.
 *
 * Every answer below is a row in
 * ~/swift-macho-linux/full/oracle-userdefaults/darwin-conststring-2026-08-28.txt,
 * measured against real Foundation on macOS 26.5.2. The probe carries two
 * CONTROLS -- a dynamic 8-bit string and a dynamic non-ASCII one -- so that
 * "this is how a CONSTANT string answers" is distinguishable from "this is how
 * any 8-bit string answers". Without them there is no way to tell which
 * behaviour belongs to this class.
 *
 * None of these dispatches. They read the compiler-emitted bytes, which is what
 * makes them terminating by construction rather than by an argument about
 * CF's internals -- the preferred shape per docs/cf-census/selector-reentry.md,
 * and the same reason -hash uses byte-taking CFStringHashCString. */

/* CFString.c:2236 dispatches this from _CFStringGetCStringPtrInternal, whose
 * native answer is `__CFStrContents(str) + skip` for an 8-bit string. A
 * constant string's bytes are the compiler's C literal, so that IS the answer.
 *
 * MEASURED, because both halves were open questions and neither is in a header:
 *
 *   requiresNullTermination YES -> non-NULL, SAME POINTER as NO
 *   byte at [length]            -> 0x00, for "hello", "" and "a/b/c.plist"
 *
 * So the argument does not change the answer, and it does not because the
 * literal is NUL-terminated in __TEXT,__cstring. Had it not been, YES would
 * have had to return NULL -- which is what the dynamic 8-bit control returns
 * (NSTaggedPointerString: NULL for both), confirming the detector is not
 * simply saying non-NULL to everything. */
- (const char *)_fastCStringContents:(BOOL)requiresNullTermination {
    return (const char *)CONST_STR(self)->ptr;
}

/* --- THE THREE BELOW ARE MEASURED BUT **NOT YET EXECUTION-REACHED** --------
 *
 * Said plainly so nobody reads them as evidence. Exactly ONE selector in this
 * block was discovered by an abort naming it: `_fastCStringContents:`. These
 * three come from the same Darwin probe and from dispatch sites adjacent to it
 * in CFString.c, and nothing has yet been observed asking for them.
 *
 * They are here because each is a three-line constant answer with a measured
 * row and a control, and because leaving a known-adjacent dispatch site
 * unimplemented converts a future "unrecognized selector" abort into work
 * someone repeats. They are NOT evidence that the executed set is four.
 * When wall 1 (#80) lifts and CF runs further, whichever of these is actually
 * reached should have that recorded here. */

/* The wide counterpart, dispatched from CFStringGetCharactersPtr
 * (CFString.c:2264). A constant string has no UniChar buffer to hand out, and
 * Darwin's answer is NULL -- measured on all three constants. The non-ASCII
 * dynamic control answers non-NULL for this one, which is what makes NULL here
 * a real answer rather than a stub that always refuses. */
- (const unichar *)_fastCharacterContents {
    return NULL;
}

/* 1536 = 0x600 = kCFStringEncodingASCII, measured for every constant string;
 * the non-ASCII control answers 256 (kCFStringEncodingUnicode) for fastest and
 * 0 (kCFStringEncodingMacRoman) for smallest, so the two are NOT the same
 * question in general -- they merely coincide for ASCII-only contents, which
 * is every narrow literal the compiler emits into this class. */
- (CFStringEncoding)_fastestEncodingInCFStringEncoding { return 0x0600; }
- (CFStringEncoding)_smallestEncodingInCFStringEncoding { return 0x0600; }

/* --- -_getCString:maxLength:encoding: — EXECUTION-REACHED (T19) ------------
 *
 * Named by an abort in T19's CFStringGetCString, exactly as
 * `_fastCStringContents:` was named by T18. CFString.c:2324 dispatches it as
 *
 *     _getCString:buffer maxLength:(NSUInteger)bufferSize - 1 encoding:encoding
 *
 * so `maxLength` is the buffer capacity MINUS the terminator. That is what the
 * call site says; what Darwin DOES is measured, because the boundary is where
 * this either overruns a caller's buffer or refuses a copy that would have fit
 * (darwin-conststring-2026-08-28.txt, "the boundary", CFSTR("hello"), len 5):
 *
 *     maxLength=4 -> false          maxLength=5 -> true, NUL written at [5]
 *
 * So `maxLength == length` SUCCEEDS and the NUL goes one past it: the method
 * writes length+1 bytes when it returns true. Off by one in either direction is
 * a buffer overrun or a spurious failure, and neither is visible from the
 * header.
 *
 * ENCODING. Measured, UTF8/ASCII/MacRoman/ISOLatin1 all return the same bytes
 * for an ASCII string, and Unicode(UTF16) returns TRUE with a real conversion
 * (BOM + widened chars). We do the 8-bit case and REFUSE LOUDLY otherwise
 * rather than returning NO, because CF reads NO as "did not fit" — a wrong
 * answer that is indistinguishable from a legitimate one, which is the
 * silent-plausible shape this project keeps finding. No UTF-16 request has been
 * observed on any path measured so far; when one is, it will name itself here
 * instead of silently degrading.
 *
 * The ASCII-superset test is CF's OWN predicate, included rather than
 * reimplemented — a second copy of that 30-line table is a thing that can
 * drift from the one CF uses to decide the same question. */
- (BOOL)_getCString:(char *)buffer
          maxLength:(NSUInteger)maxLength
           encoding:(CFStringEncoding)encoding
{
    const uint8_t *bytes = CONST_STR(self)->ptr;
    CFIndex n = (CFIndex)CONST_STR(self)->length;

    /* A narrow literal is USUALLY pure ASCII, but nothing guarantees it, and if
     * it is not then the bytes are UTF-8 and only UTF-8 reproduces them. Scan
     * rather than assume: the assumption would be invisible and wrong exactly
     * for the strings where it matters. */
    Boolean allASCII = true;
    for (CFIndex i = 0; i < n; i++) if (bytes[i] & 0x80) { allASCII = false; break; }

    Boolean byteCompatible =
        (allASCII && __CFStringEncodingIsSupersetOfASCII(encoding)) ||
        (encoding == kCFStringEncodingUTF8);

    if (!byteCompatible) {
        __NSCFConstantStringUnimplemented(
            "-_getCString:maxLength:encoding: needs a real transcoding for this "
            "encoding; returning NO would be read as 'did not fit'", encoding);
    }

    if ((CFIndex)maxLength < n) return NO;   /* measured: maxLength EXCLUDES the NUL */
    for (CFIndex i = 0; i < n; i++) buffer[i] = (char)bytes[i];
    buffer[n] = '\0';
    return YES;
}

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