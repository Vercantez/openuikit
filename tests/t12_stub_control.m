/* POSITIVE CONTROL FOR THE STUB MECHANISM.
 *
 * T9 and T10 pass, and none of the allocator stubs printed its name — from
 * which it follows that CFBase.c:109's Darwin zone allocator and
 * CFUtilities.c's Mach VM paths are never reached on anything we exercise.
 *
 * THAT INFERENCE IS ONLY WORTH ANYTHING IF THE ABORT ACTUALLY WORKS. An absence
 * of evidence is evidence of absence exactly when the detector is known to
 * fire, and not otherwise. A stub library that silently returned, or whose
 * message was swallowed by buffering — which is precisely what happened on the
 * first run of the init-wall probe, where printf's buffer was discarded by
 * abort() and the harness reported nothing at all — would produce the same
 * clean output for the opposite reason.
 *
 * So this deliberately calls one stubbed symbol and expects to die naming it.
 *
 * EXPECTED RESULT: killed by SIGABRT, with
 *
 *     STUB CALLED: malloc_zone_memalign
 *
 * on stderr. A clean exit here means the stubs are NOT loud, and every "the
 * allocator is unreached" claim resting on them is void.
 *
 * malloc_zone_memalign is chosen because it is one of the three allocator/VM
 * symbols actually stubbed today (with mach_vm_region and vm_purgable_control),
 * so the control exercises the same mechanism as the claim it supports rather
 * than a nearby one.
 */
#include <stdio.h>

extern void *malloc_zone_memalign(void *zone, unsigned long align, unsigned long size);

int main(void)
{
    fprintf(stderr, "T12: about to call a stubbed allocator symbol on purpose.\n");
    fprintf(stderr, "T12: expecting 'STUB CALLED: malloc_zone_memalign' and SIGABRT.\n");
    fflush(stderr);

    void *p = malloc_zone_memalign((void *)0, 16, 64);

    /* Unreachable if the stubs work. Reaching it is the failure. */
    fprintf(stderr, "T12 FAIL: the stub RETURNED (%p) instead of aborting.\n"
                    "  Every 'not reached' conclusion drawn from these stubs is void:\n"
                    "  a silent stub and an untaken branch look identical.\n", p);
    fflush(stderr);
    return 1;
}
