/* 32_dlopen.c -- rung (ae): loading a Mach-O dylib at RUN TIME.
 *
 * Until this landed, machorun could only load what a binary's load commands
 * named. `dlopen` aborted by name, and `tests/objc44/042-dlopen` was the last
 * failure in the objc4 corpus -- 43/44 for exactly this.
 *
 * WHAT dlopen HAS TO DO BEYOND mmap, WHICH IS WHY THE PLUGIN IS SHAPED THE WAY
 * IT IS. Mapping an image is the easy part and proves almost nothing. The
 * plugin therefore carries one of each thing the rest of the sequence is for:
 *
 *   an exported function   -> the export trie must be reachable THROUGH A
 *                             HANDLE, which is a different lookup from the
 *                             flat RTLD_DEFAULT search that already worked
 *   a __mod_init_func      -> initialisers must run, and must run BEFORE
 *                             dlopen returns, or the caller sees a
 *                             half-constructed library
 *   a __thread variable    -> TLV descriptors must be set up for an image that
 *                             arrives after the process is already threaded
 *   a call into libSystem  -> a bind in the NEW image against an OLD one. This
 *                             is the ordering case: everything must be mapped
 *                             before anything is bound, exactly as at startup
 *
 * A fixture that only checked `dlopen(...) != NULL` would pass with three of
 * those four broken.
 *
 * WHY THE SECOND dlopen MATTERS. Darwin returns the SAME handle for the same
 * image and does not re-run its initialisers. An implementation that reloads
 * would produce two copies of the plugin's state, which is invisible until
 * something depends on identity -- and objc4 depends on it hard, because it
 * would register the same classes twice.
 *
 * RTLD_NOLOAD IS A QUESTION, NOT A REQUEST: "if this is already in the process
 * give me a handle, otherwise tell me so, and do not load it". Both answers are
 * checked, before and after the real load, because getting the "no" wrong is
 * how CoreFoundation ends up taking its framework-is-absent branch.
 *
 * On macOS this runs against real dyld, so every answer here is Apple's.
 *
 * TEETH, BY THREE MUTATIONS OF src/image.c, each confirmed present in the built
 * loader (source marker plus a changed md5) before the result was trusted. ONE
 * OF THEM PASSED, and that is recorded rather than quietly dropped:
 *
 *   skip mr_run_initialisers      -> FAIL on two cases: the initialiser check
 *                                    and the TLV one. Exactly the failure a
 *                                    "did dlopen return non-NULL" test misses.
 *   skip mr_objc_note_new_images  -> this fixture PASSES, correctly: it carries
 *                                    no Objective-C. tests/objc44/042-dlopen
 *                                    catches it, and catches it on machorun's
 *                                    own invariant -- "load_images before
 *                                    map_images ... a machorun ordering bug,
 *                                    not an objc4 one".
 *   apply fixups oldest-first     -> PASSES, and that is CORRECT rather than a
 *     instead of newest-first        gap. mr_image_load maps the whole
 *                                    dependency graph before mr_dlopen binds
 *                                    anything, so "everything mapped before
 *                                    anything bound" holds by construction and
 *                                    the iteration order is cosmetic. A
 *                                    mutation that passes because the property
 *                                    is not a property is not a missing test.
 */
#include <dlfcn.h>
#include <stdio.h>
#include <string.h>

static int failures;

static void check(const char *what, int ok)
{
    printf("%-44s %s\n", what, ok ? "ok" : "FAIL");
    if (!ok) failures++;
}

int main(void)
{
    const char *lib = "./lib32plug.dylib";
    void *h, *h2;
    int (*answer)(void);
    int (*tls)(void);
    int (*uses_libc)(void);

    /* Before anything: RTLD_NOLOAD must say "not loaded" rather than load it. */
    check("RTLD_NOLOAD before load is NULL", dlopen(lib, RTLD_LAZY | RTLD_NOLOAD) == NULL);

    h = dlopen(lib, RTLD_LAZY);
    check("dlopen returned a handle", h != NULL);
    if (!h) { printf("FAILED: %d failure(s)\n", ++failures); return 1; }

    /* The export trie, through the handle. dlsym takes the C name and prepends
     * the underscore itself -- a detail that is easy to get backwards, since
     * the trie stores the mangled form. */
    answer = (int (*)(void))dlsym(h, "plug_answer");
    check("dlsym found an exported function", answer != NULL);

    /* 42 only if the constructor ran: plug_state starts at 0 and the
     * initialiser sets it to 7. A mapped-but-uninitialised plugin returns 0. */
    check("initialiser ran before dlopen returned", answer && answer() == 42);

    tls = (int (*)(void))dlsym(h, "plug_tls_value");
    check("dlsym found the TLV accessor", tls != NULL);
    check("thread-local storage works in the new image", tls && tls() == 11);

    uses_libc = (int (*)(void))dlsym(h, "plug_uses_libc");
    check("dlsym found the libSystem caller", uses_libc != NULL);
    check("a bind from the NEW image into an OLD one", uses_libc && uses_libc() == 5);

    /* A symbol that is not there. NULL is the answer; anything else means the
     * lookup is falling through to some other image or to the host. */
    check("dlsym of an absent symbol is NULL", dlsym(h, "plug_no_such_symbol") == NULL);

    /* Now RTLD_NOLOAD must say yes, and with the SAME handle. */
    h2 = dlopen(lib, RTLD_LAZY | RTLD_NOLOAD);
    check("RTLD_NOLOAD after load returns a handle", h2 != NULL);
    check("RTLD_NOLOAD returns the SAME handle", h2 == h);

    /* And a second real dlopen is also the same handle, with no second run of
     * the initialiser -- if it re-ran, plug_state would be set again, which is
     * not observable, so identity is what this checks. */
    h2 = dlopen(lib, RTLD_LAZY);
    check("re-dlopen returns the SAME handle", h2 == h);

    /* dlopen(NULL) is "a handle for the main program" on Darwin. */
    check("dlopen(NULL) returns a handle", dlopen(NULL, RTLD_LAZY) != NULL);

    /* Darwin's dlclose returns 0 for a real handle. It does NOT promise the
     * code went away, and nothing here checks that it did. */
    check("dlclose(handle) returns 0", dlclose(h) == 0);
    check("dlclose(NULL) is non-zero", dlclose(NULL) != 0);

    printf("%s: %d failure(s)\n", failures ? "FAILED" : "PASSED", failures);
    return failures ? 1 : 0;
}
