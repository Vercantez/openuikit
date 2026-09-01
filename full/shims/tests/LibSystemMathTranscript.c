#include <float.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>

typedef union {
    double value;
    uint64_t bits;
} test_double_bits;

static double (*volatile call_nan)(const char *) = nan;
static double (*volatile call_remquo)(double, double, int *) = remquo;

static double from_bits(uint64_t bits)
{
    test_double_bits value = { .bits = bits };
    return value.value;
}

static uint64_t to_bits(double value)
{
    test_double_bits result = { .value = value };
    return result.bits;
}

static void emit_nan(const char *label, const char *tag)
{
    printf("nan\t%s\t%016llx\n", label,
           (unsigned long long)to_bits(call_nan(tag)));
}

static void emit_remquo(const char *label, double x, double y)
{
    int quotient = 999;
    double remainder = call_remquo(x, y, &quotient);
    printf("remquo\t%s\t%016llx\t%d\n", label,
           (unsigned long long)to_bits(remainder), quotient);
}

static uint64_t next_bits(uint64_t *state)
{
    uint64_t value = *state;
    value ^= value << 13;
    value ^= value >> 7;
    value ^= value << 17;
    *state = value;
    return value;
}

int main(void)
{
    emit_nan("empty", "");
    emit_nan("zero", "0");
    emit_nan("decimal", "42");
    emit_nan("octal", "010");
    emit_nan("hex", "0x42");
    emit_nan("maximum", "18446744073709551615");
    emit_nan("overflow", "18446744073709551616");
    emit_nan("signed-rejected", "+1");
    emit_nan("trailing-rejected", "1 ");
    emit_nan("invalid-octal", "08");

    emit_remquo("nearest-even-up", 7.0, 2.0);
    emit_remquo("nearest-even-down", 5.0, 2.0);
    emit_remquo("half-even", 3.0, 2.0);
    emit_remquo("negative-x", -7.0, 2.0);
    emit_remquo("negative-y", 7.0, -2.0);
    emit_remquo("both-negative", -7.0, -2.0);
    emit_remquo("seven-bit-mask", 257.0, 1.0);
    emit_remquo("seven-bit-high", 255.0, 1.0);
    emit_remquo("signed-zero", -0.0, 3.0);
    emit_remquo("infinite-divisor", 2.0, INFINITY);
    emit_remquo("subnormal", from_bits(UINT64_C(3)),
                from_bits(UINT64_C(2)));
    emit_remquo("extreme-ratio", DBL_MAX, from_bits(UINT64_C(1)));

    /* Broad deterministic exponent/sign/significand coverage. Clearing one
     * exponent bit keeps both operands finite; a zero divisor is replaced by
     * the smallest positive subnormal. */
    uint64_t state = UINT64_C(0x6d61746870617463);
    for (unsigned index = 0; index < 128; index++) {
        uint64_t x_bits = next_bits(&state) & UINT64_C(0xffefffffffffffff);
        uint64_t y_bits = next_bits(&state) & UINT64_C(0xffefffffffffffff);
        char label[24];
        if ((y_bits << 1) == 0) y_bits = 1;
        snprintf(label, sizeof label, "matrix-%03u", index);
        emit_remquo(label, from_bits(x_bits), from_bits(y_bits));
    }
    return 0;
}
