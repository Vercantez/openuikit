#ifndef JAVASCRIPTCORE_JSOBJECTREF_H
#define JAVASCRIPTCORE_JSOBJECTREF_H

#include "JSBase.h"
#include "JSValueRef.h"
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*JSObjectInitializeCallback)(JSContextRef ctx, JSObjectRef object);
typedef void (*JSObjectFinalizeCallback)(JSObjectRef object);
typedef bool (*JSObjectHasPropertyCallback)(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName);
typedef JSValueRef (*JSObjectGetPropertyCallback)(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName, JSValueRef *exception);
typedef bool (*JSObjectSetPropertyCallback)(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName, JSValueRef value, JSValueRef *exception);
typedef bool (*JSObjectDeletePropertyCallback)(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName, JSValueRef *exception);
typedef void (*JSObjectGetPropertyNamesCallback)(JSContextRef ctx, JSObjectRef object, JSPropertyNameAccumulatorRef propertyNames);
typedef JSValueRef (*JSObjectCallAsFunctionCallback)(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef *exception);
typedef JSObjectRef (*JSObjectCallAsConstructorCallback)(JSContextRef ctx, JSObjectRef constructor, size_t argumentCount, const JSValueRef arguments[], JSValueRef *exception);
typedef bool (*JSObjectHasInstanceCallback)(JSContextRef ctx, JSObjectRef constructor, JSValueRef possibleInstance, JSValueRef *exception);
typedef JSValueRef (*JSObjectConvertToTypeCallback)(JSContextRef ctx, JSObjectRef object, JSType type, JSValueRef *exception);

typedef struct {
    const char *name;
    JSObjectGetPropertyCallback getProperty;
    JSObjectSetPropertyCallback setProperty;
    JSPropertyAttributes attributes;
} JSStaticValue;

typedef struct {
    const char *name;
    JSObjectCallAsFunctionCallback callAsFunction;
    JSPropertyAttributes attributes;
} JSStaticFunction;

typedef struct {
    int version;
    JSClassAttributes attributes;
    const char *className;
    JSClassRef parentClass;
    const JSStaticValue *staticValues;
    const JSStaticFunction *staticFunctions;
    JSObjectInitializeCallback initialize;
    JSObjectFinalizeCallback finalize;
    JSObjectHasPropertyCallback hasProperty;
    JSObjectGetPropertyCallback getProperty;
    JSObjectSetPropertyCallback setProperty;
    JSObjectDeletePropertyCallback deleteProperty;
    JSObjectGetPropertyNamesCallback getPropertyNames;
    JSObjectCallAsFunctionCallback callAsFunction;
    JSObjectCallAsConstructorCallback callAsConstructor;
    JSObjectHasInstanceCallback hasInstance;
    JSObjectConvertToTypeCallback convertToType;
} JSClassDefinition;

extern const JSClassDefinition kJSClassDefinitionEmpty;

JSClassRef JSClassCreate(const JSClassDefinition *definition);
JSClassRef JSClassRetain(JSClassRef jsClass);
void JSClassRelease(JSClassRef jsClass);

JSObjectRef JSObjectMake(JSContextRef ctx, JSClassRef jsClass, void *data);
JSObjectRef JSObjectMakeFunctionWithCallback(JSContextRef ctx, JSStringRef name, JSObjectCallAsFunctionCallback callAsFunction);
JSObjectRef JSObjectMakeConstructor(JSContextRef ctx, JSClassRef jsClass, JSObjectCallAsConstructorCallback callAsConstructor);
JSObjectRef JSObjectMakeArray(JSContextRef ctx, size_t argumentCount, const JSValueRef arguments[], JSValueRef *exception);
JSObjectRef JSObjectMakeDate(JSContextRef ctx, size_t argumentCount, const JSValueRef arguments[], JSValueRef *exception);
JSObjectRef JSObjectMakeError(JSContextRef ctx, size_t argumentCount, const JSValueRef arguments[], JSValueRef *exception);
JSObjectRef JSObjectMakeRegExp(JSContextRef ctx, size_t argumentCount, const JSValueRef arguments[], JSValueRef *exception);
JSObjectRef JSObjectMakeDeferredPromise(JSContextRef ctx, JSObjectRef *resolve, JSObjectRef *reject, JSValueRef *exception);
JSObjectRef JSObjectMakeFunction(JSContextRef ctx, JSStringRef name, unsigned parameterCount, const JSStringRef parameterNames[], JSStringRef body, JSStringRef sourceURL, int startingLineNumber, JSValueRef *exception);

JSValueRef JSObjectGetPrototype(JSContextRef ctx, JSObjectRef object);
void JSObjectSetPrototype(JSContextRef ctx, JSObjectRef object, JSValueRef value);
bool JSObjectHasProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName);
JSValueRef JSObjectGetProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName, JSValueRef *exception);
void JSObjectSetProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName, JSValueRef value, JSPropertyAttributes attributes, JSValueRef *exception);
bool JSObjectDeleteProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName, JSValueRef *exception);
bool JSObjectHasPropertyForKey(JSContextRef ctx, JSObjectRef object, JSValueRef propertyKey, JSValueRef *exception);
JSValueRef JSObjectGetPropertyForKey(JSContextRef ctx, JSObjectRef object, JSValueRef propertyKey, JSValueRef *exception);
void JSObjectSetPropertyForKey(JSContextRef ctx, JSObjectRef object, JSValueRef propertyKey, JSValueRef value, JSPropertyAttributes attributes, JSValueRef *exception);
bool JSObjectDeletePropertyForKey(JSContextRef ctx, JSObjectRef object, JSValueRef propertyKey, JSValueRef *exception);
JSValueRef JSObjectGetPropertyAtIndex(JSContextRef ctx, JSObjectRef object, unsigned propertyIndex, JSValueRef *exception);
void JSObjectSetPropertyAtIndex(JSContextRef ctx, JSObjectRef object, unsigned propertyIndex, JSValueRef value, JSValueRef *exception);

void *JSObjectGetPrivate(JSObjectRef object);
bool JSObjectSetPrivate(JSObjectRef object, void *data);
bool JSObjectIsFunction(JSContextRef ctx, JSObjectRef object);
bool JSObjectIsConstructor(JSContextRef ctx, JSObjectRef object);
JSValueRef JSObjectCallAsFunction(JSContextRef ctx, JSObjectRef object, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef *exception);
JSObjectRef JSObjectCallAsConstructor(JSContextRef ctx, JSObjectRef object, size_t argumentCount, const JSValueRef arguments[], JSValueRef *exception);

JSPropertyNameArrayRef JSObjectCopyPropertyNames(JSContextRef ctx, JSObjectRef object);
JSPropertyNameArrayRef JSPropertyNameArrayRetain(JSPropertyNameArrayRef array);
void JSPropertyNameArrayRelease(JSPropertyNameArrayRef array);
size_t JSPropertyNameArrayGetCount(JSPropertyNameArrayRef array);
JSStringRef JSPropertyNameArrayGetNameAtIndex(JSPropertyNameArrayRef array, size_t index);
void JSPropertyNameAccumulatorAddName(JSPropertyNameAccumulatorRef accumulator, JSStringRef propertyName);

#ifdef __cplusplus
}
#endif

#endif
