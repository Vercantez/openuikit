#if __has_include(<CoreAudioTypes/CoreAudioTypes.h>)
#include <CoreAudioTypes/CoreAudioTypes.h>
#define AVFAUDIO_ABI_HAVE_COREAUDIOTYPES 1
#else
#define AVFAUDIO_ABI_HAVE_COREAUDIOTYPES 0
#endif

#if __has_include(<AudioToolbox/AudioToolbox.h>)
#include <AudioToolbox/AudioToolbox.h>
#define AVFAUDIO_ABI_HAVE_AUDIOTOOLBOX 1
#else
#define AVFAUDIO_ABI_HAVE_AUDIOTOOLBOX 0
#endif

#if __has_include(<CoreMIDI/CoreMIDI.h>)
#include <CoreMIDI/CoreMIDI.h>
#define AVFAUDIO_ABI_HAVE_COREMIDI 1
#else
#define AVFAUDIO_ABI_HAVE_COREMIDI 0
#endif

#if __has_include(<CoreMedia/CoreMedia.h>)
#include <CoreMedia/CoreMedia.h>
#define AVFAUDIO_ABI_HAVE_COREMEDIA 1
#else
#define AVFAUDIO_ABI_HAVE_COREMEDIA 0
#endif

#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct AVFAudioCLayoutReport {
    size_t audioBufferSize;
    size_t audioBufferAlign;
    size_t audioBufferListSize;
    size_t audioBufferListAlign;
    size_t audioBufferListNumberBuffersOffset;
    size_t audioBufferListBuffersOffset;
    size_t asbdSize;
    size_t asbdAlign;
    uint32_t walkedBuffers;
};

#if AVFAUDIO_ABI_HAVE_COREAUDIOTYPES || AVFAUDIO_ABI_HAVE_AUDIOTOOLBOX
static size_t avfaudio_abl_byte_count(uint32_t buffers) {
    if (buffers < 1) {
        buffers = 1;
    }
    return sizeof(AudioBufferList) + sizeof(AudioBuffer) * (buffers - 1);
}

int avfaudio_abi_fill_c_layout_report(struct AVFAudioCLayoutReport *report) {
    if (report == NULL) {
        return -1;
    }
    memset(report, 0, sizeof(*report));
    report->audioBufferSize = sizeof(AudioBuffer);
    report->audioBufferAlign = _Alignof(AudioBuffer);
    report->audioBufferListSize = sizeof(AudioBufferList);
    report->audioBufferListAlign = _Alignof(AudioBufferList);
    report->audioBufferListNumberBuffersOffset = offsetof(AudioBufferList, mNumberBuffers);
    report->audioBufferListBuffersOffset = offsetof(AudioBufferList, mBuffers);
    report->asbdSize = sizeof(AudioStreamBasicDescription);
    report->asbdAlign = _Alignof(AudioStreamBasicDescription);

    const uint32_t bufferCount = 4;
    AudioBufferList *list = calloc(1, avfaudio_abl_byte_count(bufferCount));
    if (list == NULL) {
        return -1;
    }
    list->mNumberBuffers = bufferCount;
    for (uint32_t index = 0; index < bufferCount; ++index) {
        list->mBuffers[index].mNumberChannels = 1;
        list->mBuffers[index].mDataByteSize = 64;
        list->mBuffers[index].mData = NULL;
    }
    uint32_t walked = 0;
    for (uint32_t index = 0; index < list->mNumberBuffers; ++index) {
        if (list->mBuffers[index].mNumberChannels == 1 && list->mBuffers[index].mDataByteSize == 64) {
            ++walked;
        }
    }
    report->walkedBuffers = walked;
    free(list);
    return walked == bufferCount ? 0 : -1;
}
#else
int avfaudio_abi_fill_c_layout_report(struct AVFAudioCLayoutReport *report) {
    if (report == NULL) {
        return -1;
    }
    memset(report, 0, sizeof(*report));
    return 1;
}
#endif

int avfaudio_abi_c_probe_available(void) {
#if AVFAUDIO_ABI_HAVE_COREAUDIOTYPES && AVFAUDIO_ABI_HAVE_AUDIOTOOLBOX \
    && AVFAUDIO_ABI_HAVE_COREMIDI && AVFAUDIO_ABI_HAVE_COREMEDIA
    return 1;
#else
    return 0;
#endif
}
