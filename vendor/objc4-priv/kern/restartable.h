/*
 * compat/kern/restartable.h  --  objc4-linux
 *
 * task_restartable_ranges is Darwin's mechanism for "if a thread is preempted
 * inside this PC range, restart it" -- objc4 uses it so cache_t can be
 * rewritten without the messenger observing a torn state.
 *
 * Linux's semantic analogue is rseq(2), which is NOT drop-in (it aborts rather
 * than restarts, and needs a compiler-emitted critical section descriptor).
 * HAVE_TASK_RESTARTABLE_RANGES is 0 in this port; the consequence is that
 * cache garbage is never freed. That is a LEAK, documented as such in
 * docs/UNIMPLEMENTED.md -- not a feature.
 */
#ifndef _OBJC4LINUX_KERN_RESTARTABLE_H
#define _OBJC4LINUX_KERN_RESTARTABLE_H
#include <mach/mach.h>
#ifdef __cplusplus
extern "C" {
#endif
typedef struct { uint64_t location; unsigned short length, recovery_offs, flags; } task_restartable_range_t;
typedef task_restartable_range_t *task_restartable_range_array_t;
kern_return_t task_restartable_ranges_register(task_t task,
        task_restartable_range_array_t ranges, mach_msg_type_number_t count);
kern_return_t task_restartable_ranges_synchronize(task_t task);
#ifdef __cplusplus
}
#endif
#endif
