#ifndef JAVASCRIPTCORE_JSCONTEXTREF_H
#define JAVASCRIPTCORE_JSCONTEXTREF_H

#include "JSBase.h"
#include "JSObjectRef.h"
#include "JSValueRef.h"
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

JSContextGroupRef JSContextGroupCreate(void);
JSContextGroupRef JSContextGroupRetain(JSContextGroupRef group);
void JSContextGroupRelease(JSContextGroupRef group);

JSGlobalContextRef JSGlobalContextCreate(JSClassRef globalObjectClass);
JSGlobalContextRef JSGlobalContextCreateInGroup(JSContextGroupRef group, JSClassRef globalObjectClass);
JSGlobalContextRef JSGlobalContextRetain(JSGlobalContextRef ctx);
void JSGlobalContextRelease(JSGlobalContextRef ctx);

JSObjectRef JSContextGetGlobalObject(JSContextRef ctx);
JSContextGroupRef JSContextGetGroup(JSContextRef ctx);
JSGlobalContextRef JSContextGetGlobalContext(JSContextRef ctx);

JSStringRef JSGlobalContextCopyName(JSGlobalContextRef ctx);
void JSGlobalContextSetName(JSGlobalContextRef ctx, JSStringRef name);
bool JSGlobalContextIsInspectable(JSGlobalContextRef ctx);
void JSGlobalContextSetInspectable(JSGlobalContextRef ctx, bool inspectable);

JSValueRef JSEvaluateScript(JSContextRef ctx, JSStringRef script, JSObjectRef thisObject, JSStringRef sourceURL, int startingLineNumber, JSValueRef *exception);
bool JSCheckScriptSyntax(JSContextRef ctx, JSStringRef script, JSStringRef sourceURL, int startingLineNumber, JSValueRef *exception);
void JSGarbageCollect(JSContextRef ctx);

#ifdef __cplusplus
}
#endif

#endif
