/* t1_objc.m — the slice, exercised from Objective-C.
 *
 * Deliberately written to compile BOTH against our slice (on Linux, as Mach-O)
 * and against Apple's real Foundation + CoreFoundation on macOS, so this is a
 * genuine differential test and not a self-consistency check. Every line is
 * `key=value` so the two runs diff byte-for-byte.
 *
 * The CF type IDs are part of the differential on purpose: kCFStringTypeID and
 * friends are values our slice claims to match (src/slice/NSSlice.m takes them
 * from swift-corelibs-foundation's CFRuntime_Internal.h), so if Apple numbers
 * them differently the diff must say so rather than us quietly not looking.
 */
#if __has_include(<FoundationSlice/FoundationSlice.h>)
#  include <FoundationSlice/FoundationSlice.h>
#else
#  include <Foundation/Foundation.h>
#  include <CoreFoundation/CoreFoundation.h>
#endif
#include <stdio.h>

int main(void) {
  NSString *s = [NSString stringWithUTF8String:"hi"];
  printf("str.length=%lu\n", (unsigned long)[s length]);
  printf("str.utf8=%s\n", [s UTF8String]);
  printf("str.char0=%d\n", (int)[s characterAtIndex:0]);

  NSString *t = [NSString stringWithUTF8String:"hi"];
  printf("str.isEqual=%d\n", (int)[s isEqualToString:t]);
  printf("str.hash_eq=%d\n", (int)([s hash] == [t hash]));

  id objs[3];
  objs[0] = [NSNumber numberWithInt:1];
  objs[1] = [NSNumber numberWithInt:2];
  objs[2] = [NSNumber numberWithInt:3];
  NSArray *a = [NSArray arrayWithObjects:objs count:3];
  printf("arr.count=%lu\n", (unsigned long)[a count]);
  printf("arr.0=%d\n", [[a objectAtIndex:0] intValue]);
  printf("arr.2=%d\n", [[a objectAtIndex:2] intValue]);

  NSMutableArray *m = [NSMutableArray array];
  [m addObject:s];
  [m addObject:t];
  printf("marr.count=%lu\n", (unsigned long)[m count]);

  /* The bridging contract itself: CFGetTypeID must dispatch -_cfTypeID to the
     ObjC object. That is the CFTYPE_OBJC_FUNCDISPATCH0 path corelibs stubs to
     a no-op, and the reason _swift_stdlib_isNSString works at all. */
  printf("cf.stringTypeID=%lu\n", (unsigned long)CFStringGetTypeID());
  printf("cf.getTypeID_str=%lu\n", (unsigned long)CFGetTypeID((CFTypeRef)s));
  printf("cf.isNSString_str=%d\n",
         (int)(CFGetTypeID((CFTypeRef)s) == CFStringGetTypeID()));
  printf("cf.isNSString_arr=%d\n",
         (int)(CFGetTypeID((CFTypeRef)a) == CFStringGetTypeID()));
  return 0;
}
