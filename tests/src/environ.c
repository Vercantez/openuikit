/* environ.c -- the environment is two arrays with one name, and the bug was
 * latent before anything wrote to it.
 *
 * `environ` is a VARIABLE the guest reads directly; getenv is a CALL. Under
 * machorun those had different backing until now: `environ` was set from the
 * loader's envp and getenv forwarded to glibc, which reads glibc's own array.
 * At startup both hold the same contents, so every read agrees and nothing
 * looks wrong. **The divergence only appears after the first write** -- which
 * is the worst possible lifetime for a defect, because the code that breaks is
 * never the code that introduced it.
 *
 * That is the two-reference-counts shape: no size differs, no constant
 * differs, both sides are internally consistent, and nothing structural
 * catches it.
 *
 * SO THIS FIXTURE IS ABOUT AGREEMENT, NOT ABOUT VALUES. It never prints an
 * environment variable's contents -- a container and a Mac share almost none
 * of their environment, and even two shells differ. What it checks is that the
 * two spellings answer the same question, before and after each kind of
 * mutation:
 *
 *   setenv then getenv        the call sees it
 *   setenv then walk environ  the ARRAY sees it too
 *   unsetenv then both        both stop seeing it
 *
 * The walk is the half that would have failed. getenv alone passes with two
 * separate environments, because getenv and setenv were always talking to the
 * SAME one -- glibc's. It is the guest's `environ` that was the odd one out,
 * and only a walk touches it.
 *
 * The re-point after each write is load-bearing for a second reason the fixture
 * exercises deliberately: glibc's setenv REALLOCATES the array when it grows,
 * so a pointer cached at bootstrap is correct until the first setenv and then
 * points at freed memory. Adding several variables in a row is what forces at
 * least one reallocation.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern char **environ;

/* Walk the ARRAY rather than calling getenv -- that is the whole point. */
static const char *walk(const char *name)
{
    size_t n = strlen(name);
    char **e;
    for (e = environ; e && *e; e++)
        if (strncmp(*e, name, n) == 0 && (*e)[n] == '=') return (*e) + n + 1;
    return NULL;
}

static void agree(const char *label, const char *name, const char *expect)
{
    const char *viaCall = getenv(name);
    const char *viaWalk = walk(name);
    int callOK = expect ? (viaCall && strcmp(viaCall, expect) == 0) : (viaCall == NULL);
    int walkOK = expect ? (viaWalk && strcmp(viaWalk, expect) == 0) : (viaWalk == NULL);
    printf("  %-28s getenv:%-3s environ-walk:%-3s agree:%s\n", label,
           callOK ? "ok" : "NO", walkOK ? "ok" : "NO",
           (callOK && walkOK) ? "yes" : "NO");
}

int main(void)
{
    int i, rc;
    char name[32];

    puts("== a variable that does not exist");
    agree("before setenv", "MR_ENVIRON_PROBE", NULL);

    puts("== after setenv, both spellings must see it");
    rc = setenv("MR_ENVIRON_PROBE", "one", 1);
    printf("  setenv rc=%d\n", rc);
    agree("after setenv", "MR_ENVIRON_PROBE", "one");

    puts("== overwrite, and overwrite=0 must NOT overwrite");
    setenv("MR_ENVIRON_PROBE", "two", 1);
    agree("after overwrite=1", "MR_ENVIRON_PROBE", "two");
    setenv("MR_ENVIRON_PROBE", "three", 0);
    agree("after overwrite=0", "MR_ENVIRON_PROBE", "two");

    puts("== enough new variables to force a reallocation");
    /* glibc grows the array by reallocating, which CHANGES the value of its
     * environ. A guest holding a pointer cached at bootstrap would be walking
     * freed memory from here on, and the walk below is what notices. */
    for (i = 0; i < 64; i++) {
        snprintf(name, sizeof name, "MR_ENVIRON_FILL_%d", i);
        setenv(name, "x", 1);
    }
    agree("original still visible", "MR_ENVIRON_PROBE", "two");
    agree("the last filler", "MR_ENVIRON_FILL_63", "x");
    {
        /* And the array must still be walkable end to end -- a stale pointer
         * would either miss entries or run off into freed memory. */
        int count = 0;
        char **e;
        for (e = environ; e && *e; e++) count++;
        printf("  environ has at least the 65 we added: %s\n",
               count >= 65 ? "yes" : "NO");
    }

    puts("== unsetenv, and both spellings must stop seeing it");
    rc = unsetenv("MR_ENVIRON_PROBE");
    printf("  unsetenv rc=%d\n", rc);
    agree("after unsetenv", "MR_ENVIRON_PROBE", NULL);

    puts("== putenv, which stores the caller's buffer rather than copying");
    {
        static char buf[] = "MR_ENVIRON_PUT=alpha";
        rc = putenv(buf);
        printf("  putenv rc=%d\n", rc);
        agree("after putenv", "MR_ENVIRON_PUT", "alpha");
        unsetenv("MR_ENVIRON_PUT");
    }

    puts("done");
    return 0;
}
