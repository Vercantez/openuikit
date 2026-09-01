#ifndef JAVASCRIPTCORE_JSTYPEDARRAY_H
#define JAVASCRIPTCORE_JSTYPEDARRAY_H

#include "JSBase.h"
#include "JSValueRef.h"
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*JSTypedArrayBytesDeallocator)(void *bytes, void *deallocatorContext);

JSObjectRef JSObjectMakeTypedArray(JSContextRef ctx, JSTypedArrayType arrayType, size_t length, JSValueRef *exception);
JSObjectRef JSObjectMakeTypedArrayWithBytesNoCopy(JSContextRef ctx, JSTypedArrayType arrayType, void *bytes, size_t byteLength, JSTypedArrayBytesDeallocator bytesDeallocator, void *deallocatorContext, JSValueRef *exception);
JSObjectRef JSObjectMakeTypedArrayWithArrayBuffer(JSContextRef ctx, JSTypedArrayType arrayType, JSObjectRef buffer, JSValueRef *exception);
JSObjectRef JSObjectMakeTypedArrayWithArrayBufferAndOffset(JSContextRef ctx, JSTypedArrayType arrayType, JSObjectRef buffer, size_t byteOffset, size_t length, JSValueRef *exception);

size_t JSObjectGetTypedArrayLength(JSContextRef ctx, JSObjectRef object, JSValueRef *exception);
size_t JSObjectGetTypedArrayByteLength(JSContextRef ctx, JSObjectRef object, JSValueRef *exception);
size_t JSObjectGetTypedArrayByteOffset(JSContextRef ctx, JSObjectRef object, JSValueRef *exception);
JSObjectRef JSObjectGetTypedArrayBuffer(JSContextRef ctx, JSObjectRef object, JSValueRef *exception);
void *JSObjectGetTypedArrayBytesPtr(JSContextRef ctx, JSObjectRef object, JSValueRef *exception);

JSObjectRef JSObjectMakeArrayBufferWithBytesNoCopy(JSContextRef ctx, void *bytes, size_t byteLength, JSTypedArrayBytesDeallocator bytesDeallocator, void *deallocatorContext, JSValueRef *exception);
size_t JSObjectGetArrayBufferByteLength(JSContextRef ctx, JSObjectRef object, JSValueRef *exception);
void *JSObjectGetArrayBufferBytesPtr(JSContextRef ctx, JSObjectRef object, JSValueRef *exception);
JSTypedArrayType JSValueGetTypedArrayType(JSContextRef ctx, JSValueRef value, JSValueRef *exception);

#ifdef __cplusplus
}
#endif

#endif
