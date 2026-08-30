// Project-owned runtime probe for the raw Darwin UUID substrate used by
// FoundationEssentials. This is linked only into the Focus guest executable;
// the implementation under test remains in libFoundationEssentials.dylib.

#include <stdint.h>
#include <string.h>
#include <uuid/uuid.h>

static int has_version_and_variant(const uuid_t value, uint8_t version) {
    return (value[6] >> 4) == version && (value[8] & 0xc0) == 0x80;
}

int open_focus_uuid_compat_probe(void) {
    static const char lower[] = "00112233-4455-6677-8899-aabbccddeeff";
    static const char upper[] = "00112233-4455-6677-8899-AABBCCDDEEFF";
    uuid_t value;
    uuid_t copy;
    uuid_string_t text;

    uuid_clear(value);
    if (!uuid_is_null(value)) return 1;
    if (uuid_parse(lower, value) != 0 || uuid_is_null(value)) return 2;
    if (value[0] != 0x00 || value[7] != 0x77 || value[15] != 0xff) return 3;

    uuid_unparse_lower(value, text);
    if (strcmp(text, lower) != 0) return 4;
    uuid_unparse_upper(value, text);
    if (strcmp(text, upper) != 0) return 5;
    uuid_unparse(value, text);
    if (strcmp(text, upper) != 0) return 6;

    uuid_copy(copy, value);
    if (uuid_compare(copy, value) != 0) return 7;
    copy[15] = 0xfe;
    if (uuid_compare(copy, value) >= 0 || uuid_compare(value, copy) <= 0) return 8;

    memset(copy, 0xa5, sizeof(copy));
    if (uuid_parse("", copy) == 0 || copy[0] != 0xa5) return 9;
    if (uuid_parse("00112233-4455-6677-8899-aabbccddee", copy) == 0
        || copy[0] != 0xa5) return 10;
    if (uuid_parse("00112233-4455-6677-8899-aabbccddeeffx", copy) == 0
        || copy[0] != 0xa5) return 11;
    if (uuid_parse("00112233_4455-6677-8899-aabbccddeeff", copy) == 0
        || copy[0] != 0xa5) return 12;
    if (uuid_parse("00112233-4455-6677-8899-aabbccddeefg", copy) == 0
        || copy[0] != 0xa5) return 13;

    uuid_generate_random(value);
    if (uuid_is_null(value) || !has_version_and_variant(value, 4)) return 14;
    uuid_generate(value);
    if (uuid_is_null(value) || !has_version_and_variant(value, 4)) return 15;
    uuid_generate_time(value);
    if (uuid_is_null(value) || !has_version_and_variant(value, 1)) return 16;

    return 0;
}

#if defined(OPEN_FOCUS_UUID_COMPAT_STANDALONE)
int main(void) {
    return open_focus_uuid_compat_probe();
}
#endif
