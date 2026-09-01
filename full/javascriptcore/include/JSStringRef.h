#ifndef JAVASCRIPTCORE_JSSTRINGREF_H
#define JAVASCRIPTCORE_JSSTRINGREF_H

#include "JSBase.h"
#include <stdbool.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

JSStringRef JSStringCreateWithCharacters(const JSChar *chars, size_t numChars);
JSStringRef JSStringCreateWithUTF8CString(const char *string);
JSStringRef JSStringRetain(JSStringRef string);
void JSStringRelease(JSStringRef string);
size_t JSStringGetLength(JSStringRef string);
const JSChar *JSStringGetCharactersPtr(JSStringRef string);
size_t JSStringGetMaximumUTF8CStringSize(JSStringRef string);
size_t JSStringGetUTF8CString(JSStringRef string, char *buffer, size_t bufferSize);
bool JSStringIsEqual(JSStringRef a, JSStringRef b);
bool JSStringIsEqualToUTF8CString(JSStringRef a, const char *b);

#ifdef __cplusplus
}
#endif

#endif
