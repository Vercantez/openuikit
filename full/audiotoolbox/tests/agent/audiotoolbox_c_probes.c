/* Independent C reconstruction of AudioToolbox/CoreAudio foundational layouts.
 * This is not a module-local Swift identity for CoreAudioTypes types. It exists
 * only as a clean-room ABI fixture under tests/agent.
 */
#include <dlfcn.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    uint32_t componentType;
    uint32_t componentSubType;
    uint32_t componentManufacturer;
    uint32_t componentFlags;
    uint32_t componentFlagsMask;
} AudioComponentDescriptionC;

typedef struct {
    uint8_t channel;
    uint8_t note;
    uint8_t velocity;
    uint8_t releaseVelocity;
    float duration;
} MIDINoteMessageC;

typedef struct {
    uint32_t mNumberChannels;
    uint32_t mDataByteSize;
    void *mData;
} AudioBufferC;

typedef struct {
    uint32_t mNumberBuffers;
    AudioBufferC mBuffers[1];
} AudioBufferListC;

typedef struct {
    uint32_t mAudioDataBytesCapacity;
    void *mAudioData;
    uint32_t mAudioDataByteSize;
    void *mUserData;
    uint32_t mPacketDescriptionCapacity;
    void *mPacketDescriptions;
    uint32_t mPacketDescriptionCount;
} AudioQueueBufferC;

static void fail(const char *message) {
    fprintf(stderr, "AUDIOTOOLBOX_C_PROBE_FAIL %s\n", message);
    exit(1);
}

static size_t audio_buffer_list_bytes(uint32_t count) {
    size_t header = offsetof(AudioBufferListC, mBuffers);
    return header + (size_t)count * sizeof(AudioBufferC);
}

static void traverse_list(uint32_t claimed, uint32_t allocated, int expect_overflow) {
    size_t bytes = audio_buffer_list_bytes(allocated);
    AudioBufferListC *list = calloc(1, bytes ? bytes : 1);
    if (!list) {
        fail("calloc");
    }
    list->mNumberBuffers = claimed;
    size_t end = (size_t)((unsigned char *)list + bytes);
    int overflow = 0;
    uint32_t visited = 0;
    for (uint32_t i = 0; i < claimed; i++) {
        unsigned char *slot =
            (unsigned char *)&list->mBuffers[0] + (size_t)i * sizeof(AudioBufferC);
        if ((size_t)(slot + sizeof(AudioBufferC)) > end) {
            overflow = 1;
            break;
        }
        AudioBufferC *buffer = (AudioBufferC *)(void *)slot;
        buffer->mNumberChannels = 1;
        buffer->mDataByteSize = 4;
        visited += 1;
    }
    if (expect_overflow) {
        if (!overflow) {
            fail("expected overflow");
        }
    } else if (overflow || visited != claimed) {
        fail("unexpected overflow or visit count");
    }
    free(list);
}

static void require_symbol(void *handle, const char *name) {
    if (!dlsym(handle, name)) {
        fprintf(stderr, "missing C symbol %s: %s\n", name, dlerror());
        fail(name);
    }
}

int main(int argc, char **argv) {
    if (sizeof(AudioComponentDescriptionC) != 20) {
        fail("AudioComponentDescription size");
    }
    if (offsetof(AudioComponentDescriptionC, componentFlagsMask) != 16) {
        fail("AudioComponentDescription last field");
    }
    if (sizeof(MIDINoteMessageC) != 8) {
        fail("MIDINoteMessage size");
    }
    if (offsetof(MIDINoteMessageC, duration) != 4) {
        fail("MIDINoteMessage duration offset");
    }
    if (sizeof(AudioBufferC) != 16) {
        fail("AudioBuffer size");
    }
    if (offsetof(AudioBufferListC, mBuffers) != 8) {
        fail("AudioBufferList flexible header");
    }
    if (sizeof(AudioQueueBufferC) != 56) {
        fail("AudioQueueBuffer size");
    }

    traverse_list(0, 0, 0);
    traverse_list(1, 1, 0);
    traverse_list(8, 8, 0);
    traverse_list(16, 4, 1);

    if (argc < 2) {
        fail("dylib path required");
    }
    void *handle = dlopen(argv[1], RTLD_NOW | RTLD_LOCAL);
    if (!handle) {
        fprintf(stderr, "%s\n", dlerror());
        fail("dlopen");
    }

    const char *symbols[] = {
        "AudioComponentCount",
        "AudioComponentFindNext",
        "AudioComponentInstanceNew",
        "AudioComponentInstanceDispose",
        "NewMusicSequence",
        "DisposeMusicSequence",
        "MusicSequenceNewTrack",
        "NewMusicEventIterator",
        "MusicTrackNewMIDINoteEvent",
        "AudioQueueNewOutput",
        "AudioQueueAllocateBuffer",
        "AudioQueueFreeBuffer",
        "AudioQueueStart",
        "AudioQueueDispose",
        "AudioServicesPlaySystemSound",
        "AudioServicesCreateSystemSoundID",
        "AudioFileOpenURL",
        "AudioFileClose",
        "ExtAudioFileOpenURL",
        "AudioOutputUnitStart",
        "MusicPlayerStart",
        "AudioConverterDispose",
        NULL
    };
    for (const char **name = symbols; *name; name++) {
        require_symbol(handle, *name);
    }

    typedef int32_t (*NewMusicSequenceFn)(void **);
    NewMusicSequenceFn newSeq = (NewMusicSequenceFn)dlsym(handle, "NewMusicSequence");
    typedef int32_t (*DisposeMusicSequenceFn)(void *);
    DisposeMusicSequenceFn disposeSeq = (DisposeMusicSequenceFn)dlsym(handle, "DisposeMusicSequence");
    void *sequence = (void *)(uintptr_t)1;
    if (newSeq(&sequence) != 0 || sequence == NULL) {
        fail("NewMusicSequence C call");
    }
    if (disposeSeq(sequence) != 0) {
        fail("DisposeMusicSequence C call");
    }
    if (disposeSeq(sequence) != 0) {
        fail("DisposeMusicSequence C idempotent");
    }

    typedef uint32_t (*AudioComponentCountFn)(const void *);
    AudioComponentCountFn countFn = (AudioComponentCountFn)dlsym(handle, "AudioComponentCount");
    AudioComponentDescriptionC desc;
    memset(&desc, 0, sizeof(desc));
    if (countFn(&desc) != 0) {
        fail("AudioComponentCount must be empty");
    }

    typedef int32_t (*AudioQueueStartFn)(void *, const void *);
    AudioQueueStartFn startFn = (AudioQueueStartFn)dlsym(handle, "AudioQueueStart");
    if (startFn(NULL, NULL) != -66671 && startFn(NULL, NULL) != -66680) {
        /* QueueInvalidated=-66671 or InvalidDevice=-66680; nil queue is invalidated. */
        int32_t status = startFn(NULL, NULL);
        if (status != -66671) {
            fprintf(stderr, "AudioQueueStart nil status=%d\n", status);
            fail("AudioQueueStart fail-closed");
        }
    }

    dlclose(handle);
    puts("AUDIOTOOLBOX_C_PROBE_OK");
    return 0;
}
