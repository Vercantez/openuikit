/* pthread -- the `pthread` rung: pthread create/join, plus per-thread TLS.
 *
 * Threads are joined in a fixed order and each one's result is printed from
 * main, so the output is deterministic despite the concurrency.
 *
 * Exercises: _pthread_create / _pthread_join / _pthread_mutex_* /
 * _pthread_once, and -- the part that actually bites -- a *second* thread
 * touching _Thread_local storage. On Darwin that means tlv_get_addr must
 * allocate and zero a fresh per-thread image on first touch in each thread,
 * and __thread_data initialisers must be copied in.
 */
#include <pthread.h>
#include <stdio.h>

static _Thread_local int per_thread = 5; /* each thread starts at 5 */
static pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;
static int shared = 0;
static pthread_once_t once = PTHREAD_ONCE_INIT;
static int once_count = 0;

static void once_fn(void) { once_count++; }

struct arg { int id; int tls_seen; };

static void *worker(void *raw) {
    struct arg *a = (struct arg *)raw;
    pthread_once(&once, once_fn);

    per_thread += a->id;   /* private to this thread */
    a->tls_seen = per_thread;

    pthread_mutex_lock(&lock);
    shared += a->id;
    pthread_mutex_unlock(&lock);
    return raw;
}

int main(void) {
    enum { N = 4 };
    pthread_t t[N];
    struct arg a[N];

    for (int i = 0; i < N; i++) {
        a[i].id = i + 1;
        a[i].tls_seen = -1;
        if (pthread_create(&t[i], NULL, worker, &a[i]) != 0) return 1;
    }
    for (int i = 0; i < N; i++) {
        void *r = NULL;
        if (pthread_join(t[i], &r) != 0) return 2;
        if (r != &a[i]) return 3;
    }

    for (int i = 0; i < N; i++)
        printf("thread %d tls=%d\n", a[i].id, a[i].tls_seen);
    printf("shared=%d\n", shared);
    printf("once_count=%d\n", once_count);
    printf("main tls=%d\n", per_thread); /* main's own copy, untouched */
    return 0;
}
