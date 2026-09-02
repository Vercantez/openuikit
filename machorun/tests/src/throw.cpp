/* throw.cpp -- the `throw` rung: a C++ exception that really is thrown, really
 * crosses frames, and really is caught by type.
 *
 * THE BAR FOR THIS RUNG WAS SET BY WHAT THE PREVIOUS ONES MISSED. the `unwind` rung
 * proved the UNWINDER decodes Apple's compact __unwind_info; it says nothing
 * about throwing, because walking a stack and unwinding one are different
 * jobs. __cxa_throw allocates an exception and calls _Unwind_RaiseException;
 * __gxx_personality_v0 then decides AT EACH FRAME whether a handler matches,
 * by parsing that frame's LSDA and comparing type_info. A fixture that merely
 * links, or that throws and catches inside one function, exercises none of it.
 *
 * So every case here throws across at least one frame boundary, and the
 * interesting ones are about SELECTION rather than success:
 *
 *   - catch by exact type, with an intermediate frame in between
 *   - catch by BASE class when a derived is thrown, which needs
 *     private_typeinfo's hierarchy walk rather than a pointer compare
 *   - NOT catching a non-matching type, so it passes through a handler that
 *     does not apply and is caught further out. A personality routine that
 *     said "yes" to everything would pass every other case here and fail this
 *     one, which is why it is the case that matters most.
 *   - destructors running during unwinding, in the right order, which is the
 *     cleanup path (_UA_CLEANUP_PHASE) rather than the handler path
 *   - rethrow from inside a catch, which reuses the in-flight exception object
 *   - std::exception's what(), i.e. the vtable survived the trip
 *
 * WHY THE COUNTS AND THE ORDER STRING ARE PRINTED. "It did not crash" is not
 * evidence: an unwinder that skips cleanup frames still delivers the exception
 * to the right handler and looks perfect. The destructor ORDER is the part
 * that catches a cleanup phase that runs frames in the wrong sequence, and the
 * count catches one that skips them entirely.
 *
 * On macOS this runs against Apple's own libc++abi, so the oracle is Apple's
 * answer to every one of these questions.
 */
#include <cstdio>
#include <cstring>
#include <exception>
#include <stdexcept>

static int failures;
static char order[64];
static int  order_n;

static void note(char c)
{
    if (order_n < (int)sizeof(order) - 1) order[order_n++] = c;
}

static void check(const char *what, bool ok)
{
    std::printf("%-46s %s\n", what, ok ? "ok" : "FAIL");
    if (!ok) failures++;
}

/* ---- the types thrown ------------------------------------------------- */
struct Base { virtual ~Base() {} virtual int tag() const { return 1; } };
struct Derived : Base { int tag() const override { return 2; } };
struct Unrelated { int x = 7; };

/* A destructor that records that it ran. Objects of this type live in frames
 * the exception passes THROUGH, so they only run if the cleanup phase visits
 * those frames. */
struct Marker {
    char c;
    explicit Marker(char ch) : c(ch) {}
    ~Marker() { note(c); }
};

/* ---- frame chains ------------------------------------------------------ */
__attribute__((noinline)) static void throw_derived() { throw Derived(); }
__attribute__((noinline)) static void middle_derived() { Marker m('m'); throw_derived(); }
__attribute__((noinline)) static void outer_derived()  { Marker m('o'); middle_derived(); }

__attribute__((noinline)) static void throw_unrelated() { throw Unrelated(); }

/* A frame with a catch that does NOT match. The exception must pass through
 * it -- and its Marker must still run. */
__attribute__((noinline)) static void non_matching_handler()
{
    Marker m('n');
    try {
        throw_unrelated();
    } catch (const std::runtime_error &) {
        note('X');                 /* must never happen */
        failures++;
    }
}

__attribute__((noinline)) static void throw_runtime_error()
{
    throw std::runtime_error("the message");
}

__attribute__((noinline)) static void rethrower()
{
    try {
        throw_derived();
    } catch (const Base &) {
        note('r');
        throw;                     /* reuse the in-flight exception */
    }
}

int main()
{
    /* --- exact type, across two intermediate frames ------------------- */
    order_n = 0;
    try {
        outer_derived();
        check("throw Derived, caught", false);
    } catch (const Derived &d) {
        check("throw Derived, caught by exact type", d.tag() == 2);
    } catch (...) {
        check("throw Derived, caught by exact type", false);
    }
    order[order_n] = 0;
    /* Innermost frame's destructor first: middle before outer. */
    check("destructors ran, innermost first", std::strcmp(order, "mo") == 0);
    if (std::strcmp(order, "mo") != 0)
        std::printf("   destructor order was \"%s\", expected \"mo\"\n", order);

    /* --- base-class catch, which needs the type_info hierarchy walk ---- */
    try {
        throw_derived();
        check("throw Derived, caught as Base &", false);
    } catch (const Base &b) {
        check("throw Derived, caught as Base &", b.tag() == 2);
    } catch (...) {
        check("throw Derived, caught as Base &", false);
    }

    /* --- THE ONE THAT MATTERS: a handler that must NOT match ----------- */
    order_n = 0;
    try {
        non_matching_handler();
        check("unmatched handler was skipped", false);
    } catch (const Unrelated &u) {
        check("unmatched handler was skipped", u.x == 7);
    } catch (...) {
        check("unmatched handler was skipped", false);
    }
    order[order_n] = 0;
    check("passed-through frame still cleaned up", std::strcmp(order, "n") == 0);
    if (std::strcmp(order, "n") != 0)
        std::printf("   cleanup record was \"%s\", expected \"n\"\n", order);

    /* --- the standard hierarchy, and a vtable that survived ------------ */
    try {
        throw_runtime_error();
        check("std::runtime_error caught as std::exception", false);
    } catch (const std::exception &e) {
        check("std::runtime_error caught as std::exception",
              std::strcmp(e.what(), "the message") == 0);
    } catch (...) {
        check("std::runtime_error caught as std::exception", false);
    }

    /* --- rethrow reuses the in-flight exception ------------------------ */
    order_n = 0;
    try {
        rethrower();
        check("rethrow reached the outer handler", false);
    } catch (const Derived &d) {
        check("rethrow reached the outer handler", d.tag() == 2);
    } catch (...) {
        check("rethrow reached the outer handler", false);
    }
    order[order_n] = 0;
    check("inner handler ran before the rethrow", std::strcmp(order, "r") == 0);

    /* --- catch(...) after everything else --------------------------- */
    try {
        throw 42;
        check("catch(...) caught a scalar", false);
    } catch (const std::exception &) {
        check("catch(...) caught a scalar", false);
    } catch (...) {
        check("catch(...) caught a scalar", true);
    }

    /* --- nothing is in flight once we are back out --------------------- */
    check("no exception in flight at the end", std::current_exception() == nullptr);

    std::printf("%s: %d failure(s)\n", failures ? "FAILED" : "PASSED", failures);
    return failures ? 1 : 0;
}
