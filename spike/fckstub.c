/* fckstub.c -- the 8 Foundation/CoreFoundation symbols that the iOS-simulator
 * libswiftCore.dylib imports at load time, provided as loud-abort stubs.
 *
 * The sim libswiftCore lists Foundation and CoreFoundation as ordinary
 * LC_LOAD_DYLIBs (not delay-init as in the macOS shared-cache copy), so
 * machorun must satisfy every symbol it imports from them at bind time.
 * Measured with `dyld_info -imports`, that set is exactly these eight, and
 * all eight sit on error-bridging / String-bridging paths that a bitmap
 * drawing program never reaches. So a stub that exists (gives the binder a
 * real address) and aborts if ever actually entered is correct: it unblocks
 * load without silently faking behaviour we depend on.
 *
 * asm() labels pin the exact exported Mach-O symbol names, underscores and
 * Swift mangling included, without needing '$' in C identifiers.
 */
#include <stdio.h>
#include <stdlib.h>

static void die(const char *sym)
{
    fprintf(stderr, "fckstub: %s was actually called -- "
                    "a real Foundation/CoreFoundation is needed here\n", sym);
    abort();
}

/* CoreFoundation (4) */
void cf1(void) asm("_CFStringHashCString");
void cf2(void) asm("_CFStringHashNSString");
void cf3(void) asm("__CFStringCreateTaggedPointerString");
void cf4(void) asm("__NSIsNSString");
void cf1(void) { die("CFStringHashCString"); }
void cf2(void) { die("CFStringHashNSString"); }
void cf3(void) { die("_CFStringCreateTaggedPointerString"); }
void cf4(void) { die("_NSIsNSString"); }

/* Foundation (4). Two of these (…Mp, …Mc) are really metadata/descriptor
 * DATA symbols; exported as functions they still resolve to a valid mapped
 * address, which is all load-time binding requires as long as nothing on the
 * drawing path dereferences them as data. */
void fn1(void) asm("_$s10Foundation21_bridgeNSErrorToError_3outSbSo0C0C_SpyxGtAA021_ObjectiveCBridgeableE0RzlF");
void fn2(void) asm("_$s10Foundation24_getErrorDefaultUserInfoyyXlSgxs0C0RzlF");
void fn3(void) asm("_$s10Foundation26_ObjectiveCBridgeableErrorMp");
void fn4(void) asm("_$sSo10CFErrorRefas5Error10FoundationMc");
void fn1(void) { die("_bridgeNSErrorToError"); }
void fn2(void) { die("_getErrorDefaultUserInfo"); }
void fn3(void) { die("_ObjectiveCBridgeableError descriptor"); }
void fn4(void) { die("CFError:Error conformance"); }
