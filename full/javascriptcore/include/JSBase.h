#ifndef JAVASCRIPTCORE_JSBASE_H
#define JAVASCRIPTCORE_JSBASE_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define JSC_OBJC_API_ENABLED 0

typedef struct OpaqueJSContextGroup *JSContextGroupRef;
typedef struct OpaqueJSContext *JSContextRef;
typedef struct OpaqueJSContext *JSGlobalContextRef;
typedef struct OpaqueJSString *JSStringRef;
typedef struct OpaqueJSClass *JSClassRef;
typedef struct OpaqueJSPropertyNameArray *JSPropertyNameArrayRef;
typedef struct OpaqueJSPropertyNameAccumulator *JSPropertyNameAccumulatorRef;
typedef const struct OpaqueJSValue *JSValueRef;
typedef struct OpaqueJSValue *JSObjectRef;

typedef unsigned JSPropertyAttributes;
typedef unsigned JSClassAttributes;
typedef unsigned short JSChar;

enum {
    kJSPropertyAttributeNone = 0,
    kJSPropertyAttributeReadOnly = 1 << 1,
    kJSPropertyAttributeDontEnum = 1 << 2,
    kJSPropertyAttributeDontDelete = 1 << 3
};

enum {
    kJSClassAttributeNone = 0,
    kJSClassAttributeNoAutomaticPrototype = 1 << 1
};

#ifdef __cplusplus
}
#endif

#endif
