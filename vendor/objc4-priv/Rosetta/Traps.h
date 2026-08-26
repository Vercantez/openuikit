/*
 * vendor/objc4-priv/Rosetta/Traps.h
 *
 * objc_thread_get_rip() is Rosetta's "where is this translated thread
 * executing". Reached only from inside the
 * `rosetta_is_current_process_translated()` branch in objc-cache.mm, which is
 * dead here (see Rosetta.h). Declared weak for the same reason.
 */
#ifndef _OBJC4_PRIV_ROSETTA_TRAPS_H
#define _OBJC4_PRIV_ROSETTA_TRAPS_H

#include <stdint.h>
#include <mach/mach.h>

__BEGIN_DECLS
extern kern_return_t objc_thread_get_rip(thread_act_t thread, uint64_t *rip)
        __attribute__((weak_import));
__END_DECLS

#endif
