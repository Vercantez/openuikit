// Raw libuuid surface required by swift-foundation's Darwin _FoundationCShims.
//
// The open-source shim delegates these names to macOS libSystem when compiled
// for a Darwin target. machorun deliberately supplies a small Linux-backed
// libSystem rather than Apple's complete one, so the reusable
// FoundationEssentials guest dylib owns this missing substrate explicitly.

#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <uuid/uuid.h>

static void fill_random(void *buffer, size_t count) {
    int descriptor;
    do {
        descriptor = open("/dev/urandom", O_RDONLY);
    } while (descriptor < 0 && errno == EINTR);
    if (descriptor < 0) abort();

    uint8_t *next = (uint8_t *)buffer;
    size_t remaining = count;
    while (remaining != 0) {
        ssize_t received = read(descriptor, next, remaining);
        if (received < 0 && errno == EINTR) continue;
        if (received <= 0) {
            close(descriptor);
            abort();
        }
        next += (size_t)received;
        remaining -= (size_t)received;
    }
    (void)close(descriptor);
}

void uuid_clear(uuid_t value) {
    memset(value, 0, sizeof(uuid_t));
}

int uuid_compare(const uuid_t lhs, const uuid_t rhs) {
    int ordering = memcmp(lhs, rhs, sizeof(uuid_t));
    return ordering < 0 ? -1 : (ordering > 0 ? 1 : 0);
}

void uuid_copy(uuid_t destination, const uuid_t source) {
    memcpy(destination, source, sizeof(uuid_t));
}

void uuid_generate_random(uuid_t output) {
    fill_random(output, sizeof(uuid_t));
    output[6] = (uint8_t)((output[6] & 0x0f) | 0x40);
    output[8] = (uint8_t)((output[8] & 0x3f) | 0x80);
}

void uuid_generate(uuid_t output) {
    uuid_generate_random(output);
}

void uuid_generate_time(uuid_t output) {
    struct timespec now;
    if (clock_gettime(CLOCK_REALTIME, &now) != 0) abort();

    const uint64_t gregorian_offset = UINT64_C(0x01b21dd213814000);
    uint64_t timestamp = (uint64_t)now.tv_sec * UINT64_C(10000000)
        + (uint64_t)now.tv_nsec / UINT64_C(100)
        + gregorian_offset;
    uint8_t clock_and_node[8];
    fill_random(clock_and_node, sizeof(clock_and_node));

    output[0] = (uint8_t)(timestamp >> 24);
    output[1] = (uint8_t)(timestamp >> 16);
    output[2] = (uint8_t)(timestamp >> 8);
    output[3] = (uint8_t)timestamp;
    output[4] = (uint8_t)(timestamp >> 40);
    output[5] = (uint8_t)(timestamp >> 32);
    output[6] = (uint8_t)(((timestamp >> 56) & 0x0f) | 0x10);
    output[7] = (uint8_t)(timestamp >> 48);
    output[8] = (uint8_t)((clock_and_node[0] & 0x3f) | 0x80);
    output[9] = clock_and_node[1];
    memcpy(&output[10], &clock_and_node[2], 6);
    output[10] |= 0x01; // random node identifier, never a claimed MAC address
}

int uuid_is_null(const uuid_t value) {
    uint8_t accumulated = 0;
    for (size_t index = 0; index < sizeof(uuid_t); ++index) {
        accumulated |= value[index];
    }
    return accumulated == 0;
}

static int hex_nibble(unsigned char character) {
    if (character >= '0' && character <= '9') return character - '0';
    if (character >= 'a' && character <= 'f') return character - 'a' + 10;
    if (character >= 'A' && character <= 'F') return character - 'A' + 10;
    return -1;
}

int uuid_parse(const uuid_string_t input, uuid_t output) {
    static const uint8_t hyphens[] = {8, 13, 18, 23};
    size_t hyphen_index = 0;
    size_t source = 0;
    size_t destination = 0;
    uuid_t parsed;
    while (source < 36) {
        if (hyphen_index < sizeof(hyphens)
            && source == hyphens[hyphen_index]) {
            if (input[source++] != '-') return -1;
            ++hyphen_index;
            continue;
        }
        unsigned char high_character = (unsigned char)input[source++];
        if (high_character == '\0') return -1;
        int high = hex_nibble(high_character);
        if (high < 0) return -1;
        unsigned char low_character = (unsigned char)input[source++];
        if (low_character == '\0') return -1;
        int low = hex_nibble(low_character);
        if (low < 0) return -1;
        parsed[destination++] = (uint8_t)((high << 4) | low);
    }
    if (destination != 16 || input[36] != '\0') return -1;
    uuid_copy(output, parsed);
    return 0;
}

static void unparse(const uuid_t value, uuid_string_t output, const char *digits) {
    static const uint8_t groups[] = {4, 2, 2, 2, 6};
    size_t source = 0;
    size_t destination = 0;
    for (size_t group = 0; group < sizeof(groups); ++group) {
        if (group != 0) output[destination++] = '-';
        for (size_t byte = 0; byte < groups[group]; ++byte) {
            uint8_t item = value[source++];
            output[destination++] = digits[item >> 4];
            output[destination++] = digits[item & 0x0f];
        }
    }
    output[destination] = '\0';
}

void uuid_unparse_lower(const uuid_t value, uuid_string_t output) {
    unparse(value, output, "0123456789abcdef");
}

void uuid_unparse_upper(const uuid_t value, uuid_string_t output) {
    unparse(value, output, "0123456789ABCDEF");
}

void uuid_unparse(const uuid_t value, uuid_string_t output) {
    uuid_unparse_upper(value, output);
}
