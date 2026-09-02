/*
 * compat/mach/mach.h  --  objc4-linux
 *
 * Mach IPC does not exist on Linux. The only objc4 features that need it are
 *   - objc-cache.mm's _collecting_in_critical() thread scan (task_threads +
 *     thread_get_state), and
 *   - objc-block-trampolines.mm's vm_remap dual-mapping.
 * Both are disabled in this port (HAVE_TASK_RESTARTABLE_RANGES 0, and the
 * trampolines are unported). These declarations exist so guarded code parses;
 * every definition aborts through objc4linux_unimplemented().
 */
#ifndef _OBJC4LINUX_MACH_MACH_H
#define _OBJC4LINUX_MACH_MACH_H

#include <stdint.h>
#include <stddef.h>
#include <string.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef int             kern_return_t;
typedef unsigned int    mach_port_t;
typedef unsigned int    mach_port_name_t;
typedef uintptr_t       vm_address_t;
typedef uintptr_t       vm_size_t;
typedef uintptr_t       mach_vm_address_t;
typedef uintptr_t       mach_vm_size_t;
typedef int             vm_prot_t;
typedef int             vm_inherit_t;
typedef mach_port_t     vm_map_t;
typedef mach_port_t     task_t;
typedef mach_port_t     thread_t;
typedef mach_port_t     thread_act_t;
typedef thread_act_t   *thread_act_array_t;
typedef thread_act_t   *thread_act_port_array_t;
typedef unsigned int    mach_msg_type_number_t;
typedef int            *thread_state_t;
typedef int             thread_state_flavor_t;
typedef unsigned int    natural_t;
typedef int             integer_t;
typedef unsigned int    mach_msg_size_t;

/* <mach/boolean.h> */
typedef int boolean_t;
#ifndef TRUE
#   define TRUE  1
#endif
#ifndef FALSE
#   define FALSE 0
#endif

#define KERN_SUCCESS            0
#define KERN_FAILURE            5
#define KERN_NOT_SUPPORTED      46
#define MACH_PORT_NULL          ((mach_port_t)0)

#define VM_PROT_NONE            0x0
#define VM_PROT_READ            0x1
#define VM_PROT_WRITE           0x2
#define VM_PROT_EXECUTE         0x4
#define VM_PROT_ALL             (VM_PROT_READ|VM_PROT_WRITE|VM_PROT_EXECUTE)
#define VM_INHERIT_SHARE        0
#define VM_INHERIT_NONE         2
#define VM_FLAGS_FIXED          0x0000
#define VM_FLAGS_ANYWHERE       0x0001
#define VM_FLAGS_OVERWRITE      0x4000
#define VM_MAKE_TAG(t)          ((t) << 24)

mach_port_t   mach_task_self(void);
/* Darwin maps a pthread_t to its Mach thread port. No Linux analogue; the
 * nearest concept is the tid from gettid(2), which is not a port. Declared
 * only so guarded code parses; the definition aborts. */
mach_port_t   pthread_mach_thread_np(void *pthread);
const char   *mach_error_string(kern_return_t err);
kern_return_t mach_port_deallocate(mach_port_t task, mach_port_name_t name);
kern_return_t task_threads(task_t task, thread_act_array_t *act_list,
                           mach_msg_type_number_t *act_listCnt);
kern_return_t thread_get_state(thread_t thread, thread_state_flavor_t flavor,
                               thread_state_t old_state,
                               mach_msg_type_number_t *old_stateCnt);
kern_return_t vm_allocate(vm_map_t target, vm_address_t *address,
                          vm_size_t size, int flags);
kern_return_t vm_deallocate(vm_map_t target, vm_address_t address, vm_size_t size);
kern_return_t vm_remap(vm_map_t target, vm_address_t *address, vm_size_t size,
                       vm_address_t mask, int flags, vm_map_t src_task,
                       vm_address_t src_address, int copy,
                       vm_prot_t *cur_protection, vm_prot_t *max_protection,
                       vm_inherit_t inheritance);
kern_return_t vm_protect(vm_map_t target, vm_address_t address, vm_size_t size,
                         int set_maximum, vm_prot_t new_protection);

/* Thread state flavors objc-cache.mm names. */
#define ARM_THREAD_STATE64      6
#define x86_THREAD_STATE64      4

struct arm_thread_state64 {
    uint64_t x[29], fp, lr, sp, pc;
    uint32_t cpsr, __pad;
};
typedef struct arm_thread_state64 arm_thread_state64_t;
#define ARM_THREAD_STATE64_COUNT ((mach_msg_type_number_t)(sizeof(arm_thread_state64_t)/sizeof(uint32_t)))
#define arm_thread_state64_get_pc(ts) ((uintptr_t)((ts).pc))

struct x86_thread_state64 { uint64_t rax, rbx, rcx, rdx, rdi, rsi, rbp, rsp,
                                     r8, r9, r10, r11, r12, r13, r14, r15,
                                     rip, rflags, cs, fs, gs; };
typedef struct x86_thread_state64 x86_thread_state64_t;
#define x86_THREAD_STATE64_COUNT ((mach_msg_type_number_t)(sizeof(x86_thread_state64_t)/sizeof(uint32_t)))

#ifdef __cplusplus
}
#endif

#endif
