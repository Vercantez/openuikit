#define _DEFAULT_SOURCE 1

#include "removefile_compat.h"

#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

static char *test_root;

#define CHECK(condition, message)                                             \
    do {                                                                      \
        if (!(condition)) {                                                   \
            fprintf(stderr, "removefile test failed: %s (errno=%d)\n",      \
                    (message), errno);                                        \
            return 1;                                                         \
        }                                                                     \
    } while (0)

static char *join_path(const char *parent, const char *child)
{
    size_t parent_length = strlen(parent);
    size_t child_length = strlen(child);
    char *result = malloc(parent_length + child_length + 2);

    if (result == NULL) {
        return NULL;
    }
    memcpy(result, parent, parent_length);
    result[parent_length] = '/';
    memcpy(result + parent_length + 1, child, child_length + 1);
    return result;
}

static int make_directory(const char *path)
{
    return mkdir(path, 0700);
}

static int make_file(const char *path)
{
    static const char payload[] = "removefile-semantics";
    int descriptor = open(path, O_WRONLY | O_CREAT | O_TRUNC, 0600);
    ssize_t count;

    if (descriptor < 0) {
        return -1;
    }
    count = write(descriptor, payload, sizeof(payload) - 1);
    if (close(descriptor) != 0) {
        return -1;
    }
    return count == (ssize_t)(sizeof(payload) - 1) ? 0 : -1;
}

static int exists(const char *path)
{
    struct stat attributes;
    return lstat(path, &attributes) == 0;
}

static const void *callback_bits(removefile_callback_t callback)
{
    const void *result;
    _Static_assert(sizeof(result) == sizeof(callback),
                   "callback pointer ABI mismatch");
    memcpy(&result, &callback, sizeof(result));
    return result;
}

static int count_status(removefile_state_t state, const char *path,
                        void *context)
{
    (void)state;
    (void)path;
    (*(int *)context)++;
    return REMOVEFILE_PROCEED;
}

static int skip_named_file(removefile_state_t state, const char *path,
                           void *context)
{
    (void)state;
    (void)context;
    return strstr(path, "/skip") != NULL ? REMOVEFILE_SKIP : REMOVEFILE_PROCEED;
}

struct error_context {
    int calls;
    int decision;
};

static int handle_error(removefile_state_t state, const char *path,
                        void *context)
{
    struct error_context *error = context;
    int state_error = 0;

    (void)path;
    if (removefile_state_get(state, REMOVEFILE_STATE_ERRNO, &state_error) != 0 ||
        state_error == 0) {
        return REMOVEFILE_STOP;
    }
    error->calls++;
    return error->decision;
}

struct cancel_context {
    int confirmations;
};

static int cancel_during_walk(removefile_state_t state, const char *path,
                              void *context)
{
    struct cancel_context *cancel = context;
    (void)path;
    cancel->confirmations++;
    if (cancel->confirmations == 2) {
        (void)removefile_cancel(state);
    }
    return REMOVEFILE_PROCEED;
}

static int test_state_surface(void)
{
    removefile_state_t state = removefile_state_alloc();
    removefile_callback_t callback = NULL;
    void *context = NULL;
    void *fts_entry = (void *)1;
    int sentinel = 42;
    int state_error = -1;

    CHECK(state != NULL, "state allocation");
    CHECK(removefile_state_set(state, REMOVEFILE_STATE_CONFIRM_CALLBACK,
                               callback_bits(skip_named_file)) == 0,
          "set callback");
    CHECK(removefile_state_set(state, REMOVEFILE_STATE_CONFIRM_CONTEXT,
                               &sentinel) == 0,
          "set context");
    CHECK(removefile_state_get(state, REMOVEFILE_STATE_CONFIRM_CALLBACK,
                               &callback) == 0 && callback == skip_named_file,
          "get callback");
    CHECK(removefile_state_get(state, REMOVEFILE_STATE_CONFIRM_CONTEXT,
                               &context) == 0 && context == &sentinel,
          "get context");
    CHECK(removefile_state_get(state, REMOVEFILE_STATE_ERRNO, &state_error) == 0 &&
              state_error == 0,
          "initial state errno");
    CHECK(removefile_state_get(state, REMOVEFILE_STATE_FTSENT, &fts_entry) == 0 &&
              fts_entry == NULL,
          "FTS entry state surface");
    errno = 0;
    CHECK(removefile_state_set(state, REMOVEFILE_STATE_ERRNO, &sentinel) == -1 &&
              errno == EINVAL,
          "errno is read-only");
    CHECK(removefile_state_free(state) == 0, "state free");
    errno = 0;
    CHECK(removefile_state_free(NULL) == -1 && errno == EINVAL,
          "null state free refusal");
    return 0;
}

static int test_recursive_and_symlink(void)
{
    char *external = join_path(test_root, "external");
    char *external_file = join_path(external, "preserved");
    char *root = join_path(test_root, "recursive");
    char *sub = join_path(root, "sub");
    char *file = join_path(sub, "file");
    char *link = join_path(sub, "link");
    removefile_state_t state = removefile_state_alloc();
    int status_count = 0;

    CHECK(external && external_file && root && sub && file && link && state,
          "recursive test allocation");
    CHECK(make_directory(external) == 0 && make_file(external_file) == 0,
          "external target setup");
    CHECK(make_directory(root) == 0 && make_directory(sub) == 0 &&
              make_file(file) == 0 && symlink(external, link) == 0,
          "recursive tree setup");
    CHECK(removefile_state_set(state, REMOVEFILE_STATE_STATUS_CALLBACK,
                               callback_bits(count_status)) == 0 &&
              removefile_state_set(state, REMOVEFILE_STATE_STATUS_CONTEXT,
                                   &status_count) == 0,
          "status callback setup");
    CHECK(removefile(root, state, REMOVEFILE_RECURSIVE) == 0,
          "recursive depth-first removal");
    CHECK(!exists(root), "recursive root removed");
    CHECK(exists(external_file), "symlink target preserved");
    CHECK(status_count == 4, "status reports every removed entry");
    CHECK(removefile_state_free(state) == 0, "recursive state free");
    free(external);
    free(external_file);
    free(root);
    free(sub);
    free(file);
    free(link);
    return 0;
}

static int test_keep_parent_and_confirm_skip(void)
{
    char *keep = join_path(test_root, "keep-parent");
    char *sub = join_path(keep, "sub");
    char *file = join_path(sub, "file");
    char *delegated = join_path(test_root, "delegate");
    char *drop = join_path(delegated, "drop");
    char *skip = join_path(delegated, "skip");
    removefile_state_t state = removefile_state_alloc();

    CHECK(keep && sub && file && delegated && drop && skip && state,
          "keep/confirm allocation");
    CHECK(make_directory(keep) == 0 && make_directory(sub) == 0 &&
              make_file(file) == 0,
          "keep-parent tree setup");
    CHECK(removefile(keep, NULL,
                     REMOVEFILE_RECURSIVE | REMOVEFILE_KEEP_PARENT) == 0,
          "keep-parent recursive removal");
    CHECK(exists(keep) && !exists(sub), "parent retained and contents removed");

    CHECK(make_directory(delegated) == 0 && make_file(drop) == 0 &&
              make_file(skip) == 0,
          "delegate tree setup");
    CHECK(removefile_state_set(state, REMOVEFILE_STATE_CONFIRM_CALLBACK,
                               callback_bits(skip_named_file)) == 0,
          "confirm callback setup");
    CHECK(removefile(delegated, state,
                     REMOVEFILE_RECURSIVE | REMOVEFILE_KEEP_PARENT) == 0,
          "confirm skip walk");
    CHECK(!exists(drop) && exists(skip) && exists(delegated),
          "confirm callback skips exactly one item");
    CHECK(removefile_state_free(state) == 0, "delegate state free");
    CHECK(removefile(delegated, NULL, REMOVEFILE_RECURSIVE) == 0,
          "delegate cleanup");
    CHECK(removefile(keep, NULL, REMOVEFILE_RECURSIVE) == 0,
          "keep-parent cleanup");
    free(keep);
    free(sub);
    free(file);
    free(delegated);
    free(drop);
    free(skip);
    return 0;
}

static int test_errors_cancellation_and_flags(void)
{
    char *missing = join_path(test_root, "missing");
    char *cancel_root = join_path(test_root, "cancel");
    char *cancel_file = join_path(cancel_root, "file");
    char *secure_file = join_path(test_root, "secure");
    char *at_file = join_path(test_root, "at-file");
    char *at_relative = join_path(test_root, "at-relative");
    char *original_directory = getcwd(NULL, 0);
    removefile_state_t error_state = removefile_state_alloc();
    removefile_state_t cancel_state = removefile_state_alloc();
    struct error_context error = {0, REMOVEFILE_PROCEED};
    struct cancel_context cancel = {0};
    int state_error = 0;

    CHECK(missing && cancel_root && cancel_file && secure_file && at_file &&
              at_relative && original_directory && error_state && cancel_state,
          "error/cancel allocation");
    CHECK(removefile_state_set(error_state, REMOVEFILE_STATE_ERROR_CALLBACK,
                               callback_bits(handle_error)) == 0 &&
              removefile_state_set(error_state, REMOVEFILE_STATE_ERROR_CONTEXT,
                                   &error) == 0,
          "error callback setup");
    CHECK(removefile(missing, error_state, REMOVEFILE_RECURSIVE) == 0 &&
              error.calls == 1,
          "delegate proceeds after error");
    CHECK(removefile_state_get(error_state, REMOVEFILE_STATE_ERRNO,
                               &state_error) == 0 && state_error == ENOENT,
          "state preserves reported errno");
    error.decision = REMOVEFILE_STOP;
    errno = 0;
    CHECK(removefile(missing, error_state, REMOVEFILE_RECURSIVE) == -1 &&
              errno == ENOENT && error.calls == 2,
          "delegate stops after error");

    CHECK(make_directory(cancel_root) == 0 && make_file(cancel_file) == 0,
          "cancellation tree setup");
    CHECK(removefile_state_set(cancel_state, REMOVEFILE_STATE_CONFIRM_CALLBACK,
                               callback_bits(cancel_during_walk)) == 0 &&
              removefile_state_set(cancel_state,
                                   REMOVEFILE_STATE_CONFIRM_CONTEXT,
                                   &cancel) == 0,
          "cancellation callback setup");
    errno = 0;
    CHECK(removefile(cancel_root, cancel_state, REMOVEFILE_RECURSIVE) == -1 &&
              errno == ECANCELED && cancel.confirmations == 2,
          "active cancellation is honored");
    CHECK(exists(cancel_root), "cancelled tree remains reachable");
    CHECK(removefile_state_free(cancel_state) == 0, "cancel state free");
    CHECK(removefile(cancel_root, NULL, REMOVEFILE_RECURSIVE) == 0,
          "cancelled tree cleanup with fresh state");

    CHECK(make_file(secure_file) == 0, "secure refusal file setup");
    errno = 0;
    CHECK(removefile(secure_file, NULL, REMOVEFILE_SECURE_1_PASS) == -1 &&
              errno == ENOTSUP && exists(secure_file),
          "secure erase is honestly unsupported");
    CHECK(removefile(secure_file, NULL, 0) == 0, "secure file cleanup");

    CHECK(make_file(at_file) == 0, "removefileat setup");
    CHECK(removefileat(123, at_file, NULL, 0) == 0,
          "absolute removefileat ignores descriptor");
    CHECK(make_file(at_relative) == 0 && chdir(test_root) == 0,
          "relative removefileat setup");
    CHECK(removefileat(AT_FDCWD, "at-relative", NULL, 0) == 0,
          "relative removefileat uses the current-directory descriptor");
    CHECK(chdir(original_directory) == 0, "restore directory after removefileat");
    errno = 0;
    CHECK(removefileat(123, "relative", NULL, 0) == -1 && errno == ENOTSUP,
          "unsupported relative descriptor is explicit");

    CHECK(removefile_state_free(error_state) == 0, "error state free");
    free(missing);
    free(cancel_root);
    free(cancel_file);
    free(secure_file);
    free(at_file);
    free(at_relative);
    free(original_directory);
    return 0;
}

int main(void)
{
    char template[] = "/tmp/open-foundation-removefile.XXXXXX";

    test_root = mkdtemp(template);
    CHECK(test_root != NULL, "temporary root");
    CHECK(test_state_surface() == 0, "state surface");
    CHECK(test_recursive_and_symlink() == 0, "recursive/symlink semantics");
    CHECK(test_keep_parent_and_confirm_skip() == 0,
          "keep-parent/confirm semantics");
    CHECK(test_errors_cancellation_and_flags() == 0,
          "error/cancel/flags semantics");
    CHECK(removefile(test_root, NULL, REMOVEFILE_RECURSIVE) == 0,
          "temporary root cleanup");
    puts("OPEN_FOUNDATION_REMOVEFILE_OK recursive=depth-first "
         "symlink=no-follow keep-parent=yes callbacks=confirm,error,status "
         "cancellation=honored secure=refused");
    return 0;
}
