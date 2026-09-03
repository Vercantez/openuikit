/* fmal.c -- Darwin long-double fused multiply-add.
 *
 * Swift's x86_64 Float80.addProduct / addingProduct calls fmal. Darwin x86_64
 * long double is 16-byte x87 (same as glibc); Darwin arm64 long double IS
 * double (8 bytes) while Linux aarch64 is binary128, so arm64 must NOT
 * host-bind glibc's fmal. Both arches export fmal from libSystem: x86
 * forwards to glibc_fmal, arm64 implements as fma(double).
 *
 * WHAT THIS GRADES:
 *   fmal(1.5, 2.0, 3.0) == 6     IEEE, both arches, both oracles.
 *   sizeof(long double)          16 on x86_64, 8 on arm64.
 *   ld80_bit_survives            1.0 + 2^-63 is exact in 80-bit and lost in
 *                                binary64. The arch split, not a bug.
 *
 * Operator: tests/build_fixtures.sh fmal && harness/run_macos.sh --record fmal
 * (built -fno-builtin so the call actually hits libSystem rather than a
 * compiler intrinsic), then flip the manifest oracle cell to `run`.
 */
#include <math.h>
#include <stdio.h>

int main(void)
{
    long double r = fmal(1.5L, 2.0L, 3.0L);
    long double tiny = fmal(1.0L, 1.0L, 0x1p-63L);

    printf("sizeof_ld               %d\n", (int)sizeof(long double));
    printf("fmal_1.5_2.0_3.0        %.0Lf\n", r);
    printf("fmal_exact_6            %s\n", r == 6.0L ? "yes" : "NO");
    printf("ld80_bit_survives       %s\n", tiny != 1.0L ? "yes" : "no");
    puts("done");
    return 0;
}
