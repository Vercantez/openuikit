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
 * WHAT THIS OMITS versus Apple's 816-line header, deliberately and in full:
 *   - the Pascal string family (Str15 .. Str255, StringPtr, StringHandle,
 *     ConstStr255Param and the rest) and the string-copy inlines
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

/* -------------------------------------------------------------- script codes
 * Vestigial, and one line each; present because the Darwin overlay's constant
 * declarations reference the names. */
typedef SInt16 ScriptCode;
typedef SInt16 LangCode;
typedef SInt16 RegionCode;

#endif /* __MACTYPES__ */
