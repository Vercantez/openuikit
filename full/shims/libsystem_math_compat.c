/*
 * Two C99 libm entry points advertised by Apple's iOS SDK but absent from
 * machorun's deliberately small libSystem implementation.  OpenCoreGraphics'
 * CGFloat tgmath surface calls these exact C symbols, so they belong in the
 * project-owned libSystem umbrella beside syspatch.c rather than in a Swift
 * framework.
 *
 * The implementations do not call a host libm.  remquo performs an integer
 * significand reduction, which preserves the required quotient bits even when
 * x/y would overflow.  Darwin returns the low seven signed quotient bits.  nan
 * accepts the same unsigned integer-constant tags measured on Apple libSystem
 * (decimal, leading-zero octal, or 0x hexadecimal), rejecting signs,
 * whitespace, trailing text, and overflow.
 */

#include <limits.h>
#include <stdint.h>

typedef union {
    double value;
    uint64_t bits;
} openui_double_bits;

static double openui_quiet_nan(uint64_t payload)
{
    openui_double_bits result = {
        .bits = UINT64_C(0x7ff8000000000000)
            | (payload & UINT64_C(0x0007ffffffffffff))
    };
    return result.value;
}

static int openui_nan_digit(unsigned char byte)
{
    if (byte >= '0' && byte <= '9') return (int)(byte - '0');
    if (byte >= 'a' && byte <= 'f') return (int)(byte - 'a') + 10;
    if (byte >= 'A' && byte <= 'F') return (int)(byte - 'A') + 10;
    return -1;
}

static int openui_nan_payload(const char *tag, uint64_t *payload)
{
    const unsigned char *cursor = (const unsigned char *)tag;
    unsigned base = 10;
    uint64_t value = 0;
    int digits = 0;

    if (!cursor || !*cursor) return 0;
    if (cursor[0] == '0') {
        if (cursor[1] == 'x' || cursor[1] == 'X') {
            base = 16;
            cursor += 2;
        } else {
            base = 8;
        }
    }

    for (; *cursor; cursor++) {
        int digit = openui_nan_digit(*cursor);
        if (digit < 0 || (unsigned)digit >= base) return 0;
        if (value > (UINT64_MAX - (uint64_t)digit) / base) return 0;
        value = value * base + (uint64_t)digit;
        digits++;
    }
    if (!digits) return 0;
    *payload = value;
    return 1;
}

double openui_libsystem_nan(const char *tag) __asm__("_nan");
double openui_libsystem_nan(const char *tag)
{
    uint64_t payload = 0;
    (void)openui_nan_payload(tag, &payload);
    return openui_quiet_nan(payload);
}

double openui_libsystem_remquo(double x, double y, int *quotient)
    __asm__("_remquo");
double openui_libsystem_remquo(double x, double y, int *quotient)
{
    openui_double_bits ux = { .value = x };
    openui_double_bits uy = { .value = y };
    int exponent_x = (int)((ux.bits >> 52) & UINT64_C(0x7ff));
    int exponent_y = (int)((uy.bits >> 52) & UINT64_C(0x7ff));
    int sign_x = (int)(ux.bits >> 63);
    int sign_y = (int)(uy.bits >> 63);
    uint64_t significand_x = ux.bits;
    uint64_t difference;
    uint64_t scan;
    uint32_t quotient_bits = 0;

    *quotient = 0;
    if ((uy.bits << 1) == 0
        || (exponent_y == 0x7ff
            && (uy.bits & UINT64_C(0x000fffffffffffff)) != 0)
        || exponent_x == 0x7ff) {
        return openui_quiet_nan(0);
    }
    if ((ux.bits << 1) == 0) return x;

    /* Normalize both magnitudes to an explicit 53-bit significand. */
    if (!exponent_x) {
        for (scan = significand_x << 12; (scan >> 63) == 0;
             exponent_x--, scan <<= 1) {}
        significand_x <<= -exponent_x + 1;
    } else {
        significand_x &= UINT64_C(0x000fffffffffffff);
        significand_x |= UINT64_C(1) << 52;
    }
    if (!exponent_y) {
        for (scan = uy.bits << 12; (scan >> 63) == 0;
             exponent_y--, scan <<= 1) {}
        uy.bits <<= -exponent_y + 1;
    } else {
        uy.bits &= UINT64_C(0x000fffffffffffff);
        uy.bits |= UINT64_C(1) << 52;
    }

    if (exponent_x < exponent_y) {
        if (exponent_x + 1 == exponent_y) goto choose_nearest;
        return x;
    }

    /* Binary long division.  uint32_t wrap retains far more than Darwin's
     * seven observable quotient bits, including for enormous ratios. */
    for (; exponent_x > exponent_y; exponent_x--) {
        difference = significand_x - uy.bits;
        if ((difference >> 63) == 0) {
            significand_x = difference;
            quotient_bits++;
        }
        significand_x <<= 1;
        quotient_bits <<= 1;
    }
    difference = significand_x - uy.bits;
    if ((difference >> 63) == 0) {
        significand_x = difference;
        quotient_bits++;
    }
    if (significand_x == 0) {
        exponent_x = -60;
    } else {
        while ((significand_x >> 52) == 0) {
            significand_x <<= 1;
            exponent_x--;
        }
    }

choose_nearest:
    if (exponent_x > 0) {
        significand_x -= UINT64_C(1) << 52;
        significand_x |= (uint64_t)exponent_x << 52;
    } else {
        significand_x >>= -exponent_x + 1;
    }
    ux.bits = significand_x;
    x = ux.value;
    if (sign_y) y = -y;

    /* IEEE remainder chooses the nearest integer quotient, ties to even. */
    if (exponent_x == exponent_y
        || (exponent_x + 1 == exponent_y
            && (2 * x > y
                || (2 * x == y && (quotient_bits & 1) != 0)))) {
        x -= y;
        quotient_bits++;
    }

    quotient_bits &= 0x7f;
    *quotient = sign_x ^ sign_y
        ? -(int)quotient_bits
        : (int)quotient_bits;
    return sign_x ? -x : x;
}
