/* socket_loopback.c -- the `socket_loopback` rung: BSD sockets over 127.0.0.1
 * and AF_UNIX, the calls a guest-side HTTP loopback server makes (the Ledger
 * conformance app: socket / setsockopt(SO_REUSEADDR) / bind / listen /
 * getsockname / accept, then read/write/close on both ends).
 *
 * WHAT IS TRANSLATED, AND WHY A PLAIN FORWARD IS WRONG ON EVERY CALL:
 *
 *     struct sockaddr_in   Darwin { u8 sin_len; u8 sin_family; ... }
 *                          Linux  { u16 sin_family; ... }
 *                          same 16 bytes, DIFFERENT first two: forwarded, the
 *                          kernel reads family = (len | family<<8) = 0x0210,
 *                          which is EAFNOSUPPORT at best.
 *     AF_INET6             Darwin 30, Linux 10 (AF_INET/AF_UNIX agree: 2/1)
 *     SOL_SOCKET           Darwin 0xffff, Linux 1  (and 1 is a valid level)
 *     SO_REUSEADDR         Darwin 0x0004, Linux 2
 *     SO_ERROR             Darwin 0x1007, Linux 4
 *     MSG_DONTWAIT         Darwin 0x80,   Linux 0x40
 *     ECONNREFUSED         Darwin 61,     Linux 111 (errno, checked by NAME)
 *
 * Nothing host-specific is printed: no descriptor numbers, no ephemeral port,
 * no addresses beyond the loopback literal both systems agree on. Identical
 * on macOS and under machorun when the translation holds. */
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>

static const char *errname(int e)
{
    switch (e) {
    case ECONNREFUSED: return "ECONNREFUSED";
    case EADDRINUSE:   return "EADDRINUSE";
    case EINPROGRESS:  return "EINPROGRESS";
    case EAGAIN:       return "EAGAIN";
    case ENOTSOCK:     return "ENOTSOCK";
    case EAFNOSUPPORT: return "EAFNOSUPPORT";
    case EPIPE:        return "EPIPE";
    default:           return "other";
    }
}

static void line(const char *label, const char *value)
{
    printf("  %-34s %s\n", label, value);
}

static void yesno(const char *label, int cond)
{
    line(label, cond ? "yes" : "no");
}

int main(void)
{
    int srv, cli, conn, rc, one = 1;
    struct sockaddr_in a, bound, peer;
    socklen_t len;
    char buf[64];

    printf("== TCP loopback\n");
    srv = socket(AF_INET, SOCK_STREAM, 0);
    yesno("socket(AF_INET, SOCK_STREAM)", srv >= 0);
    rc = setsockopt(srv, SOL_SOCKET, SO_REUSEADDR, &one, sizeof one);
    yesno("setsockopt(SO_REUSEADDR)", rc == 0);
    rc = setsockopt(srv, SOL_SOCKET, SO_NOSIGPIPE, &one, sizeof one);
    yesno("setsockopt(SO_NOSIGPIPE)", rc == 0);

    memset(&a, 0, sizeof a);
    a.sin_len = sizeof a;
    a.sin_family = AF_INET;
    a.sin_port = 0;                                   /* ephemeral */
    a.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    rc = bind(srv, (struct sockaddr *)&a, sizeof a);
    yesno("bind(127.0.0.1:0)", rc == 0);
    rc = listen(srv, 4);
    yesno("listen(4)", rc == 0);

    len = sizeof bound;
    memset(&bound, 0, sizeof bound);
    rc = getsockname(srv, (struct sockaddr *)&bound, &len);
    yesno("getsockname", rc == 0);
    yesno("  returned len == sizeof(sockaddr_in)", len == sizeof bound);
    yesno("  sin_len == sizeof(sockaddr_in)", bound.sin_len == sizeof bound);
    yesno("  sin_family == AF_INET", bound.sin_family == AF_INET);
    yesno("  port assigned", ntohs(bound.sin_port) != 0);
    inet_ntop(AF_INET, &bound.sin_addr, buf, sizeof buf);
    line("  address", buf);

    cli = socket(AF_INET, SOCK_STREAM, 0);
    rc = setsockopt(cli, IPPROTO_TCP, TCP_NODELAY, &one, sizeof one);
    yesno("setsockopt(TCP_NODELAY) on client", rc == 0);
    rc = connect(cli, (struct sockaddr *)&bound, sizeof bound);
    yesno("connect(ephemeral port)", rc == 0);

    len = sizeof peer;
    memset(&peer, 0, sizeof peer);
    conn = accept(srv, (struct sockaddr *)&peer, &len);
    yesno("accept", conn >= 0);
    yesno("  peer family == AF_INET", peer.sin_family == AF_INET);
    inet_ntop(AF_INET, &peer.sin_addr, buf, sizeof buf);
    line("  peer address", buf);

    rc = (int)send(conn, "GET /quote\n", 11, 0);
    yesno("send 11 bytes", rc == 11);
    memset(buf, 0, sizeof buf);
    rc = (int)recv(cli, buf, sizeof buf - 1, 0);
    yesno("recv 11 bytes", rc == 11 && strcmp(buf, "GET /quote\n") == 0);
    rc = (int)write(cli, "{\"amount\":12.5}", 15);
    yesno("write 15 bytes on client", rc == 15);
    memset(buf, 0, sizeof buf);
    rc = (int)read(conn, buf, sizeof buf - 1);
    yesno("read 15 bytes on accepted fd", rc == 15 && strcmp(buf, "{\"amount\":12.5}") == 0);
    rc = (int)recv(cli, buf, sizeof buf - 1, MSG_DONTWAIT);
    line("recv(MSG_DONTWAIT) on idle socket", rc < 0 ? errname(errno) : "data");

    {
        int err = -1; socklen_t el = sizeof err;
        rc = getsockopt(cli, SOL_SOCKET, SO_ERROR, &err, &el);
        yesno("getsockopt(SO_ERROR) == 0", rc == 0 && err == 0);
        int ra = -1; socklen_t rl = sizeof ra;
        rc = getsockopt(srv, SOL_SOCKET, SO_REUSEADDR, &ra, &rl);
        yesno("getsockopt(SO_REUSEADDR) reads back set", rc == 0 && ra != 0);
        /* SO_ACCEPTCONN is deliberately not graded: macOS 26.1 reports 0 for a
         * listening socket (recorded 2026-09-07) while Linux reports 1, so it
         * cannot serve as an oracle line. libdispatch's use is covered by the
         * fcntl_madvise rung's notes. */
    }
    rc = shutdown(conn, SHUT_WR);
    yesno("shutdown(SHUT_WR)", rc == 0);
    rc = (int)read(cli, buf, sizeof buf);
    yesno("peer read sees EOF", rc == 0);
    close(conn); close(cli); close(srv);

    printf("== refused connect\n");
    cli = socket(AF_INET, SOCK_STREAM, 0);
    memset(&a, 0, sizeof a);
    a.sin_len = sizeof a; a.sin_family = AF_INET;
    a.sin_port = htons(1); a.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    rc = connect(cli, (struct sockaddr *)&a, sizeof a);
    line("connect(127.0.0.1:1)", rc < 0 ? errname(errno) : "connected?!");
    close(cli);

    printf("== AF_UNIX socketpair\n");
    {
        int sv[2];
        rc = socketpair(AF_UNIX, SOCK_STREAM, 0, sv);
        yesno("socketpair(AF_UNIX, SOCK_STREAM)", rc == 0);
        rc = (int)write(sv[0], "ping", 4);
        memset(buf, 0, sizeof buf);
        rc = (int)read(sv[1], buf, sizeof buf - 1);
        yesno("ping across the pair", rc == 4 && strcmp(buf, "ping") == 0);
        close(sv[0]); close(sv[1]);
    }

    printf("== inet_pton / inet_ntop\n");
    {
        struct in_addr ia; struct in6_addr ia6; char out[64];
        yesno("inet_pton(AF_INET, 10.1.2.3)", inet_pton(AF_INET, "10.1.2.3", &ia) == 1);
        line("  round trip", inet_ntop(AF_INET, &ia, out, sizeof out));
        yesno("inet_pton(AF_INET6, ::1)", inet_pton(AF_INET6, "::1", &ia6) == 1);
        line("  round trip", inet_ntop(AF_INET6, &ia6, out, sizeof out));
        yesno("inet_pton rejects 300.1.1.1", inet_pton(AF_INET, "300.1.1.1", &ia) == 0);
    }
    printf("== not a socket\n");
    rc = listen(0, 1);
    line("listen(stdin)", rc < 0 ? errname(errno) : "accepted?!");
    return 0;
}
