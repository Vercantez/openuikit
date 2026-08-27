/* Can a Darwin Mach-O guest actually create and use the Linux fd-wait
 * primitives? libSystem exports none of them; the question is whether that
 * matters. Runs under machorun. */
#include <sys/epoll.h>
#include <sys/eventfd.h>
#include <sys/timerfd.h>
#include <poll.h>
#include <stdio.h>
#include <string.h>

int main(void) {
    int fails = 0;

    int ep = epoll_create1(0);
    printf("epoll_create1     -> fd %d %s\n", ep, ep >= 0 ? "OK" : "FAIL");
    if (ep < 0) fails++;

    int ev = eventfd(0, 0);
    printf("eventfd           -> fd %d %s\n", ev, ev >= 0 ? "OK" : "FAIL");
    if (ev < 0) fails++;

    int tf = timerfd_create(1 /*CLOCK_MONOTONIC*/, 0);
    printf("timerfd_create    -> fd %d %s\n", tf, tf >= 0 ? "OK" : "FAIL");
    if (tf < 0) fails++;

    /* Register the eventfd and prove the wait path actually reports it. */
    struct epoll_event e; memset(&e, 0, sizeof e);
    e.events = POLLIN; e.data.fd = ev;
    int r = epoll_ctl(ep, 1 /*EPOLL_CTL_ADD*/, ev, &e);
    printf("epoll_ctl ADD     -> %d %s\n", r, r == 0 ? "OK" : "FAIL");
    if (r != 0) fails++;

    unsigned long long one = 1;
    eventfd_write(ev, one);
    struct epoll_event out; memset(&out, 0, sizeof out);
    int n = epoll_wait(ep, &out, 1, 500);
    printf("epoll_wait        -> %d event(s), fd %d %s\n", n, out.data.fd,
           (n == 1 && out.data.fd == ev) ? "OK -- the wait path WORKS" : "FAIL");
    if (!(n == 1 && out.data.fd == ev)) fails++;

    printf("%s (%d failure%s)\n", fails ? "FAILED" : "OK", fails,
           fails == 1 ? "" : "s");
    return fails != 0;
}
