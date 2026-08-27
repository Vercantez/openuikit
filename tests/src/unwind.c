/* unwind.c -- the `unwind` rung: unwinding a real stack through Apple's compact
 * __TEXT,__unwind_info.
 *
 * THIS WALKS, IT DOES NOT LINK. Every unwind symbol in machorun resolved
 * perfectly for as long as the unwinder was a set of aborting stubs, so a link
 * test would have passed throughout -- the same trap that hid the std::__sort
 * recursion, where the symbol was present and the body was an infinite loop.
 * What has to be proved is that the compact-unwind DECODER produces the right
 * answer for a real frame, and the only way to know that is to walk a stack
 * whose shape you already know and check every level.
 *
 * WHAT THE macOS ORACLE TAUGHT ME, AND WHY THE OBVIOUS TEST IS WRONG. The
 * first version of this fixture matched each frame by calling
 * _Unwind_FindEnclosingFunction and comparing against &level1 / &level2 /
 * &level3. It failed ON macOS, against Apple's own libunwind, naming none of
 * the three -- and Apple was right. COMPACT UNWIND COMPRESSES: consecutive
 * functions whose 32-bit encodings are identical share a single entry, so the
 * `start_ip` it reports is the start of the RUN, not of the function. Three
 * adjacent one-line functions are exactly the case that merges. So
 * _Unwind_FindEnclosingFunction is not a function-identity oracle at all, and
 * a test built on that assumption tests the wrong thing on every platform.
 *
 * What replaces it is exact and immune to merging: each level records its own
 * __builtin_return_address(0) on the way down, and the walk must report those
 * same addresses on the way out. Comparing the unwinder against the compiler's
 * own idea of the return address is a stronger check than any name -- an
 * unwinder that lands one frame off, or restores the wrong saved x30, fails it
 * immediately, and there is no way to pass it by accident.
 *
 * TEETH DEMONSTRATED BY TWO MUTATIONS OF src/unwind.c, both with the defect
 * confirmed present in the built loader (source marker plus a changed md5)
 * before the result was trusted -- a mutant that did not take reads exactly
 * like a fixture with no teeth:
 *
 *   drop the image slide          -> SIGSEGV at 0x12f74, an unslid section
 *                                    address, named by the crash reporter
 *   swap the two sections         -> exit 1, no crash, three named failures:
 *                                    the enclosing-function probe, "TOO FEW"
 *                                    frames, and the return-address check
 *
 * The second matters more than the first. A wrong answer that does not crash
 * is the failure mode this rung exists for.
 *
 * WHY THIS IS A HARD TEST AND NOT A SMOKE TEST. Apple's binaries carry no
 * .eh_frame. `__TEXT,__unwind_info` is a compressed two-level page table whose
 * leaves are 32-bit encodings of a frame's shape -- for arm64, frameless with a
 * stack size, frame-based with a saved-register mask, or a DWARF escape. To
 * name `level1` as the caller of `level2`, libunwind has to find the right
 * second-level page by binary search, decode the encoding, work out where x29
 * and x30 were spilled, and restore them. Getting the page lookup or the
 * register mask wrong still produces AN answer, just the wrong frame -- which
 * is why this compares against known function addresses rather than merely
 * counting frames or checking for non-NULL.
 *
 * THE off-by-one IS DELIBERATE AND IS THE POINT OF `ip - 1`. _Unwind_GetIP
 * returns a RETURN address: the instruction after the call. When the call is
 * the last instruction of a function -- every tail call, and every call to a
 * noreturn function -- that address belongs to the NEXT function, and the
 * lookup names the wrong one. libunwind's own _Unwind_FindEnclosingFunction
 * does not adjust, so the caller must. machorun's crash reporter had exactly
 * this bug and reported an mr_bail's caller as the symbol after it.
 *
 * The loader's half is `_dyld_find_unwind_sections` (src/unwind.c): libunwind
 * can decode the section but only dyld knows where it is. If that returns the
 * wrong image or forgets the slide, every frame here fails at once.
 *
 * Output is names and booleans, never addresses, so the two platforms are
 * comparable: the SAME binary runs on macOS and under machorun, so every
 * function offset is identical and only the load address differs.
 */
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <unwind.h>

/* uintptr_t rather than _Unwind_Word / _Unwind_Ptr: those are LLVM's and
 * libgcc's spellings, and Apple's own <unwind.h> declares _Unwind_GetIP and
 * _Unwind_GetCFA as returning uintptr_t with no such typedefs. The fixture has
 * to compile against APPLE's header, because it is built on macOS with the
 * real SDK -- that is what makes it an oracle. */

/* The return address each level was entered with, captured on the way DOWN by
 * the compiler. ra[0] is the address in level3 that walk() returns to, ra[1]
 * the address in level2 that level3 returns to, ra[2] the one in level1.
 *
 * The unwinder must produce exactly these, in this order, starting at frame 1
 * (frame 0 being walk itself). */
#define NEXPECTED 3
static const void *ra[NEXPECTED];
static const char *const ra_name[NEXPECTED] = {
    "level3 (walk's caller)", "level2 (level3's caller)", "level1 (level2's caller)"
};

/* The chain to walk. noinline so the frames really exist; the `sink` write
 * stops clang turning any of them into a tail call, which would collapse the
 * very frames under test. */
volatile int sink;

__attribute__((noinline)) static void walk(void);

__attribute__((noinline)) static void level3(void)
{ sink = 3; ra[1] = __builtin_return_address(0); walk();   sink = 33; }
__attribute__((noinline)) static void level2(void)
{ sink = 2; ra[2] = __builtin_return_address(0); level3(); sink = 22; }
__attribute__((noinline)) static void level1(void) { sink = 1; level2(); sink = 11; }

static int frame;          /* how many frames _Unwind_Backtrace has given us */
static int matched;        /* how many of the expected three we recognised */
static int failures;
static uintptr_t prev_cfa;
static int cfa_monotonic = 1;

static _Unwind_Reason_Code visit(struct _Unwind_Context *ctx, void *arg)
{
    uintptr_t ip  = (uintptr_t)_Unwind_GetIP(ctx);
    uintptr_t cfa = (uintptr_t)_Unwind_GetCFA(ctx);
    void *start;

    (void)arg;

    if (!ip) return _URC_END_OF_STACK;

    /* The stack grows down, so unwinding outward must see the canonical frame
     * address strictly INCREASE. A decoder that mis-reads a frame's size
     * usually still yields a plausible-looking pc while breaking this, so it
     * catches a whole class of wrong answers that a name check alone does
     * not. Frame 0 has nothing to compare against. */
    if (frame > 0 && cfa <= prev_cfa) cfa_monotonic = 0;
    prev_cfa = cfa;

    /* Frame 0 is walk() itself and has no recorded counterpart. Frames 1..3
     * must be exactly the return addresses the compiler handed each level. */
    if (frame >= 1 && frame <= NEXPECTED) {
        const void *want = ra[frame - 1];
        int ok = ((const void *)ip == want);
        printf("frame %d return address is %-26s %s\n",
               frame, ra_name[frame - 1], ok ? "as recorded" : "WRONG");
        if (ok) matched++; else failures++;
    }

    /* Whatever the enclosing-function lookup reports, it must be inside the
     * image and at or below the address asked about. That is the invariant
     * that survives compact unwind's entry merging; equality does not. */
    start = _Unwind_FindEnclosingFunction((void *)(ip - (frame ? 1 : 0)));
    if (frame >= 1 && frame <= NEXPECTED && (start == 0 || (uintptr_t)start > ip)) {
        printf("FAIL frame %d: enclosing function 0x%llx is not at or below ip\n",
               frame, (unsigned long long)(uintptr_t)start);
        failures++;
    }

    frame++;
    /* Stop once we have seen all three plus a few more; walking into the
     * loader's ELF frames is not part of this test and the two platforms
     * genuinely differ there. */
    return (matched == NEXPECTED) ? _URC_END_OF_STACK : _URC_NO_REASON;
}

/* noinline, and that is load-bearing rather than tidy. `walk` is static and
 * called exactly once, so at -O1 clang inlines it into level3 -- and then
 * walk's __builtin_return_address(0) IS level3's, two levels record the same
 * address, and the frames under test shift by one. MEASURED: ra[0] and ra[1]
 * came back identical, which is impossible unless a frame vanished. Every
 * function in this chain has to be pinned or the fixture quietly tests a
 * shorter stack than it claims. */
__attribute__((noinline)) static void walk(void)
{
    _Unwind_Reason_Code rc;

    ra[0] = __builtin_return_address(0);
    rc = _Unwind_Backtrace(visit, 0);

    /* _URC_END_OF_STACK is what our own callback returns to stop early; on
     * both platforms _Unwind_Backtrace turns that into _URC_END_OF_STACK. */
    if (rc != _URC_END_OF_STACK && rc != _URC_NO_REASON) {
        printf("FAIL _Unwind_Backtrace returned %d\n", (int)rc);
        failures++;
    }
}

int main(void)
{
    /* The narrowest possible check of the section lookup, before any walking:
     * if _dyld_find_unwind_sections names the wrong image or drops the slide,
     * this fails on its own and every frame result below is noise. It asks
     * only that SOME entry covers a known function address and starts at or
     * below it -- not that it starts exactly there, because of merging. */
    void *self = _Unwind_FindEnclosingFunction((void *)(void (*)(void))level1);
    printf("enclosing(level1) covers it: %s\n",
           (self != 0 && (uintptr_t)self <= (uintptr_t)(void *)level1) ? "yes" : "no");
    if (self == 0 || (uintptr_t)self > (uintptr_t)(void *)level1) failures++;

    /* An address that is in no function at all. NULL is the honest answer and
     * a decoder that returns something anyway is guessing. */
    printf("enclosing(NULL) is NULL:     %s\n",
           _Unwind_FindEnclosingFunction(0) == 0 ? "yes" : "no");
    if (_Unwind_FindEnclosingFunction(0) != 0) failures++;

    level1();

    printf("frames walked:               %s\n", frame >= NEXPECTED + 1 ? "enough" : "TOO FEW");
    if (frame < NEXPECTED + 1) failures++;

    printf("all %d return addresses match: %s\n", NEXPECTED, matched == NEXPECTED ? "yes" : "no");
    if (matched != NEXPECTED) failures++;

    /* NOT THE TELL, and labelled so nobody has to rediscover why it never
     * fires. Demonstrated by mutation: with the loader reporting the two
     * sections the wrong way round, the walk stops at frame 0 and this check
     * has nothing to compare, so it reports "yes" on a build where three other
     * checks report failure. It earns its place for the opposite case -- a
     * decoder that produces plausible pcs while mis-reading frame sizes -- and
     * it is kept rather than deleted for that, not for this one. */
    printf("CFA strictly increasing:     %s\n", cfa_monotonic ? "yes" : "no");
    if (!cfa_monotonic) failures++;

    printf("%s: %d failure(s)\n", failures ? "FAILED" : "PASSED", failures);
    return failures ? 1 : 0;
}
