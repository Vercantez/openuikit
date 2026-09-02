/*
 * _modules/_sys_types.h -- machorun's clean-room replacement.
 *
 * NOT Apple's header, and there is almost nothing here to be Apple's: this is
 * a MODULE SHIM, not an interface. Its entire job is to give the Clang module
 * `sys_types` exactly one header to own, so that `sys/types.h` can stay a
 * plain header included by many modules while `sys_types` remains a module in
 * its own right.
 *
 * WHY IT IS NEEDED HERE. Swift's `Darwin.swiftinterface` opens with
 *
 *     @_exported import sys_types
 *
 * and `sys_types` has no `.swiftmodule` anywhere in the sysroot -- it is a
 * *Clang* module, and the only thing that can declare it is a modulemap
 * pointing at this file. Without it, `import Darwin` fails at that line with
 * "no such module 'sys_types'" no matter how complete the rest of the SDK is.
 *
 * It was very nearly missed. A survey of Apple's Darwin modulemaps put the
 * whole `_modules/*.h` group aside as "these belong to OTHER top-level
 * modules, not to the chain" -- true of five of the six, and false of this one,
 * because `Darwin` imports `sys_types` directly. The list of modules a chain
 * needs comes from the INTERFACES' import lines, not from a modulemap's
 * structure.
 *
 * THE #error IS FUNCTIONAL, NOT DECORATIVE. `__building_module(sys_types)` is
 * true only while Clang is compiling this module, so including this file by
 * hand is a diagnostic rather than a second, unmodularised copy of
 * <sys/types.h>. Apple's header does the same thing for the same reason, and
 * the mechanism is the only way to write this file correctly.
 */

#ifndef __SYS_TYPES_H_
#define __SYS_TYPES_H_

#if !__building_module(sys_types)
#error "Do not include this header directly, include <sys/types.h> instead"
#endif

#include <sys/types.h>

#endif /* __SYS_TYPES_H_ */
