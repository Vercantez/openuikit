/* Independent C reconstruction of CoreMedia foundational value layouts.
 * Field types follow the public C typedefs (int64_t/int32_t/uint32_t), not
 * copied SDK headers. */
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

struct CMTime {
    int64_t value;
    int32_t timescale;
    uint32_t flags;
    int64_t epoch;
};

struct CMTimeRange {
    struct CMTime start;
    struct CMTime duration;
};

struct CMTimeMapping {
    struct CMTimeRange source;
    struct CMTimeRange target;
};

struct CMSampleTimingInfo {
    struct CMTime duration;
    struct CMTime presentationTimeStamp;
    struct CMTime decodeTimeStamp;
};

struct CMVideoDimensions {
    int32_t width;
    int32_t height;
};

static int fail(const char *label) {
    fprintf(stderr, "CM_LAYOUT_FAIL %s\n", label);
    return 1;
}

int main(void) {
    if (sizeof(struct CMTime) != 24) return fail("CMTime.size");
    if (_Alignof(struct CMTime) != 8) return fail("CMTime.align");
    if (offsetof(struct CMTime, value) != 0) return fail("CMTime.value");
    if (offsetof(struct CMTime, timescale) != 8) return fail("CMTime.timescale");
    if (offsetof(struct CMTime, flags) != 12) return fail("CMTime.flags");
    if (offsetof(struct CMTime, epoch) != 16) return fail("CMTime.epoch");

    if (sizeof(struct CMTimeRange) != 48) return fail("CMTimeRange.size");
    if (offsetof(struct CMTimeRange, start) != 0) return fail("CMTimeRange.start");
    if (offsetof(struct CMTimeRange, duration) != 24) return fail("CMTimeRange.duration");

    if (sizeof(struct CMTimeMapping) != 96) return fail("CMTimeMapping.size");
    if (offsetof(struct CMTimeMapping, source) != 0) return fail("CMTimeMapping.source");
    if (offsetof(struct CMTimeMapping, target) != 48) return fail("CMTimeMapping.target");

    if (sizeof(struct CMSampleTimingInfo) != 72) return fail("CMSampleTimingInfo.size");
    if (offsetof(struct CMSampleTimingInfo, duration) != 0)
        return fail("CMSampleTimingInfo.duration");
    if (offsetof(struct CMSampleTimingInfo, presentationTimeStamp) != 24)
        return fail("CMSampleTimingInfo.presentationTimeStamp");
    if (offsetof(struct CMSampleTimingInfo, decodeTimeStamp) != 48)
        return fail("CMSampleTimingInfo.decodeTimeStamp");

    if (sizeof(struct CMVideoDimensions) != 8) return fail("CMVideoDimensions.size");
    if (offsetof(struct CMVideoDimensions, width) != 0)
        return fail("CMVideoDimensions.width");
    if (offsetof(struct CMVideoDimensions, height) != 4)
        return fail("CMVideoDimensions.height");

    puts("CM_LAYOUT_OK");
    return 0;
}
