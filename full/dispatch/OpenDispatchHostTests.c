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

static int specific_key;
static int specific_value;

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

static void no_op(void *opaque)
{
    (void)opaque;
}

static void increment_with_specific(void *opaque)
{
    if (openui_dispatch_host_v1_get_specific(&specific_key)
        != &specific_value) {
        fail("private queue specific value was not visible in callback");
    }
    increment(opaque);
}

static void signal_semaphore(void *opaque)
{
    if (openui_dispatch_host_v1_semaphore_signal(opaque) < 0) {
        fail("semaphore signal returned an invalid result");
    }
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

static void expect_semaphore_rejection(void)
{
    pid_t child = fork();
    int status = 0;
    if (child < 0) fail("fork failed");
    if (child == 0) {
        (void)openui_dispatch_host_v1_semaphore_signal(
            (void *)(uintptr_t)0x1234
        );
        _exit(0);
    }
    if (waitpid(child, &status, 0) != child) fail("waitpid failed");
    if (!WIFSIGNALED(status) || WTERMSIG(status) != SIGABRT) {
        fail("invalid semaphore boundary did not abort");
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
    void *private_queue;
    void *semaphore;
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

    private_queue = openui_dispatch_host_v1_create_queue(
        "portable.private",
        0,
        0x15,
        0,
        0,
        NULL
    );
    if (private_queue == NULL) fail("private queue unavailable");
    openui_dispatch_host_v1_queue_set_specific(
        OPENUI_DISPATCH_QUEUE_PRIVATE_V1,
        private_queue,
        &specific_key,
        &specific_value,
        no_op
    );
    openui_dispatch_host_v1_async(
        OPENUI_DISPATCH_QUEUE_PRIVATE_V1,
        private_queue,
        &state,
        increment_with_specific
    );
    wait_for(&state, 3);
    openui_dispatch_host_v1_release_queue(private_queue);

    semaphore = openui_dispatch_host_v1_semaphore_create(0);
    if (semaphore == NULL) fail("semaphore unavailable");
    openui_dispatch_host_v1_async(
        OPENUI_DISPATCH_QUEUE_GLOBAL_V1,
        queue,
        semaphore,
        signal_semaphore
    );
    if (openui_dispatch_host_v1_semaphore_wait(
            semaphore,
            UINT64_C(5000000000)
        ) != 0) {
        fail("semaphore did not observe asynchronous signal");
    }
    if (openui_dispatch_host_v1_semaphore_wait(
            semaphore,
            UINT64_C(1000000)
        ) != 1) {
        fail("semaphore timeout did not fail closed");
    }
    openui_dispatch_host_v1_semaphore_release(semaphore);

    expect_rejection(OPENUI_DISPATCH_QUEUE_MAIN_V1, queue);
    expect_rejection(OPENUI_DISPATCH_QUEUE_GLOBAL_V1, (void *)(uintptr_t)0x1234);
    expect_rejection(OPENUI_DISPATCH_QUEUE_PRIVATE_V1, (void *)(uintptr_t)0x1234);
    expect_semaphore_rejection();

    puts("OPEN_DISPATCH_HOST_OK global=minted private=serial specific=typed semaphore=signal,timeout async=worker after=timer tokens=contained glibc>=2.38");
    return 0;
}
