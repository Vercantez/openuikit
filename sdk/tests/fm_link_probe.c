/*
 * fm_link_probe.c -- the FileManager surface, COMPILED AND LINKED.
 *
 * A STAGED HEADER IS A PROMISE, AND ONLY A LINK COLLECTS ON IT. sdk/ has been
 * bitten twice by the other kind of check: a header that compiles fine and
 * declares something nothing defines. `-fsyntax-only` cannot see that, the
 * .tbd is generated from the dylib so it cannot see it either, and the first
 * consumer to find out is whoever links a guest weeks later -- the partial
 * claim in its worst form (docs/UNIMPLEMENTED.md, `geteuid` alone).
 *
 * So this file takes the address of, or calls, every symbol #69 staged a
 * header for. It is compiled against sdk/ and LINKED against
 * sdk/usr/lib .tbd stubs. If a header lands without its implementation, the link
 * fails HERE, in a file whose whole purpose is to say so, rather than in
 * somebody's build.
 *
 * IT IS NOT RUN, and that is deliberate. Behaviour is graded by the difftest
 * fixtures against the macOS oracle, which is a stronger check than anything
 * this could assert; running it here would duplicate that badly. The claim
 * this file makes is exactly one: DECLARED AND DEFINED, TOGETHER.
 *
 * Two things it deliberately does NOT do:
 *   - it does not take addresses through a `void *` array and stop there. Each
 *     reference is a real call with real argument types, so a declaration that
 *     drifts from the definition's signature is a compile error too.
 *   - it does not #include a header for a family that is not implemented yet.
 *     A row here is added by the commit that implements the family; an empty
 *     section is a lie about coverage.
 */

#include <mach/mach.h>
#include <mach/vm_map.h>
#include <pwd.h>
#include <stddef.h>
#include <sys/utsname.h>
#include <sysdir.h>

/* Returned rather than discarded, so no call can be optimised away as dead. */
unsigned long fm_link_probe(void);
unsigned long fm_link_probe(void)
{
    unsigned long acc = 0;
    char path[1024];
    struct passwd pw, *res = NULL;
    char buf[2048];

    /* pwd.h -- libSystem exports these already; the header was the gap. */
    acc += (unsigned long)getpwnam_r("root", &pw, buf, sizeof buf, &res);
    acc += (unsigned long)getpwuid_r(0, &pw, buf, sizeof buf, &res);
    acc += (unsigned long)(res != NULL);

    /* sysdir.h -- same, and the enumerators have to name real constants for
     * this to compile at all. */
    {
        sysdir_search_path_enumeration_state st =
            sysdir_start_search_path_enumeration(SYSDIR_DIRECTORY_CACHES,
                                                 SYSDIR_DOMAIN_MASK_USER);
        path[0] = 0;
        st = sysdir_get_next_search_path_enumeration(st, path);
        acc += (unsigned long)st + (unsigned char)path[0];
    }

    /* mach/vm_map.h -- declared in sdk/local/mach/vm_map.h, whose standing rule
     * is that a routine appears only if libSystem exports it. This is that
     * rule made checkable instead of remembered. */
    {
        char a[64] = { 0 }, b[64] = { 0 };
        acc += (unsigned long)vm_copy(mach_task_self(),
                                      (vm_address_t)a, sizeof a, (vm_address_t)b);
    }

    /* sys/utsname.h */
    {
        struct utsname uts;
        acc += (unsigned long)uname(&uts) + (unsigned char)uts.sysname[0];
    }

    return acc;
}
