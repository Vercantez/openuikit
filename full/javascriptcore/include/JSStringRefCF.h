#ifndef JAVASCRIPTCORE_JSSTRINGREFCF_H
#define JAVASCRIPTCORE_JSSTRINGREFCF_H

#include "JSBase.h"

#if __has_include(<CoreFoundation/CoreFoundation.h>)
#include <CoreFoundation/CoreFoundation.h>

#ifdef __cplusplus
extern "C" {
#endif

JSStringRef JSStringCreateWithCFString(CFStringRef string);
CFStringRef JSStringCopyCFString(CFAllocatorRef alloc, JSStringRef string);

#ifdef __cplusplus
}
#endif

#endif

#endif
