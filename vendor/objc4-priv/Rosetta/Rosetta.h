/*
 * vendor/objc4-priv/Rosetta/Rosetta.h
 *
 * OBJC_USE_ROSETTA is 1 for TARGET_OS_OSX, so objc-cache.mm includes this and
 * calls rosetta_is_current_process_translated(). Apple guards the call with
 * `if (&rosetta_is_current_process_translated && ...)` -- an address test on a
 * WEAK symbol, which is exactly how a machine without Rosetta behaves. We
 * declare it weak and never define it, so the address is null and the branch
 * is not taken. That is Apple's own "no Rosetta here" path, not a stub of
 * ours, and it needs no change to objc4.
 */
#ifndef _OBJC4_PRIV_ROSETTA_H
#define _OBJC4_PRIV_ROSETTA_H

#include <stdbool.h>

__BEGIN_DECLS
extern bool rosetta_is_current_process_translated(void) __attribute__((weak_import));
__END_DECLS

#endif
