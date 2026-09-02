/* The middle image: a dylib that lives in a DIFFERENT DIRECTORY from the
 * executable and dlopens things from there.
 *
 * It exists only so that "the image that called dlopen" and "the main
 * executable" are two different answers. Every @-prefixed spelling the
 * executable tries, it tries too, with the identical string -- so the fixture
 * compares answers rather than checking one side in isolation.
 *
 * Its own LC_RPATH is @loader_path, which is this directory. The executable's
 * first LC_RPATH is @loader_path too, which is a different directory. So even
 * @rpath, which does not mention @loader_path at the call site, comes out
 * differently depending on whose LC_RPATHs are searched first.
 */
#include <dlfcn.h>

/* Returns the identity string of whatever leaf it opened, or NULL, and hands
 * back the handle so the caller can compare identities. */
const char *mid_open(const char *path, void **handle_out);
const char *mid_open(const char *path, void **handle_out)
{
    const char *(*where)(void);
    void *h = dlopen(path, RTLD_LAZY);

    if (handle_out) *handle_out = h;
    if (!h) return 0;
    where = (const char *(*)(void))dlsym(h, "leaf_where");
    return where ? where() : 0;
}
