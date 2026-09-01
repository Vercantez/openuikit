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
    void *serial_queue;
    void *concurrent_queue;
    uint64_t before;
    uint64_t after;
    unsigned index;

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

    serial_queue = openui_dispatch_host_v1_create_queue(
        "org.openui.tests.serial", 0x11, 0, 0, NULL
    );
    if (serial_queue == NULL) fail("serial custom queue unavailable");
    openui_dispatch_host_v1_async(
        OPENUI_DISPATCH_QUEUE_CUSTOM_V1, serial_queue, &state, increment
    );
    openui_dispatch_host_v1_sync(
        OPENUI_DISPATCH_QUEUE_CUSTOM_V1, serial_queue, 0, &state, increment
    );
    if (state.count != 4) fail("serial custom queue did not preserve ordering");
    openui_dispatch_host_v1_release_queue(serial_queue);
    expect_rejection(OPENUI_DISPATCH_QUEUE_CUSTOM_V1, serial_queue);

    concurrent_queue = openui_dispatch_host_v1_create_queue(
        "org.openui.tests.concurrent", 0x15,
        OPENUI_DISPATCH_QUEUE_CONCURRENT_V1, 0, NULL
    );
    if (concurrent_queue == NULL) fail("concurrent custom queue unavailable");
    for (index = 0; index < 16; index++) {
        openui_dispatch_host_v1_async(
            OPENUI_DISPATCH_QUEUE_CUSTOM_V1,
            concurrent_queue,
            &state,
            increment
        );
    }
    openui_dispatch_host_v1_sync(
        OPENUI_DISPATCH_QUEUE_CUSTOM_V1,
        concurrent_queue,
        OPENUI_DISPATCH_WORK_BARRIER_V1,
        &state,
        increment
    );
    if (state.count != 21) fail("barrier sync did not drain preceding work");
    openui_dispatch_host_v1_release_queue(concurrent_queue);

    if (setenv("OPENUI_DISPATCH_MEMORY_PRESSURE", "normal", 1) != 0) {
        fail("setenv normal failed");
    }
    if (openui_dispatch_host_v1_memory_pressure()
        != OPENUI_DISPATCH_MEMORY_PRESSURE_NORMAL_V1) {
        fail("normal pressure override failed");
    }
    if (setenv("OPENUI_DISPATCH_MEMORY_PRESSURE", "warning", 1) != 0) {
        fail("setenv warning failed");
    }
    if (openui_dispatch_host_v1_memory_pressure()
        != OPENUI_DISPATCH_MEMORY_PRESSURE_WARNING_V1) {
        fail("warning pressure override failed");
    }
    if (setenv("OPENUI_DISPATCH_MEMORY_PRESSURE", "critical", 1) != 0) {
        fail("setenv critical failed");
    }
    if (openui_dispatch_host_v1_memory_pressure()
        != OPENUI_DISPATCH_MEMORY_PRESSURE_CRITICAL_V1) {
        fail("critical pressure override failed");
    }
    if (unsetenv("OPENUI_DISPATCH_MEMORY_PRESSURE") != 0) {
        fail("unsetenv pressure failed");
    }

    puts("OPEN_DISPATCH_HOST_OK global=minted custom=serial,concurrent sync=ordered,barrier memory-pressure=cgroup,proc,override async=worker after=timer main-token=contained glibc>=2.38");
    return 0;
}
