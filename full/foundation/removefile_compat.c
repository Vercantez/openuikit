/*
 * Darwin removefile(3) compatibility for FoundationEssentials.
 *
 * This is deliberately a real filesystem implementation rather than a
 * success stub.  It walks physical directory entries depth-first, never
 * follows a symbolic link, implements the state/callback protocol used by
 * FileManager delegates, and refuses secure-erasure flags that cannot be
 * truthfully provided by this platform.
 */
#define _DEFAULT_SOURCE 1

#include "removefile_compat.h"

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

struct _removefile_state {
    removefile_callback_t confirm_callback;
    void *confirm_context;
    removefile_callback_t error_callback;
    void *error_context;
    removefile_callback_t status_callback;
    void *status_context;
    void *current_fts_entry;
    int error_number;
    unsigned int cancelled;
};

enum mr_remove_result {
    MR_REMOVE_FAILED = -1,
    MR_REMOVE_OK = 0,
    MR_REMOVE_SKIPPED = 1,
};

static int mr_fail(int error_number)
{
    errno = error_number;
    return -1;
}

static int mr_is_cancelled(removefile_state_t state)
{
    return __atomic_load_n(&state->cancelled, __ATOMIC_ACQUIRE) != 0;
}

static void mr_store_callback(removefile_callback_t *destination,
                              const void *value)
{
    _Static_assert(sizeof(*destination) == sizeof(value),
                   "callback and object pointers must share the Darwin ABI");
    memcpy(destination, &value, sizeof(*destination));
}

static void mr_load_callback(void *destination,
                             const removefile_callback_t *callback)
{
    memcpy(destination, callback, sizeof(*callback));
}

removefile_state_t removefile_state_alloc(void)
{
    return (removefile_state_t)calloc(1, sizeof(struct _removefile_state));
}

int removefile_state_free(removefile_state_t state)
{
    if (state == NULL) {
        return mr_fail(EINVAL);
    }
    free(state);
    return 0;
}

int removefile_state_get(removefile_state_t state, uint32_t key, void *dst)
{
    if (state == NULL || dst == NULL) {
        return mr_fail(EINVAL);
    }

    switch (key) {
    case REMOVEFILE_STATE_CONFIRM_CALLBACK:
        mr_load_callback(dst, &state->confirm_callback);
        break;
    case REMOVEFILE_STATE_CONFIRM_CONTEXT:
        *(void **)dst = state->confirm_context;
        break;
    case REMOVEFILE_STATE_ERROR_CALLBACK:
        mr_load_callback(dst, &state->error_callback);
        break;
    case REMOVEFILE_STATE_ERROR_CONTEXT:
        *(void **)dst = state->error_context;
        break;
    case REMOVEFILE_STATE_ERRNO:
        *(int *)dst = state->error_number;
        break;
    case REMOVEFILE_STATE_STATUS_CALLBACK:
        mr_load_callback(dst, &state->status_callback);
        break;
    case REMOVEFILE_STATE_STATUS_CONTEXT:
        *(void **)dst = state->status_context;
        break;
    case REMOVEFILE_STATE_FTSENT:
        *(void **)dst = state->current_fts_entry;
        break;
    default:
        return mr_fail(EINVAL);
    }
    return 0;
}

int removefile_state_set(removefile_state_t state, uint32_t key,
                         const void *value)
{
    if (state == NULL) {
        return mr_fail(EINVAL);
    }

    switch (key) {
    case REMOVEFILE_STATE_CONFIRM_CALLBACK:
        mr_store_callback(&state->confirm_callback, value);
        break;
    case REMOVEFILE_STATE_CONFIRM_CONTEXT:
        state->confirm_context = (void *)value;
        break;
    case REMOVEFILE_STATE_ERROR_CALLBACK:
        mr_store_callback(&state->error_callback, value);
        break;
    case REMOVEFILE_STATE_ERROR_CONTEXT:
        state->error_context = (void *)value;
        break;
    case REMOVEFILE_STATE_STATUS_CALLBACK:
        mr_store_callback(&state->status_callback, value);
        break;
    case REMOVEFILE_STATE_STATUS_CONTEXT:
        state->status_context = (void *)value;
        break;
    case REMOVEFILE_STATE_ERRNO:
    case REMOVEFILE_STATE_FTSENT:
    default:
        return mr_fail(EINVAL);
    }
    return 0;
}

int removefile_cancel(removefile_state_t state)
{
    if (state == NULL) {
        return mr_fail(EINVAL);
    }
    __atomic_store_n(&state->cancelled, 1, __ATOMIC_RELEASE);
    return 0;
}

static int mr_stop(removefile_state_t state, int error_number)
{
    state->error_number = error_number;
    errno = error_number;
    return MR_REMOVE_FAILED;
}

static int mr_check_cancelled(removefile_state_t state)
{
    if (mr_is_cancelled(state)) {
        return mr_stop(state, ECANCELED);
    }
    return MR_REMOVE_OK;
}

static int mr_callback_result(removefile_state_t state, int decision)
{
    if (decision == REMOVEFILE_PROCEED) {
        return MR_REMOVE_OK;
    }
    if (decision == REMOVEFILE_SKIP) {
        return MR_REMOVE_SKIPPED;
    }
    if (decision == REMOVEFILE_STOP) {
        return mr_stop(state, ECANCELED);
    }
    return mr_stop(state, EINVAL);
}

static int mr_confirm(removefile_state_t state, const char *path)
{
    int result;

    if (mr_check_cancelled(state) != MR_REMOVE_OK) {
        return MR_REMOVE_FAILED;
    }
    if (state->confirm_callback == NULL) {
        return MR_REMOVE_OK;
    }
    result = mr_callback_result(
        state,
        state->confirm_callback(state, path, state->confirm_context));
    if (result == MR_REMOVE_OK && mr_check_cancelled(state) != MR_REMOVE_OK) {
        return MR_REMOVE_FAILED;
    }
    return result;
}

/* Return OK when a delegate explicitly accepts and suppresses the error. */
static int mr_report_error(removefile_state_t state, const char *path,
                           int error_number)
{
    int decision;

    state->error_number = error_number;
    errno = error_number;
    if (state->error_callback == NULL) {
        return MR_REMOVE_FAILED;
    }
    decision = state->error_callback(state, path, state->error_context);
    if (decision == REMOVEFILE_PROCEED || decision == REMOVEFILE_SKIP) {
        errno = 0;
        return MR_REMOVE_OK;
    }
    if (decision == REMOVEFILE_STOP) {
        errno = error_number;
        return MR_REMOVE_FAILED;
    }
    return mr_stop(state, EINVAL);
}

static int mr_status(removefile_state_t state, const char *path)
{
    int result;

    if (state->status_callback == NULL) {
        return mr_check_cancelled(state);
    }
    result = mr_callback_result(
        state,
        state->status_callback(state, path, state->status_context));
    if (result == MR_REMOVE_SKIPPED) {
        result = MR_REMOVE_OK;
    }
    if (result == MR_REMOVE_OK && mr_check_cancelled(state) != MR_REMOVE_OK) {
        return MR_REMOVE_FAILED;
    }
    return result;
}

static char *mr_child_path(const char *parent, const char *name)
{
    size_t parent_length = strlen(parent);
    size_t name_length = strlen(name);
    int needs_separator = parent_length != 0 && parent[parent_length - 1] != '/';
    size_t total;
    char *result;

    if (parent_length > SIZE_MAX - name_length - (size_t)needs_separator - 1) {
        errno = ENAMETOOLONG;
        return NULL;
    }
    total = parent_length + (size_t)needs_separator + name_length + 1;
    result = (char *)malloc(total);
    if (result == NULL) {
        return NULL;
    }
    memcpy(result, parent, parent_length);
    if (needs_separator) {
        result[parent_length++] = '/';
    }
    memcpy(result + parent_length, name, name_length + 1);
    return result;
}

static int mr_same_directory(const struct stat *expected, DIR *directory)
{
    struct stat opened;
    int descriptor = dirfd(directory);

    if (descriptor < 0 || fstat(descriptor, &opened) != 0) {
        return 0;
    }
    return S_ISDIR(opened.st_mode) && opened.st_dev == expected->st_dev &&
           opened.st_ino == expected->st_ino;
}

static int mr_remove_path(const char *path, removefile_state_t state,
                          removefile_flags_t flags, int is_root,
                          dev_t root_device)
{
    struct stat attributes;
    int decision;

    decision = mr_confirm(state, path);
    if (decision != MR_REMOVE_OK) {
        return decision;
    }

    if (lstat(path, &attributes) != 0) {
        return mr_report_error(state, path, errno);
    }

    if (is_root) {
        root_device = attributes.st_dev;
    }

    /* Darwin CROSS_MOUNT is a directory mount-point policy. Overlayfs
     * reports a different st_dev for non-directories than for directories
     * on the same mount, so comparing every entry against the walk root
     * would skip ordinary files and leave ENOTEMPTY on rmdir. */
    if (!is_root && S_ISDIR(attributes.st_mode) &&
        attributes.st_dev != root_device &&
        (flags & REMOVEFILE_CROSS_MOUNT) == 0) {
        return MR_REMOVE_SKIPPED;
    }

    if (!S_ISDIR(attributes.st_mode)) {
        if (unlink(path) != 0) {
            return mr_report_error(state, path, errno);
        }
        return mr_status(state, path);
    }

    if ((flags & REMOVEFILE_RECURSIVE) != 0) {
        DIR *directory = opendir(path);
        struct dirent *entry;
        int read_error = 0;
        int child_failed = 0;

        if (directory == NULL) {
            return mr_report_error(state, path, errno);
        }
        if (!mr_same_directory(&attributes, directory)) {
            int saved_error = errno == 0 ? EAGAIN : errno;
            (void)closedir(directory);
            return mr_report_error(state, path, saved_error);
        }

        errno = 0;
        while ((entry = readdir(directory)) != NULL) {
            char *child;
            int child_result;

            if (strcmp(entry->d_name, ".") == 0 ||
                strcmp(entry->d_name, "..") == 0) {
                errno = 0;
                continue;
            }
            child = mr_child_path(path, entry->d_name);
            if (child == NULL) {
                read_error = errno == 0 ? ENOMEM : errno;
                break;
            }
            child_result = mr_remove_path(child, state, flags, 0, root_device);
            free(child);
            if (child_result == MR_REMOVE_FAILED) {
                read_error = errno == 0 ? state->error_number : errno;
                child_failed = 1;
                break;
            }
            errno = 0;
        }
        if (entry == NULL && read_error == 0 && errno != 0) {
            read_error = errno;
        }
        if (closedir(directory) != 0 && read_error == 0) {
            read_error = errno;
        }
        if (read_error != 0) {
            /* Callback failures were already reported by the child. */
            if (child_failed) {
                errno = read_error;
                return MR_REMOVE_FAILED;
            }
            return mr_report_error(state, path, read_error);
        }
    }

    if (!(is_root && (flags & REMOVEFILE_KEEP_PARENT) != 0)) {
        if (rmdir(path) != 0) {
            return mr_report_error(state, path, errno);
        }
    }
    return mr_status(state, path);
}

int removefile(const char *path, removefile_state_t state,
               removefile_flags_t flags)
{
    static const removefile_flags_t secure_or_unsupported =
        REMOVEFILE_SECURE_7_PASS | REMOVEFILE_SECURE_35_PASS |
        REMOVEFILE_SECURE_1_PASS | REMOVEFILE_SECURE_3_PASS |
        REMOVEFILE_SECURE_1_PASS_ZERO | REMOVEFILE_CLEAR_PURGEABLE |
        REMOVEFILE_SYSTEM_DISCARDED;
    static const removefile_flags_t supported =
        REMOVEFILE_RECURSIVE | REMOVEFILE_KEEP_PARENT |
        REMOVEFILE_CROSS_MOUNT | REMOVEFILE_ALLOW_LONG_PATHS |
        REMOVEFILE_RECURSIVE_SLIM;
    int result;
    int owns_state = 0;

    if (path == NULL || path[0] == '\0') {
        if (state != NULL) {
            state->error_number = EINVAL;
        }
        return mr_fail(EINVAL);
    }
    if ((flags & secure_or_unsupported) != 0 || (flags & ~supported) != 0) {
        if (state != NULL) {
            state->error_number = ENOTSUP;
        }
        return mr_fail(ENOTSUP);
    }
    if ((flags & REMOVEFILE_KEEP_PARENT) != 0 &&
        (flags & REMOVEFILE_RECURSIVE) == 0) {
        if (state != NULL) {
            state->error_number = EINVAL;
        }
        return mr_fail(EINVAL);
    }
    if (state == NULL) {
        state = removefile_state_alloc();
        if (state == NULL) {
            return -1;
        }
        owns_state = 1;
    }
    state->error_number = 0;
    state->current_fts_entry = NULL;
    if (mr_check_cancelled(state) != MR_REMOVE_OK) {
        result = MR_REMOVE_FAILED;
        goto done;
    }
    result = mr_remove_path(path, state, flags, 1, (dev_t)0);

done:
    if (owns_state) {
        int saved_error = errno;
        (void)removefile_state_free(state);
        errno = saved_error;
    }
    return result == MR_REMOVE_FAILED ? -1 : 0;
}

int removefileat(int fd, const char *path, removefile_state_t state,
                 removefile_flags_t flags)
{
    if (path == NULL) {
        return mr_fail(EINVAL);
    }
    /* Absolute paths do not consult fd.  openat is intentionally unavailable
     * at the current Mach-O/ELF ABI boundary, so refuse other relative bases
     * instead of silently resolving them against the process cwd. */
    if (path[0] == '/' || fd == AT_FDCWD) {
        return removefile(path, state, flags);
    }
    return mr_fail(ENOTSUP);
}
