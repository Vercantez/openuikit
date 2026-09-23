/* dispatch_once_block.c -- the `dispatch_once_block` rung: dispatch_once, the
 * block form of dispatch_once_f, as Objective-C singletons call it (FMDB's
 * +FMDBVersion, NetNewsWire's NSString+RSDatabase caches). The block runs
 * exactly once per token, a once nested on another token inside the block
 * does not deadlock. (The token's final value is not printed: macOS 26
 * leaves something other than ~0l there, measured, and machorun's ~0l is
 * its own contract with libswiftCore's inlined swift_once fast path.) */
#include <dispatch/dispatch.h>
#include <stdio.h>

static int outer_runs, inner_runs;

static void run_inner(void)
{
    static dispatch_once_t inner;
    dispatch_once(&inner, ^{ inner_runs++; });
}

int main(void)
{
    static dispatch_once_t outer;
    __block int captured = 41;
    for (int i = 0; i < 3; i++) {
        dispatch_once(&outer, ^{
            outer_runs++;
            captured++;           /* a __block capture the block writes */
            run_inner();
        });
        run_inner();
    }
    printf("outer runs=%d inner runs=%d captured-in-block=%d\n", outer_runs, inner_runs, captured);
    return 0;
}
