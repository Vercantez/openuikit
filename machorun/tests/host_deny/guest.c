/* guest.c -- the guest side of the host-bind deny fixture.
 *
 * Deliberately imports NOTHING interesting itself. A guest executable is not
 * is_runtime, so its own undefined symbols never reach the host fallback --
 * they are reported and the load fails, which is already the right behaviour
 * and is not what this fixture is about. Everything happens in
 * libdenyprobe.dylib, which lives inside the darwin root.
 */
#include <stdio.h>

extern int deny_probe(const char *what);

int main(int argc, char **argv)
{
    if (argc != 2) { printf("usage: guest <probe-name>\n"); return 64; }
    return deny_probe(argv[1]);
}
