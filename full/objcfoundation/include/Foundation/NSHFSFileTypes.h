// HFS type codes as strings, as in the iOS 26.1 SDK's <Foundation/NSHFSFileTypes.h>
// (FMDB's -applicationIDString uses them).
#ifndef OF_FOUNDATION_NSHFSFILETYPES_H
#define OF_FOUNDATION_NSHFSFILETYPES_H

#import <Foundation/NSObjCRuntime.h>

@class NSString;

#if !defined(__swift__)
NS_ASSUME_NONNULL_BEGIN
/// The four characters of an OSType, quoted: 'abcd'.
FOUNDATION_EXPORT NSString *NSFileTypeForHFSTypeCode(OSType hfsFileTypeCode);
/// The OSType of a quoted four-character string; 0 when it is not one.
FOUNDATION_EXPORT OSType NSHFSTypeCodeFromFileType(NSString * _Nullable fileTypeString);
NS_ASSUME_NONNULL_END
#endif

#endif
