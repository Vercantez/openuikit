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

#include <copyfile.h>
#include <grp.h>
#include <mach/mach.h>
#include <mach/vm_map.h>
#include <pwd.h>
#include <stddef.h>
#include <stdint.h>
#include <sys/mount.h>
#include <sys/quota.h>
#include <sys/utsname.h>
#include <sys/xattr.h>
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

    /* grp.h -- the family whole: both lookup keys and both reentrancy forms. */
    {
        struct group gr, *gres = NULL;
        acc += (unsigned long)getgrnam_r("root", &gr, buf, sizeof buf, &gres);
        acc += (unsigned long)getgrgid_r(0, &gr, buf, sizeof buf, &gres);
        acc += (unsigned long)(getgrnam("root") != NULL);
        acc += (unsigned long)(getgrgid(0) != NULL);
    }

    /* sys/xattr.h -- the family whole: path and descriptor forms of all four
     * operations. Eight entry points, not the five #69 named. */
    {
        const char *p = "/dev/null";
        acc += (unsigned long)getxattr(p, "user.x", buf, sizeof buf, 0, 0);
        acc += (unsigned long)fgetxattr(0, "user.x", buf, sizeof buf, 0, 0);
        acc += (unsigned long)setxattr(p, "user.x", buf, 1, 0, XATTR_CREATE);
        acc += (unsigned long)fsetxattr(0, "user.x", buf, 1, 0, XATTR_REPLACE);
        acc += (unsigned long)removexattr(p, "user.x", XATTR_NOFOLLOW);
        acc += (unsigned long)fremovexattr(0, "user.x", 0);
        acc += (unsigned long)listxattr(p, buf, sizeof buf, 0);
        acc += (unsigned long)flistxattr(0, buf, sizeof buf, 0);
    }

    /* sys/quota.h */
    {
        int on = 0;
        acc += (unsigned long)quotactl("/", QCMD(Q_QUOTASTAT, USRQUOTA), 0, (char *)&on);
    }

    /* sys/utsname.h */
    {
        struct utsname uts;
        acc += (unsigned long)uname(&uts) + (unsigned char)uts.sysname[0];
    }

    /* sys/mount.h -- layout translation; f_mntonname is the field Linux's
     * statfs does not have. Both spellings, because arm64 unsuffixed names
     * and the $INODE64 aliases are the same function. */
    {
        struct statfs sfs;
        acc += (unsigned long)statfs("/", &sfs);
        acc += (unsigned long)fstatfs(0, &sfs);
        acc += (unsigned char)sfs.f_mntonname[0];
        acc += (unsigned long)sizeof(struct statfs);
    }

    /* copyfile.h -- FE's used subset. The state/callback/removefile surface
     * is declared and defined (and aborts if called); taking the address
     * here is what makes a missing stub a link failure rather than a
     * runtime surprise. */
    {
        copyfile_state_t st = 0;
        acc += (unsigned long)copyfile("/dev/null", "/tmp/machorun_fm_link",
                                       st, COPYFILE_DATA);
        acc += (unsigned long)fcopyfile(0, 1, st, COPYFILE_DATA);
        acc += (unsigned long)(uintptr_t)copyfile_state_alloc;
        acc += (unsigned long)(uintptr_t)copyfile_state_free;
        acc += (unsigned long)(uintptr_t)copyfile_state_get;
        acc += (unsigned long)(uintptr_t)copyfile_state_set;
    }

    return acc;
}
