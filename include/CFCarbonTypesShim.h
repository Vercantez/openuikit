/* CFCarbonTypesShim.h -- the two Carbon typedefs CF's public headers need and
 * machorun's clean-room MacTypes.h does not carry.
 *
 * WHY THIS EXISTS. src/nscf/NSCFConstantString.m includes CF's
 * ForFoundationOnly.h, to call CF's OWN __CFStringEncodingIsSupersetOfASCII
 * rather than copy its thirty-line table. That include pulls CFString.h and
 * CFPriv.h, which reference four Carbon types. machorun's MacTypes.h defines
 * two of them:
 *
 *     StringPtr          defined
 *     ConstStr255Param   defined
 *     ConstStringPtr     NOT defined   <- here
 *     UTF32Char          NOT defined   <- here
 *
 * MEASURED, not assumed: grep over the whole staged SDK and over /work/cfextra
 * finds UTF32Char in neither.
 *
 * WHY IN THE REPO AND NOT IN /work/cfextra, where the CF census keeps its
 * shims: /work/cfextra is an unversioned container artifact, which is the exact
 * defect #81 records about /work/cfobjc. A header the build cannot compile
 * without belongs where the build recipe lives.
 *
 * NOT A GUESS AT APPLE'S DEFINITIONS -- these are the two lines Apple's own
 * MacTypes.h has, and both are forced: ConstStringPtr is the const spelling of
 * StringPtr, which machorun already defines as `unsigned char *`, and
 * UTF32Char must be exactly 32 bits or CFStringGetLongCharacterForSurrogatePair
 * computes the wrong scalar. If machorun's MacTypes.h ever grows them, DELETE
 * this file -- two definitions of a typedef is a redefinition error, which is
 * the loud failure and the good one.
 */

#ifndef FM_CF_CARBON_TYPES_SHIM_H
#define FM_CF_CARBON_TYPES_SHIM_H

#include <stdint.h>

/* CORRECTION 2026-08-28, from machorun-files and verified here: THIS FILE IS A
 * THIRD COPY, and the omission runs the OTHER way from what I first reported.
 * Measured on both headers:
 *
 *   swiftcore-macho/sdk/libc/MacTypes.h    54 lines   HAS all ten of
 *       Str255 ConstStr255Param StringPtr ConstStringPtr StringHandle
 *       UTF8Char UTF16Char UTF32Char UnicodeScalarValue BytePtr_t
 *   machorun/sdk/local/MacTypes.h         129 lines   OMITS all ten, and says
 *       so in its own header comment -- but HAS AbsoluteTime, OptionBits,
 *       LogicalAddress, Duration and more the 54-line one lacks.
 *
 * THE TWO ARE COMPLEMENTARY, NOT DUPLICATE. Neither is a superset, so
 * "compare, then delete ours" is wrong in BOTH directions as written. My error
 * has a name worth keeping: I preferred the copy that was BIGGER rather than
 * the copy that was a SUPERSET -- 129 against 54 makes one look obviously
 * canonical, and it is not.
 *
 * Consequence: PREFER_MACHORUN_HEADERS=1 in stage_sdk.sh is LOSSY, not
 * neutral. It keeps the header lacking these ten, and THIS FILE is what makes
 * that combination compile -- re-supplying, from a third repo, types that
 * already exist in a second one. Exactly the duplication this project warns
 * about, committed by the person warning about it.
 *
 * THE DELETION SIGNAL IS NOT AUTOMATIC, so it is a contract instead. C permits
 * identical repeated typedefs, so if machorun's header grows these, the
 * duplication compiles SILENTLY and this file rots in place. The #error below
 * is the tripwire: whoever adds them defines MR_MACTYPES_HAS_PASCAL_STRINGS
 * beside them, and this file then refuses to build until it is deleted. One
 * line on their side buys a loud failure here instead of a silent third copy.
 */
#ifdef MR_MACTYPES_HAS_PASCAL_STRINGS
#error "machorun's MacTypes.h now defines the Pascal-string and UTF types. \
DELETE include/CFCarbonTypesShim.h and its -include from build_cf_probes.sh; \
this file exists only to compensate for their absence."
#endif

/* MacTypes.h FIRST, and it is not optional. CF's public headers assume it has
 * already been included -- the CF census gets that from force-including
 * CoreFoundation_Prefix.h, which the nscf compile line does not use. Without
 * it the errors are for StringPtr and ConstStr255Param, which machorun's
 * MacTypes.h DOES define; measuring that (4 errors naming defined types, not
 * 11 naming undefined ones) is what distinguished "the header is missing" from
 * "the header is not being included". */
#include <MacTypes.h>

/* THE PASCAL-STRING FAMILY IS OMITTED ON PURPOSE, NOT BY OVERSIGHT.
 * machorun's MacTypes.h says so in its own header comment (lines 29-30):
 * "the Pascal string family (Str15 .. Str255, StringPtr, StringHandle,
 * ConstStr255Param and the rest) and the string-copy inlines" are excluded.
 * CF's PUBLIC CFString.h still declares four functions that use them
 * (CFStringGetPascalString and friends), so any TU that includes CFString.h
 * needs the types even though nothing here will ever call those functions.
 *
 * CF's own build gets them by force-including CoreFoundation_Prefix.h. A
 * non-CF translation unit should not take CF's whole build prefix just to
 * borrow one inline predicate, so the four types are supplied here instead.
 * The definitions are forced by the API, not chosen: Str255 is a
 * length-prefixed 256-byte buffer, and the pointer spellings follow from it.
 *
 * A correction worth keeping: the first version of this file added only two
 * types, because a `grep -q StringPtr MacTypes.h` said the other two were
 * present. That grep was a SUBSTRING match -- it was finding "StringPtr"
 * inside "ConstStringPtr" in a COMMENT. The types were never there. Checking
 * for a typedef by grepping its name matches prose as readily as code. */
#ifndef __MACTYPES_PASCAL_STRINGS__
#define __MACTYPES_PASCAL_STRINGS__
typedef unsigned char        Str255[256];
typedef unsigned char       *StringPtr;
typedef const unsigned char *ConstStringPtr;
typedef const unsigned char *ConstStr255Param;
#endif

#ifndef __UTF32CHAR__
#define __UTF32CHAR__
/* Must be exactly 32 bits: CFStringGetLongCharacterForSurrogatePair computes a
 * scalar value into it, and a narrower type would silently truncate every
 * astral-plane character. */
typedef uint32_t UTF32Char;
#endif

#endif /* FM_CF_CARBON_TYPES_SHIM_H */
