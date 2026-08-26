/* MacTypes.h — clean-room. CFBase.h includes it under TARGET_OS_MAC for the
 * legacy Carbon scalar typedefs and Boolean/OSStatus. Only the types CFBase
 * actually names are reconstructed here; the historical Carbon API surface
 * (Handle, Ptr, FSSpec, ...) is deliberately absent. */
#ifndef __MACTYPES__
#define __MACTYPES__
#include <stdint.h>
#include <stddef.h>
typedef unsigned char           UInt8;
typedef signed char             SInt8;
typedef unsigned short          UInt16;
typedef signed short            SInt16;
typedef unsigned int            UInt32;
typedef signed int              SInt32;
typedef unsigned long long      UInt64;
typedef signed long long        SInt64;
typedef float                   Float32;
typedef double                  Float64;
typedef unsigned char           Boolean;
typedef SInt32                  OSStatus;
typedef UInt32                  OSType;
typedef UInt32                  FourCharCode;
typedef UInt32                  UTF32Char;
typedef UInt16                  UTF16Char;
typedef UInt8                   UTF8Char;
typedef UInt16                  UniChar;
typedef char *                  Ptr;
typedef Ptr *                   Handle;
typedef long                    Size;
typedef SInt16                  OSErr;
typedef unsigned char           Str255[256];
typedef const unsigned char *   ConstStr255Param;
typedef unsigned char           StrFileName[64];
typedef unsigned char *         StringPtr;
typedef const unsigned char *   ConstStringPtr;
typedef unsigned char **        StringHandle;
typedef SInt16                  ScriptCode;
typedef SInt16                  LangCode;
typedef SInt16                  RegionCode;
typedef UInt32                  UnicodeScalarValue;
typedef UInt16                  UniCharCount;
typedef UniChar *               UniCharPtr;
typedef SInt32                  Fixed;
typedef SInt32                  ByteCount;
typedef SInt32                  ItemCount;
typedef UInt32                  ByteOffset;
typedef SInt16                  ResType;
typedef unsigned char           BytePtr_t;
typedef UInt8 *                 BytePtr;
#ifndef NULL
#define NULL ((void *)0)
#endif
enum { noErr = 0 };
#endif /* __MACTYPES__ */
