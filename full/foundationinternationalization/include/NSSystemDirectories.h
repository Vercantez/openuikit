#ifndef OPEN_FOUNDATION_INTERNATIONALIZATION_NS_SYSTEM_DIRECTORIES_H
#define OPEN_FOUNDATION_INTERNATIONALIZATION_NS_SYSTEM_DIRECTORIES_H

/*
 * This header is included by pinned ICU, but its only callers in that source
 * are disabled upstream with #if 0.  Supplying the opaque Darwin declarations
 * avoids patching the third-party source and leaves any future use explicit.
 */
typedef unsigned long NSSearchPathEnumerationState;
typedef unsigned long NSSearchPathDirectory;
typedef unsigned long NSSearchPathDomainMask;

#define NSLibraryDirectory ((NSSearchPathDirectory)5)
#define NSCachesDirectory ((NSSearchPathDirectory)13)
#define NSUserDomainMask ((NSSearchPathDomainMask)1)
#define NSLocalDomainMask ((NSSearchPathDomainMask)2)
#define NSNetworkDomainMask ((NSSearchPathDomainMask)4)

#ifdef __cplusplus
extern "C" {
#endif
NSSearchPathEnumerationState NSStartSearchPathEnumeration(
    NSSearchPathDirectory, NSSearchPathDomainMask);
NSSearchPathEnumerationState NSGetNextSearchPathEnumeration(
    NSSearchPathEnumerationState, char *);
#ifdef __cplusplus
}
#endif

#endif
