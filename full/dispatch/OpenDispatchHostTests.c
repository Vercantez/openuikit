#include "OpenDispatchABI.h"

#include <pthread.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

struct state {
    pthread_mutex_t lock;
    pthread_cond_t condition;
    unsigned count;
};

static void fail(const char *message)
{
    fprintf(stderr, "OpenDispatchHostTests: %s\n", message);
    exit(1);
}

static void increment(void *opaque)
{
    struct state *state = opaque;
    if (pthread_mutex_lock(&state->lock) != 0) abort();
    state->count++;
    if (pthread_cond_broadcast(&state->condition) != 0) abort();
    if (pthread_mutex_unlock(&state->lock) != 0) abort();
}

static void wait_for(struct state *state, unsigned expected)
{
    struct timespec deadline;
    if (clock_gettime(CLOCK_REALTIME, &deadline) != 0) fail("clock_gettime failed");
    deadline.tv_sec += 5;
    if (pthread_mutex_lock(&state->lock) != 0) fail("mutex lock failed");
    while (state->count < expected) {
        if (pthread_cond_timedwait(&state->condition, &state->lock, &deadline) != 0) {
            fail("timed out waiting for asynchronous callback");
        }
    }
    if (pthread_mutex_unlock(&state->lock) != 0) fail("mutex unlock failed");
}

static void expect_rejection(uint32_t kind, void *queue)
{
    pid_t child = fork();
    int status = 0;
    if (child < 0) fail("fork failed");
    if (child == 0) {
        openui_dispatch_host_v1_async(kind, queue, NULL, increment);
        _exit(0);
    }
    if (waitpid(child, &status, 0) != child) fail("waitpid failed");
    if (!WIFSIGNALED(status) || WTERMSIG(status) != SIGABRT) {
        fail("invalid queue boundary did not abort");
    }
}

int main(void)
{
    struct state state = {
        .lock = PTHREAD_MUTEX_INITIALIZER,
        .condition = PTHREAD_COND_INITIALIZER,
        .count = 0
    };
    void *queue;
    uint64_t before;
    uint64_t after;

    if (openui_dispatch_host_v1_runtime_check() != 0) fail("glibc requirement failed");
    queue = openui_dispatch_host_v1_get_global_queue(0x15, 4);
    if (queue == NULL) queue = openui_dispatch_host_v1_get_global_queue(0x15, 0);
    if (queue == NULL) fail("global queue unavailable");

    openui_dispatch_host_v1_async(
        OPENUI_DISPATCH_QUEUE_GLOBAL_V1, queue, &state, increment
    );
    wait_for(&state, 1);

    before = openui_dispatch_host_v1_monotonic_nanoseconds();
    openui_dispatch_host_v1_after(
        OPENUI_DISPATCH_QUEUE_GLOBAL_V1, queue, UINT64_C(1000000), &state, increment
    );
    wait_for(&state, 2);
    after = openui_dispatch_host_v1_monotonic_nanoseconds();
    if (after <= before) fail("monotonic clock did not advance");

    expect_rejection(OPENUI_DISPATCH_QUEUE_MAIN_V1, queue);
    expect_rejection(OPENUI_DISPATCH_QUEUE_GLOBAL_V1, (void *)(uintptr_t)0x1234);

    puts("OPEN_DISPATCH_HOST_OK global=minted async=worker after=timer main-token=contained glibc>=2.38");
    return 0;
}
