#ifndef JAVASCRIPTCORE_JSVALUEREF_H
#define JAVASCRIPTCORE_JSVALUEREF_H

#include "JSBase.h"
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
    kJSTypeUndefined,
    kJSTypeNull,
    kJSTypeBoolean,
    kJSTypeNumber,
    kJSTypeString,
    kJSTypeObject,
    kJSTypeSymbol,
    kJSTypeBigInt
} JSType;

typedef enum {
    kJSTypedArrayTypeNone,
    kJSTypedArrayTypeInt8Array,
    kJSTypedArrayTypeInt16Array,
    kJSTypedArrayTypeInt32Array,
    kJSTypedArrayTypeUint8Array,
    kJSTypedArrayTypeUint8ClampedArray,
    kJSTypedArrayTypeUint16Array,
    kJSTypedArrayTypeUint32Array,
    kJSTypedArrayTypeFloat32Array,
    kJSTypedArrayTypeFloat64Array,
    kJSTypedArrayTypeArrayBuffer,
    kJSTypedArrayTypeBigInt64Array,
    kJSTypedArrayTypeBigUint64Array
} JSTypedArrayType;

typedef enum {
    kJSRelationConditionUndefined = 0,
    kJSRelationConditionEqual = 1,
    kJSRelationConditionGreaterThan = 2,
    kJSRelationConditionLessThan = 3
} JSRelationCondition;

JSType JSValueGetType(JSContextRef ctx, JSValueRef value);
bool JSValueIsUndefined(JSContextRef ctx, JSValueRef value);
bool JSValueIsNull(JSContextRef ctx, JSValueRef value);
bool JSValueIsBoolean(JSContextRef ctx, JSValueRef value);
bool JSValueIsNumber(JSContextRef ctx, JSValueRef value);
bool JSValueIsString(JSContextRef ctx, JSValueRef value);
bool JSValueIsObject(JSContextRef ctx, JSValueRef value);
bool JSValueIsSymbol(JSContextRef ctx, JSValueRef value);
bool JSValueIsBigInt(JSContextRef ctx, JSValueRef value);
bool JSValueIsArray(JSContextRef ctx, JSValueRef value);
bool JSValueIsDate(JSContextRef ctx, JSValueRef value);
bool JSValueIsObjectOfClass(JSContextRef ctx, JSValueRef value, JSClassRef jsClass);
bool JSValueIsEqual(JSContextRef ctx, JSValueRef a, JSValueRef b, JSValueRef *exception);
bool JSValueIsStrictEqual(JSContextRef ctx, JSValueRef a, JSValueRef b);
bool JSValueIsInstanceOfConstructor(JSContextRef ctx, JSValueRef value, JSObjectRef constructor, JSValueRef *exception);

JSValueRef JSValueMakeUndefined(JSContextRef ctx);
JSValueRef JSValueMakeNull(JSContextRef ctx);
JSValueRef JSValueMakeBoolean(JSContextRef ctx, bool boolean);
JSValueRef JSValueMakeNumber(JSContextRef ctx, double number);
JSValueRef JSValueMakeString(JSContextRef ctx, JSStringRef string);
JSValueRef JSValueMakeSymbol(JSContextRef ctx, JSStringRef description);
JSValueRef JSValueMakeFromJSONString(JSContextRef ctx, JSStringRef string);
JSStringRef JSValueCreateJSONString(JSContextRef ctx, JSValueRef value, unsigned indent, JSValueRef *exception);

bool JSValueToBoolean(JSContextRef ctx, JSValueRef value);
double JSValueToNumber(JSContextRef ctx, JSValueRef value, JSValueRef *exception);
JSStringRef JSValueToStringCopy(JSContextRef ctx, JSValueRef value, JSValueRef *exception);
JSObjectRef JSValueToObject(JSContextRef ctx, JSValueRef value, JSValueRef *exception);
int32_t JSValueToInt32(JSContextRef ctx, JSValueRef value, JSValueRef *exception);
uint32_t JSValueToUInt32(JSContextRef ctx, JSValueRef value, JSValueRef *exception);
int64_t JSValueToInt64(JSContextRef ctx, JSValueRef value, JSValueRef *exception);
uint64_t JSValueToUInt64(JSContextRef ctx, JSValueRef value, JSValueRef *exception);

JSRelationCondition JSValueCompare(JSContextRef ctx, JSValueRef left, JSValueRef right, JSValueRef *exception);
JSRelationCondition JSValueCompareDouble(JSContextRef ctx, JSValueRef left, double right, JSValueRef *exception);
JSRelationCondition JSValueCompareInt64(JSContextRef ctx, JSValueRef left, int64_t right, JSValueRef *exception);
JSRelationCondition JSValueCompareUInt64(JSContextRef ctx, JSValueRef left, uint64_t right, JSValueRef *exception);

void JSValueProtect(JSContextRef ctx, JSValueRef value);
void JSValueUnprotect(JSContextRef ctx, JSValueRef value);

JSValueRef JSBigIntCreateWithDouble(JSContextRef ctx, double value, JSValueRef *exception);
JSValueRef JSBigIntCreateWithInt64(JSContextRef ctx, int64_t integer, JSValueRef *exception);
JSValueRef JSBigIntCreateWithUInt64(JSContextRef ctx, uint64_t integer, JSValueRef *exception);
JSValueRef JSBigIntCreateWithString(JSContextRef ctx, JSStringRef string, JSValueRef *exception);

#ifdef __cplusplus
}
#endif

#endif
