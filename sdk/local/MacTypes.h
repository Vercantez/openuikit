/*
 * MacTypes.h -- machorun's clean-room replacement.
 *
 * NOT Apple's header. This is the SECOND genuine category-(c) header in this
 * SDK -- present only in the Xcode SDK, in no apple-oss-distributions release
 * -- after sdk/local/math.h. docs/SDK_SURVEY.md's headline ("the
 * genuinely-only-in-the-Xcode-SDK category is empty") was corrected to "off by
 * one" when math.h was written; it is off by two.
 *
 * Checked rather than assumed: MacTypes.h is not at EXTERNAL_HEADERS/ in the
 * pinned xnu, and not in Libc. Both 404.
 *
 * WHY IT IS HERE AT ALL, since nothing in this project is Carbon. Swift's
 * `Darwin.swiftinterface` declares
 *
 *     public var noErr: Darwin.OSStatus { get }
 *
 * so `import Darwin` needs the type `OSStatus` visible in module `Darwin`, and
 * Apple's Darwin.modulemap gives it to the `MacTypes` submodule whose one
 * header is this file. Without it the chain fails on a type, several modules
 * after the one that is actually missing.
 *
 * WHAT THIS IS: the scalar type vocabulary, which is what OSStatus lives in and
 * what every other reference in the interface reaches for. These are fixed-
 * width typedefs with published, stable meanings -- there is nothing to
 * transcribe and nothing to get creatively right.
 *
 * THE PASCAL STRING FAMILY WAS ONCE OMITTED HERE AND IS NOT ANY MORE (#88,
 * 2026-08-27). It was removed on the reasoning that nothing should reach for
 * it -- and ~/swiftcore-macho's own clean-room MacTypes.h supplies it, so
 * something did. When machorun's SDK grew this file the two collided, and the
 * proposed resolution ("machorun's is canonical, delete the other") would have
 * DROPPED TEN TYPEDEFS, because the 129-line file is not a superset of the
 * 54-line one: measured, 40 typedefs against 41, each missing names the other
 * has. Size was doing the arguing. The Pascal-string and UTF families are
 * therefore merged in below, from Apple's own definitions, so that this file
 * IS the superset the reconciliation assumed it was.
 *
 * WHAT THIS OMITS versus Apple's 816-line header, deliberately and in full:
 *   - the Pascal string INLINES (the string-copy/compare helpers); the TYPES
 *     are present, the functions are not
 *   - the Carbon numeric types beyond Fixed: Fract, ShortFixed, wide,
 *     UnsignedWide, Float80/Float96, extended80/extended96, NumVersion
 *   - the QuickDraw-era aggregates: Point, Rect, Pattern, Style, VersRec
 *   - ProcPtr and the UniversalProcPtr / routine-descriptor machinery
 *   - the Debugger/DebugStr declarations, which are calls into a system
 *     component this project does not have
 * Anything reaching for one of those gets an undeclared-identifier error
 * naming it, which is the outcome this SDK prefers over a plausible stub.
 */

#ifndef __MACTYPES__
#define __MACTYPES__

#include <stdint.h>
#include <stdbool.h>

/* ------------------------------------------------------- fixed-width scalars
 * Apple spells these over the C99 types on every modern platform; the widths
 * are the whole content of the names. */
typedef int8_t   SInt8;
typedef int16_t  SInt16;
typedef int32_t  SInt32;
typedef int64_t  SInt64;
typedef uint8_t  UInt8;
typedef uint16_t UInt16;
typedef uint32_t UInt32;
typedef uint64_t UInt64;

typedef float  Float32;
typedef double Float64;

/* 16.16 signed fixed point. Kept because it is a scalar and costs one line;
 * the rest of the Carbon numeric zoo is not. */
typedef SInt32 Fixed;
typedef Fixed *FixedPtr;

/* -------------------------------------------------------------- error codes
 * THE REASON THIS FILE EXISTS. OSStatus is signed 32-bit and OSErr is the
 * older signed 16-bit form; `noErr` is 0 in both. */
typedef SInt16 OSErr;
typedef SInt32 OSStatus;

#ifndef noErr
#define noErr 0
#endif

/* --------------------------------------------------------------- addresses */
typedef char           *Ptr;
typedef Ptr            *Handle;
typedef long            Size;

typedef void           *LogicalAddress;
typedef const void     *ConstLogicalAddress;
typedef void           *PhysicalAddress;
typedef UInt8          *BytePtr;
typedef unsigned long   ByteCount;
typedef unsigned long   ByteOffset;
typedef unsigned long   ItemCount;
typedef UInt32          OptionBits;
typedef SInt32          Duration;
typedef UInt64          AbsoluteTime;

/* ------------------------------------------------------------ four-char codes
 * A FourCharCode is four bytes read as a big-endian UInt32 -- 'moov', 'TEXT'.
 * OSType and ResType are the same thing under their historical names. */
typedef UInt32 FourCharCode;
typedef FourCharCode OSType;
typedef FourCharCode ResType;
typedef OSType  *OSTypePtr;
typedef ResType *ResTypePtr;

/* ---------------------------------------------------------------- booleans
 * Boolean IS `unsigned char` on Darwin, not `bool` and not `int`: it is one
 * byte in every struct that has ever contained one, and widening it would move
 * every field after it. */
typedef unsigned char Boolean;

#ifndef TRUE
#define TRUE 1
#endif
#ifndef FALSE
#define FALSE 0
#endif

/* ------------------------------------------------------------------ Unicode
 * UniChar is UTF-16, which is what makes it 16 bits rather than a wchar_t. */
typedef UInt16        UniChar;
typedef UniChar      *UniCharPtr;
typedef unsigned long UniCharCount;
typedef UniCharCount *UniCharCountPtr;

/* The transfer-format character types. Widths are the whole content of the
 * names, and each is pinned by sdk/tests/abi_probe.c against Apple's own
 * header -- a typedef of the wrong width compiles perfectly and is exactly
 * what a differential catches. */
typedef UInt32 UnicodeScalarValue;
typedef UInt32 UTF32Char;
typedef UInt16 UTF16Char;
typedef UInt8  UTF8Char;

/* A FEATURE MACRO, because a REDEFINITION WOULD NOT FAIL. ~/foundation-macho
 * carries a CFCarbonTypesShim.h that re-supplies these types -- written while
 * this header still omitted them -- and the natural assumption is that the
 * duplicate becomes a loud redefinition error once this header grows them.
 * IT DOES NOT: C permits a typedef to be repeated IDENTICALLY, so the third
 * copy would compile silently and rot in place, which is the shadowing shape
 * one file over. This macro is what lets that shim say
 *
 *     #ifdef MR_MACTYPES_HAS_PASCAL_STRINGS
 *     #error "...delete include/CFCarbonTypesShim.h..."
 *     #endif
 *
 * and turn its own removal from something somebody must remember into
 * something the compiler insists on. Requested by the shim's author, who found
 * the redefinition assumption was wrong; it is one line here and a refusal
 * there. It is named for the Pascal family specifically because that is what
 * the shim re-supplies -- a broader name would be asserting more than this
 * comment can back. Apple's header has no such macro, which is why it is NOT
 * in sdk/tests/abi_probe.c: that probe compiles against Apple's SDK on the
 * oracle side and a macro only we define has no oracle to agree with. The
 * downstream #error is the check of record. */
#define MR_MACTYPES_HAS_PASCAL_STRINGS 1

/* -------------------------------------------------------- Pascal strings
 * A length byte followed by that many characters, which is why Str255 is 256
 * bytes and not 255. Present because ~/swiftcore-macho's clean-room copy
 * supplies them and something links against that; see the note at the top of
 * this file about which of the two headers was actually the superset.
 *
 * StrFileName is spelled Apple's way -- Str63, not a bare [64] array -- so the
 * name means what it means on Darwin rather than merely being the right size.
 * That distinction costs one typedef and is the difference between a
 * transcription and a coincidence. */
typedef unsigned char           Str63[64];
typedef unsigned char           Str255[256];
typedef Str63                   StrFileName;
typedef unsigned char          *StringPtr;
typedef StringPtr              *StringHandle;
typedef const unsigned char    *ConstStringPtr;
typedef const unsigned char    *ConstStr255Param;

/* -------------------------------------------------------------- script codes
 * Vestigial, and one line each; present because the Darwin overlay's constant
 * declarations reference the names. */
typedef SInt16 ScriptCode;
typedef SInt16 LangCode;
typedef SInt16 RegionCode;

#endif /* __MACTYPES__ */
