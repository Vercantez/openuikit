#ifndef COREAUDIOTYPES_C_LAYOUT_FIXTURE_H
#define COREAUDIOTYPES_C_LAYOUT_FIXTURE_H

/*
 * Clean-room C fixture for sizeof/alignof/offsetof comparison.
 * Independently reconstructed from sealed Swift graph field types and
 * declaration order. Not Apple header text.
 */

#include <stddef.h>
#include <stdint.h>

struct CATAudioBuffer {
    uint32_t mNumberChannels;
    uint32_t mDataByteSize;
    void *mData;
};

struct CATAudioBufferList {
    uint32_t mNumberBuffers;
    struct CATAudioBuffer mBuffers[1];
};

struct CATAudioStreamBasicDescription {
    double mSampleRate;
    uint32_t mFormatID;
    uint32_t mFormatFlags;
    uint32_t mBytesPerPacket;
    uint32_t mFramesPerPacket;
    uint32_t mBytesPerFrame;
    uint32_t mChannelsPerFrame;
    uint32_t mBitsPerChannel;
    uint32_t mReserved;
};

struct CATAudioStreamPacketDescription {
    int64_t mStartOffset;
    uint32_t mVariableFramesInPacket;
    uint32_t mDataByteSize;
};

struct CATAudioStreamPacketDependencyDescription {
    uint32_t mIsIndependentlyDecodable;
    uint32_t mPreRollCount;
    uint32_t mFlags;
    uint32_t mReserved;
};

struct CATSMPTETime {
    int16_t mSubframes;
    int16_t mSubframeDivisor;
    uint32_t mCounter;
    uint32_t mType;
    uint32_t mFlags;
    int16_t mHours;
    int16_t mMinutes;
    int16_t mSeconds;
    int16_t mFrames;
};

struct CATAudioTimeStamp {
    double mSampleTime;
    uint64_t mHostTime;
    double mRateScalar;
    uint64_t mWordClockTime;
    struct CATSMPTETime mSMPTETime;
    uint32_t mFlags;
    uint32_t mReserved;
};

struct CATAudioChannelDescription {
    uint32_t mChannelLabel;
    uint32_t mChannelFlags;
    float mCoordinates[3];
};

struct CATAudioChannelLayout {
    uint32_t mChannelLayoutTag;
    uint32_t mChannelBitmap;
    uint32_t mNumberChannelDescriptions;
    struct CATAudioChannelDescription mChannelDescriptions[1];
};

struct CATAudioClassDescription {
    uint32_t mType;
    uint32_t mSubType;
    uint32_t mManufacturer;
};

struct CATAudioFormatListItem {
    struct CATAudioStreamBasicDescription mASBD;
    uint32_t mChannelLayoutTag;
};

struct CATAudioValueRange {
    double mMinimum;
    double mMaximum;
};

struct CATAudioValueTranslation {
    void *mInputData;
    uint32_t mInputDataSize;
    void *mOutputData;
    uint32_t mOutputDataSize;
};

#endif
