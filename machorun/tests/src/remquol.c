/* remquol.c -- Darwin long-double remquo, same arch split as fmal.
 *
 * Darwin x86_64 long double is 16-byte x87 (glibc remquol). Darwin arm64
 * long double IS double; Linux aarch64 remquol is binary128, so arm64
 * implements remquol as remquo(double).
 *
 * Operator: tests/build_fixtures.sh remquol &&
 * harness/run_macos.sh --record remquol, then flip the manifest cell to `run`.
 * Built -fno-builtin so the guest actually imports _remquol.
 */
#include <math.h>
#include <stdio.h>

int main(void)
{
    int q = -1;
    long double r = remquol(13.0L, 4.0L, &q);

    printf("sizeof_ld               %d\n", (int)sizeof(long double));
    printf("remquol_13_4            %.1Lf\n", r);
    printf("quo                     %d\n", q);
    printf("ld80_bit_survives       %s\n",
           (1.0L + 0x1p-63L) != 1.0L ? "yes" : "no");
    puts("done");
    return 0;
}
