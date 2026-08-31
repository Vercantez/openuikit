/*
 * Portable implementation contract for Darwin's removefile(3) family.
 *
 * The target SDK's <removefile.h> declares this same ABI to Swift.  Keeping
 * the implementation header independent of an Apple SDK also lets the exact
 * state machine and filesystem semantics run as a native Linux test.
 */
#ifndef OPEN_FOUNDATION_REMOVEFILE_COMPAT_H
#define OPEN_FOUNDATION_REMOVEFILE_COMPAT_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef uint32_t removefile_flags_t;
typedef struct _removefile_state *removefile_state_t;
typedef int (*removefile_callback_t)(removefile_state_t state,
                                     const char *path,
                                     void *context);

enum {
    REMOVEFILE_RECURSIVE = (1u << 0),
    REMOVEFILE_KEEP_PARENT = (1u << 1),
    REMOVEFILE_SECURE_7_PASS = (1u << 2),
    REMOVEFILE_SECURE_35_PASS = (1u << 3),
    REMOVEFILE_SECURE_1_PASS = (1u << 4),
    REMOVEFILE_SECURE_3_PASS = (1u << 5),
    REMOVEFILE_SECURE_1_PASS_ZERO = (1u << 6),
    REMOVEFILE_CROSS_MOUNT = (1u << 7),
    REMOVEFILE_ALLOW_LONG_PATHS = (1u << 8),
    REMOVEFILE_CLEAR_PURGEABLE = (1u << 9),
    REMOVEFILE_SYSTEM_DISCARDED = (1u << 10),
    REMOVEFILE_RECURSIVE_SLIM = (1u << 11),
};

enum {
    REMOVEFILE_STATE_CONFIRM_CALLBACK = 1,
    REMOVEFILE_STATE_CONFIRM_CONTEXT = 2,
    REMOVEFILE_STATE_ERROR_CALLBACK = 3,
    REMOVEFILE_STATE_ERROR_CONTEXT = 4,
    REMOVEFILE_STATE_ERRNO = 5,
    REMOVEFILE_STATE_STATUS_CALLBACK = 6,
    REMOVEFILE_STATE_STATUS_CONTEXT = 7,
    REMOVEFILE_STATE_FTSENT = 8,
};

enum {
    REMOVEFILE_PROCEED = 0,
    REMOVEFILE_SKIP = 1,
    REMOVEFILE_STOP = 2,
};

removefile_state_t removefile_state_alloc(void);
int removefile_state_free(removefile_state_t state);
int removefile_state_get(removefile_state_t state, uint32_t key, void *dst);
int removefile_state_set(removefile_state_t state, uint32_t key,
                         const void *value);
int removefile(const char *path, removefile_state_t state,
               removefile_flags_t flags);
int removefileat(int fd, const char *path, removefile_state_t state,
                 removefile_flags_t flags);
int removefile_cancel(removefile_state_t state);

#ifdef __cplusplus
}
#endif

#endif
