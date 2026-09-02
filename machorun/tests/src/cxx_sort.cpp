/* cxx_sort.cpp -- the `cxx_sort` rung: std::sort actually sorts, for all five types.
 *
 * darwin/src/libcxx_std.cpp explicitly instantiates std::__sort for double,
 * float, int, long and unsigned long, because libc++ leaves those out of the
 * headers and expects them in the shipping dylib. That instantiation used to
 * forward to __sort_dispatch -- which, for exactly those types, dispatches
 * straight back into the specialisation being defined:
 *
 *     __ZNSt3__16__sortIRNS_6__lessIddEEPdEEvT0_S5_T_:
 *       2608  bl  __ZNSt3__16__sortIRNS_6__lessIddEEPdEEvT0_S5_T_   <- itself
 *
 * No comparison, no loop, no base case. Any guest that std::sorted one of
 * those types recursed until the stack died, and because a stack-overflow
 * SIGSEGV leaves the crash handler no stack to run on, machorun printed
 * nothing at all -- zero bytes of diagnostic for an infinite loop.
 *
 * WHY THIS FIXTURE SORTS RATHER THAN LINKS. The symbol existed and resolved
 * the whole time it was broken; libquartz bound to it successfully. A test
 * that checked "does std::sort link" would have passed throughout. So every
 * case here sorts real data and verifies the ORDER, and the arrays are big
 * enough and shaped badly enough to reach past introsort's insertion-sort
 * shortcut into the recursive partitioning and the heapsort fallback:
 *
 *   - 4096 elements, which is far past the 24-element insertion-sort cutoff
 *   - already ascending, already descending, all-equal, organ-pipe and
 *     sawtooth inputs, which are the shapes that drive quicksort to its
 *     worst case and force the depth-limited fall back to heapsort
 *
 * A sort that returned without doing anything would pass on the already-sorted
 * case alone, which is why that is one case out of five rather than the test.
 *
 * Deterministic by construction: the "random" input is a fixed LCG with a
 * fixed seed, so the sequence is identical on both hosts and no clock, address
 * or library RNG is involved.
 *
 * Plain arrays rather than std::vector, deliberately: vector reaches
 * std::logic_error through __throw_length_error, which this libc++ does not
 * carry, and a fixture for std::sort should not be gated on an exception class
 * it never throws.
 */
#include <algorithm>
#include <cstdio>

static unsigned lcg_state;
static void lcg_seed(unsigned s) { lcg_state = s; }
static unsigned lcg(void) { lcg_state = lcg_state * 1103515245u + 12345u; return lcg_state >> 8; }

enum Shape { ASCENDING, DESCENDING, ALL_EQUAL, ORGAN_PIPE, SAWTOOTH, RANDOM };
static const char *shape_name(Shape s)
{
    switch (s) {
    case ASCENDING:  return "ascending";
    case DESCENDING: return "descending";
    case ALL_EQUAL:  return "all-equal";
    case ORGAN_PIPE: return "organ-pipe";
    case SAWTOOTH:   return "sawtooth";
    default:         return "random";
    }
}

enum { N = 4096 };

template <class T>
static void fill(T *v, Shape shape, unsigned n)
{
    lcg_seed(12345u);
    for (unsigned i = 0; i < n; i++) {
        unsigned k;
        switch (shape) {
        case ASCENDING:  k = i;                              break;
        case DESCENDING: k = n - i;                          break;
        case ALL_EQUAL:  k = 7;                              break;
        case ORGAN_PIPE: k = (i < n / 2) ? i : (n - i);      break;
        case SAWTOOTH:   k = i % 64;                         break;
        default:         k = lcg() % 100000u;                break;
        }
        v[i] = static_cast<T>(k);
    }
}

/* Sorted, and a permutation of what went in -- checked by sum, so a sort that
 * dropped or duplicated elements while producing an ordered result would still
 * be caught. */
template <class T>
static bool check(const char *type, Shape shape, unsigned n)
{
    static T v[N];
    fill(v, shape, n);
    double before = 0;
    for (unsigned i = 0; i < n; i++) before += static_cast<double>(v[i]);

    std::sort(v, v + n);

    double after = 0;
    bool ordered = true;
    for (unsigned i = 0; i < n; i++) {
        after += static_cast<double>(v[i]);
        if (i && v[i - 1] > v[i]) ordered = false;
    }
    bool same_multiset = (before == after);
    printf("%-14s %-11s %s\n", type, shape_name(shape),
           (ordered && same_multiset) ? "sorted"
           : !ordered                 ? "NOT SORTED"
                                      : "ELEMENTS LOST");
    return ordered && same_multiset;
}

template <class T>
static int all_shapes(const char *type)
{
    int bad = 0;
    static const Shape shapes[] = { ASCENDING, DESCENDING, ALL_EQUAL,
                                    ORGAN_PIPE, SAWTOOTH, RANDOM };
    for (unsigned i = 0; i < sizeof shapes / sizeof *shapes; i++)
        if (!check<T>(type, shapes[i], N)) bad++;
    return bad;
}

int main()
{
    int bad = 0;
    bad += all_shapes<double>("double");
    bad += all_shapes<float>("float");
    bad += all_shapes<int>("int");
    bad += all_shapes<long>("long");
    bad += all_shapes<unsigned long>("unsigned long");

    /* The degenerate lengths, where an off-by-one in a base case lives. */
    {
        int v[2];
        std::sort(v, v);                                  /* empty */
        printf("empty          -           sorted\n");
        v[0] = 5; std::sort(v, v + 1);
        printf("one element    -           %s\n", v[0] == 5 ? "sorted" : "BAD");
        v[0] = 9; v[1] = 4; std::sort(v, v + 2);
        printf("two elements   -           %s\n", (v[0] == 4 && v[1] == 9) ? "sorted" : "BAD");
    }

    printf("failures=%d\n", bad);
    printf("done\n");
    return bad ? 1 : 0;
}
