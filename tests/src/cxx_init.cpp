/* cxx_init -- the `cxx_init` rung, C++ half: real static initialisers.
 *
 * A namespace-scope object with a non-trivial constructor and destructor.
 * clang emits a __mod_init_func entry calling _GLOBAL__sub_I_..., which
 * constructs the object and registers the destructor with __cxa_atexit
 * (passing &__dso_handle). This additionally drags in libc++ and
 * libc++abi, so the fixture is also a three-image dependency test.
 *
 * Loader must implement: __mod_init_func, __cxa_atexit / __cxa_finalize,
 * __dso_handle per image, and the C++ ABI's guard variables for the
 * function-local static.
 */
#include <cstdio>
#include <string>

struct Tracer {
    const char *name;
    explicit Tracer(const char *n) : name(n) { std::printf("ctor %s\n", name); }
    ~Tracer() { std::printf("dtor %s\n", name); std::fflush(stdout); }
};

static Tracer g_a("a");
static Tracer g_b("b");

static int counted() {
    static int n = 41; /* guarded function-local static */
    return ++n;
}

int main() {
    std::printf("main\n");
    std::printf("local-static=%d\n", counted());
    std::string s = "std::string works";
    std::printf("%s len=%zu\n", s.c_str(), s.size());
    return 0;
}
