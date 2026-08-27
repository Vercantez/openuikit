/* loader_path.c -- the `loader_path` rung: @loader_path in a dlopen resolves
 * against the image that CALLED dlopen, not against the main executable.
 *
 * THE LAYOUT IS THE TEST. Two copies of the same library, same basename, in
 * two directories, and two images asking for it by the same string:
 *
 *     tests/bin/loader_path                                 the executable
 *     tests/bin/libloader_path_leaf.dylib                   leaf_where() -> "bin"
 *     tests/bin/loader_path_plugins/libloader_path_mid.dylib    the caller
 *     tests/bin/loader_path_plugins/libloader_path_leaf.dylib   -> "plugins"
 *
 * dlopen("@loader_path/libloader_path_leaf.dylib") is correct from both, and
 * correct means two DIFFERENT files. That is why the wrong answer here is
 * dangerous rather than merely wrong: resolving against the main executable
 * does not return NULL and does not fail a "did dlopen succeed" check -- it
 * returns a valid handle to the wrong library. A plugin would get the host
 * app's copy of its own dependency and nothing would look broken until the two
 * copies disagreed about something.
 *
 * WHAT EACH CASE IS FOR, since three spellings are involved and only two of
 * them follow the caller:
 *
 *   @loader_path      the caller's directory. The fix.
 *   @rpath            searches the CALLER's LC_RPATHs first, the main
 *                     executable's second. Nothing at the call site mentions
 *                     the caller, which is what makes this one easy to miss:
 *                     the executable's first LC_RPATH is @loader_path (= bin)
 *                     and the middle dylib's is @loader_path (= plugins), so
 *                     the same @rpath string must resolve to different files.
 *   @executable_path  the main executable, from every image, always. It is the
 *                     control: it is the spelling that must NOT have moved,
 *                     and the difference between it and @loader_path is the
 *                     only reason Darwin has both.
 *
 * IDENTITY IS CHECKED IN BOTH DIRECTIONS. Two spellings that name the same
 * file must give the same handle -- dlopen canonicalises, so @loader_path and
 * @rpath from the executable are one image, not two -- and two spellings that
 * name different files must give different ones. Checking only "not NULL"
 * passes with the bug; checking only "different" passes with a loader that
 * loads a second copy of everything.
 *
 * On macOS this runs against real dyld, so every expectation is Apple's.
 */
#include <dlfcn.h>
#include <stdio.h>
#include <string.h>

static int failures;

static void check(const char *what, int ok)
{
    printf("%-52s %s\n", what, ok ? "ok" : "FAIL");
    if (!ok) failures++;
}

/* Same body as the middle dylib's mid_open, deliberately duplicated rather
 * than shared: it has to be compiled INTO THE EXECUTABLE, because the whole
 * question is which image the call is made from. A shared helper in a third
 * library would make both calls come from that library and quietly answer a
 * different question. */
static const char *exe_open(const char *path, void **handle_out)
{
    const char *(*where)(void);
    void *h = dlopen(path, RTLD_LAZY);

    if (handle_out) *handle_out = h;
    if (!h) return 0;
    where = (const char *(*)(void))dlsym(h, "leaf_where");
    return where ? where() : 0;
}

/* The middle image, linked by @rpath so it must be found in the subdirectory
 * before main() ever runs. */
extern const char *mid_open(const char *path, void **handle_out);

static int is(const char *got, const char *want)
{
    return got && strcmp(got, want) == 0;
}

int main(void)
{
    static const char leaf[] = "libloader_path_leaf.dylib";
    char spell[128];
    void *h_exe_loader = 0, *h_mid_loader = 0;
    void *h_exe_rpath = 0, *h_mid_rpath = 0;
    void *h_exe_exec = 0, *h_mid_exec = 0;
    const char *w;

    /* ------------------------------------------------ @loader_path */
    snprintf(spell, sizeof spell, "@loader_path/%s", leaf);

    w = exe_open(spell, &h_exe_loader);
    check("@loader_path from the executable finds bin's leaf", is(w, "bin"));

    w = mid_open(spell, &h_mid_loader);
    check("@loader_path from the plugin finds the plugin's leaf", is(w, "plugins"));

    check("the same string gave two different images",
          h_exe_loader && h_mid_loader && h_exe_loader != h_mid_loader);

    /* ------------------------------------------------ @rpath */
    snprintf(spell, sizeof spell, "@rpath/%s", leaf);

    w = exe_open(spell, &h_exe_rpath);
    check("@rpath searches the executable's LC_RPATHs", is(w, "bin"));

    w = mid_open(spell, &h_mid_rpath);
    check("@rpath searches the PLUGIN's LC_RPATHs first", is(w, "plugins"));

    /* Same files as the @loader_path pair, so the same handles. A loader that
     * compared the spelling instead of the resolved path would load each
     * library twice and pass every check above. */
    check("@rpath and @loader_path agree from the executable", h_exe_rpath == h_exe_loader);
    check("@rpath and @loader_path agree from the plugin", h_mid_rpath == h_mid_loader);

    /* ------------------------------------------------ @executable_path */
    snprintf(spell, sizeof spell, "@executable_path/%s", leaf);

    w = exe_open(spell, &h_exe_exec);
    check("@executable_path from the executable is bin's leaf", is(w, "bin"));

    w = mid_open(spell, &h_mid_exec);
    check("@executable_path does NOT follow the caller", is(w, "bin"));

    check("@executable_path is the same image from both", h_exe_exec == h_mid_exec);
    check("and it is the executable's own leaf", h_exe_exec == h_exe_loader);

    /* ------------------------------------------------ the absent case */
    /* A name that exists in NEITHER directory. NULL is the answer; a loader
     * that fell back to some other search path would find nothing here either,
     * but a loader that ignored the prefix entirely and tried the cwd would --
     * the cwd is tests/bin when the harness runs this. */
    check("@loader_path of an absent library is NULL",
          dlopen("@loader_path/libloader_path_absent.dylib", RTLD_LAZY) == NULL);

    printf("%s: %d failure(s)\n", failures ? "FAILED" : "PASSED", failures);
    return failures ? 1 : 0;
}
