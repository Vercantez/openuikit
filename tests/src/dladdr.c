/* dladdr.c -- the `dladdr` rung: "which image and symbol is this address in", and
 * the scoped dlsym handles.
 *
 * THESE ARE ONE GAP, NOT THREE. `dladdr`, `dlsym(RTLD_NEXT/RTLD_SELF/
 * RTLD_MAIN_ONLY)` and `dlopen`'s `@loader_path` were all unimplemented for
 * the same reason: machorun had no notion of THE CALLING IMAGE. The loader
 * only ever sees its own frames, so asking it there is asking the wrong
 * process. Asking in libSystem.B.dylib -- a Mach-O we build, which the guest
 * calls directly -- makes `__builtin_return_address(0)` the guest's own return
 * address in the guest's own image, and nothing has to be walked.
 *
 * WHY THIS READS THE SYMBOL TABLE AND NOT THE EXPORT TRIE. Measured on macOS:
 * `dladdr` on a STATIC, non-exported function returns its name. The export
 * trie has no such symbol -- it carries only what an image vends -- so a
 * trie-based implementation returns `dli_sname = NULL` for exactly the
 * addresses a crash report cares about most, while still returning 1 and
 * looking like it worked. `local_fn` below is static for that reason.
 *
 * WHAT IS DELIBERATELY NOT COMPARED, AND WHY THAT IS NOT WEAKNESS. `dli_fname`
 * is an absolute path and legitimately differs: macOS gives the path it
 * exec'd, machorun gives the install name or a path under `darwin/`. Printing
 * it would make this fixture fail for a reason that is not a defect -- the
 * same trap that made `tests/meta/*.otool.txt` churn on every worktree. So the
 * BASENAME is compared, which is a real property, and the directory is not.
 *
 * TEETH, BY THREE MUTATIONS OF src/image.c, each confirmed in the built loader
 * before the result was trusted:
 *
 *   answer from the export trie   -> FAIL. This is the TEMPTING SHORTCUT --
 *     instead of LC_SYMTAB           the trie is already parsed and already
 *                                    indexed -- and it fails on the static
 *                                    function AND on dli_saddr, because the
 *                                    nearest EXPORTED symbol below a static
 *                                    function is some other function entirely.
 *                                    A wrong name with a plausible address.
 *   RTLD_NEXT does not skip the   -> FAIL, on exactly one case: the one that
 *     caller (NEXT behaves as        distinguishes NEXT from SELF. Every other
 *     SELF)                          scoped case still passes.
 *   keep the leading underscore   -> FAIL on all three name comparisons.
 *
 * Addresses are never printed either. Everything here is a relationship
 * between two values obtained at run time -- is this pointer equal to that
 * one, is this base below that address -- which holds identically on both
 * platforms while the numbers do not.
 */
#include <dlfcn.h>
#include <stdio.h>
#include <string.h>

static int failures;

static void check(const char *what, int ok)
{
    printf("%-46s %s\n", what, ok ? "ok" : "FAIL");
    if (!ok) failures++;
}

static const char *base(const char *p)
{
    const char *s = p ? strrchr(p, '/') : 0;
    return s ? s + 1 : (p ? p : "(null)");
}

/* Deliberately static: it is in LC_SYMTAB and NOT in the export trie. */
__attribute__((noinline)) static int local_fn(void) { return 5; }

/* Exported, so it is in both. */
__attribute__((noinline)) int exported_fn(void);
__attribute__((noinline)) int exported_fn(void) { return 6; }

int main(void)
{
    Dl_info i;
    int stack_var;

    /* --- an address in this executable, from the symbol table ---------- */
    memset(&i, 0, sizeof i);
    check("dladdr on a static function returns 1", dladdr((void *)local_fn, &i) == 1);
    check("  names it (symtab, not the export trie)",
          i.dli_sname && strcmp(i.dli_sname, "local_fn") == 0);
    check("  dli_saddr is exactly the function", i.dli_saddr == (void *)local_fn);
    check("  dli_fbase is below the function",
          (const char *)i.dli_fbase < (const char *)local_fn);
    check("  dli_fname basename is this program",
          strcmp(base(i.dli_fname), "dladdr") == 0);

    /* --- an exported one, same answers ---------------------------------- */
    memset(&i, 0, sizeof i);
    check("dladdr on an exported function returns 1", dladdr((void *)exported_fn, &i) == 1);
    check("  names it", i.dli_sname && strcmp(i.dli_sname, "exported_fn") == 0);
    check("  the underscore is stripped",
          i.dli_sname && i.dli_sname[0] != '_');

    /* --- a libSystem address: a DIFFERENT image -------------------------
     *
     * printf, NOT strlen, and the oracle is why. Measured on macOS:
     * dladdr(strlen) answers `_platform_strlen` in libsystem_platform.dylib,
     * because Apple splits libSystem into sub-libraries and strlen is an
     * assembly routine under another name. machorun has one libSystem.B.dylib
     * and would say `strlen`. That difference is a real property of the two
     * platforms and not a defect in either, so asserting on it would make this
     * fixture fail for the wrong reason forever. printf is `printf` on both.
     *
     * The IMAGE name is still not compared -- libsystem_c.dylib against
     * libSystem.B.dylib -- only that it is not this executable, which is the
     * part that is actually being tested. */
    memset(&i, 0, sizeof i);
    check("dladdr on a libc function returns 1", dladdr((void *)printf, &i) == 1);
    check("  it is not this executable",
          i.dli_fname && strcmp(base(i.dli_fname), "dladdr") != 0);
    check("  names it", i.dli_sname && strcmp(i.dli_sname, "printf") == 0);

    /* --- addresses in NO image. 0, not -1, and dlerror stays unset. ----- */
    check("dladdr on a stack address returns 0", dladdr(&stack_var, &i) == 0);
    check("dladdr(NULL) returns 0", dladdr(0, &i) == 0);

    /* --- the scoped handles -------------------------------------------- */
    /* RTLD_SELF searches the caller's image first, so a symbol defined HERE
     * must be found and must be this image's copy. */
    check("RTLD_SELF finds a symbol in the caller",
          dlsym(RTLD_SELF, "exported_fn") == (void *)exported_fn);

    /* RTLD_NEXT starts AFTER the caller, so the same symbol must NOT be found
     * -- nothing later defines it. Getting this backwards is the whole
     * difference between NEXT and SELF, and a lookup that ignored scope
     * entirely would pass the SELF case and fail this one. */
    check("RTLD_NEXT skips the caller's own image",
          dlsym(RTLD_NEXT, "exported_fn") == NULL);

    /* A libSystem symbol IS after us in load order, so NEXT finds it. */
    check("RTLD_NEXT finds a later image's symbol",
          dlsym(RTLD_NEXT, "printf") != NULL);

    /* RTLD_MAIN_ONLY searches the executable and nothing else. */
    check("RTLD_MAIN_ONLY finds this image's symbol",
          dlsym(RTLD_MAIN_ONLY, "exported_fn") == (void *)exported_fn);
    check("RTLD_MAIN_ONLY does not find libc's",
          dlsym(RTLD_MAIN_ONLY, "printf") == NULL);

    /* RTLD_DEFAULT still works and is a different search from all of them. */
    check("RTLD_DEFAULT still finds a libc symbol",
          dlsym(RTLD_DEFAULT, "printf") != NULL);

    printf("%s: %d failure(s)\n", failures ? "FAILED" : "PASSED", failures);
    return failures ? 1 : 0;
}
