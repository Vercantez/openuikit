/* sem_open.c -- Darwin named semaphores. sem_t is int; glibc's is a struct.
 *
 * A by-name host-bind is wrong (SEM_FAILED inverted, 4 vs 32 byte object).
 * libSystem mints a heap object and translates O_* / the failure sentinel.
 *
 * Operator: tests/build_fixtures.sh sem_open &&
 * harness/run_macos.sh --record sem_open, then flip the manifest cell to `run`.
 */
#include <fcntl.h>
#include <stdio.h>
#include <sys/semaphore.h>
#include <unistd.h>

int main(void)
{
    char name[64];
    sem_t *s;
    int rc;

    snprintf(name, sizeof name, "/mr_sem_%d", (int)getpid());
    sem_unlink(name);
    s = sem_open(name, O_CREAT | O_EXCL, 0600, 1);
    printf("sem_open_not_FAILED     %s\n", (s != SEM_FAILED) ? "yes" : "NO");
    if (s == SEM_FAILED) {
        printf("done\n");
        return 1;
    }
    rc = sem_wait(s);
    printf("sem_wait                rc=%d\n", rc);
    rc = sem_post(s);
    printf("sem_post                rc=%d\n", rc);
    rc = sem_close(s);
    printf("sem_close               rc=%d\n", rc);
    rc = sem_unlink(name);
    printf("sem_unlink              rc=%d\n", rc);
    puts("done");
    return 0;
}
