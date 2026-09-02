/* The second route to the leaf. Its LC_LOAD_DYLIB string is rewritten by
 * build_fixtures.sh to name the ALIAS path, so the loader's string test cannot
 * short-circuit and the FILE-identity question is the one actually asked. */
#define CAT2(a, b) a##b
#define CAT(a, b) CAT2(a, b)
extern int *CAT(CAT(dup_, DUP_KIND), _token)(void);
int *CAT(CAT(dup_, DUP_KIND), _mid_token)(void) { return CAT(CAT(dup_, DUP_KIND), _token)(); }
