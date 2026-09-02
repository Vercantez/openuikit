#include "CoreAudioTypesCLayout.h"

#include <stdio.h>

#define REPORT_SIZE(T) printf("SIZE %s %zu %zu\n", #T, sizeof(struct T), _Alignof(struct T))
#define REPORT_OFF(T, F) printf("OFF %s %s %zu\n", #T, #F, offsetof(struct T, F))
#define ASSERT_SIZE(T, S, A) \
    _Static_assert(sizeof(struct T) == (S), #T " size"); \
    _Static_assert(_Alignof(struct T) == (A), #T " alignment")
#define ASSERT_OFF(T, F, O) _Static_assert(offsetof(struct T, F) == (O), #T "." #F " offset")

/* Values observed from the Xcode 26.1 macOS ARM64 CoreAudioTypes headers. */
ASSERT_SIZE(CATAudioBuffer, 16, 8);
ASSERT_OFF(CATAudioBuffer, mNumberChannels, 0);
ASSERT_OFF(CATAudioBuffer, mDataByteSize, 4);
ASSERT_OFF(CATAudioBuffer, mData, 8);

ASSERT_SIZE(CATAudioBufferList, 24, 8);
ASSERT_OFF(CATAudioBufferList, mNumberBuffers, 0);
ASSERT_OFF(CATAudioBufferList, mBuffers, 8);

ASSERT_SIZE(CATAudioStreamBasicDescription, 40, 8);
ASSERT_OFF(CATAudioStreamBasicDescription, mSampleRate, 0);
ASSERT_OFF(CATAudioStreamBasicDescription, mFormatID, 8);
ASSERT_OFF(CATAudioStreamBasicDescription, mFormatFlags, 12);
ASSERT_OFF(CATAudioStreamBasicDescription, mBytesPerPacket, 16);
ASSERT_OFF(CATAudioStreamBasicDescription, mFramesPerPacket, 20);
ASSERT_OFF(CATAudioStreamBasicDescription, mBytesPerFrame, 24);
ASSERT_OFF(CATAudioStreamBasicDescription, mChannelsPerFrame, 28);
ASSERT_OFF(CATAudioStreamBasicDescription, mBitsPerChannel, 32);
ASSERT_OFF(CATAudioStreamBasicDescription, mReserved, 36);

ASSERT_SIZE(CATAudioStreamPacketDescription, 16, 8);
ASSERT_OFF(CATAudioStreamPacketDescription, mStartOffset, 0);
ASSERT_OFF(CATAudioStreamPacketDescription, mVariableFramesInPacket, 8);
ASSERT_OFF(CATAudioStreamPacketDescription, mDataByteSize, 12);

ASSERT_SIZE(CATAudioStreamPacketDependencyDescription, 16, 4);
ASSERT_OFF(CATAudioStreamPacketDependencyDescription, mIsIndependentlyDecodable, 0);
ASSERT_OFF(CATAudioStreamPacketDependencyDescription, mPreRollCount, 4);
ASSERT_OFF(CATAudioStreamPacketDependencyDescription, mFlags, 8);
ASSERT_OFF(CATAudioStreamPacketDependencyDescription, mReserved, 12);

ASSERT_SIZE(CATSMPTETime, 24, 4);
ASSERT_OFF(CATSMPTETime, mSubframes, 0);
ASSERT_OFF(CATSMPTETime, mSubframeDivisor, 2);
ASSERT_OFF(CATSMPTETime, mCounter, 4);
ASSERT_OFF(CATSMPTETime, mType, 8);
ASSERT_OFF(CATSMPTETime, mFlags, 12);
ASSERT_OFF(CATSMPTETime, mHours, 16);
ASSERT_OFF(CATSMPTETime, mMinutes, 18);
ASSERT_OFF(CATSMPTETime, mSeconds, 20);
ASSERT_OFF(CATSMPTETime, mFrames, 22);

ASSERT_SIZE(CATAudioTimeStamp, 64, 8);
ASSERT_OFF(CATAudioTimeStamp, mSampleTime, 0);
ASSERT_OFF(CATAudioTimeStamp, mHostTime, 8);
ASSERT_OFF(CATAudioTimeStamp, mRateScalar, 16);
ASSERT_OFF(CATAudioTimeStamp, mWordClockTime, 24);
ASSERT_OFF(CATAudioTimeStamp, mSMPTETime, 32);
ASSERT_OFF(CATAudioTimeStamp, mFlags, 56);
ASSERT_OFF(CATAudioTimeStamp, mReserved, 60);

ASSERT_SIZE(CATAudioChannelDescription, 20, 4);
ASSERT_OFF(CATAudioChannelDescription, mChannelLabel, 0);
ASSERT_OFF(CATAudioChannelDescription, mChannelFlags, 4);
ASSERT_OFF(CATAudioChannelDescription, mCoordinates, 8);

ASSERT_SIZE(CATAudioChannelLayout, 32, 4);
ASSERT_OFF(CATAudioChannelLayout, mChannelLayoutTag, 0);
ASSERT_OFF(CATAudioChannelLayout, mChannelBitmap, 4);
ASSERT_OFF(CATAudioChannelLayout, mNumberChannelDescriptions, 8);
ASSERT_OFF(CATAudioChannelLayout, mChannelDescriptions, 12);

ASSERT_SIZE(CATAudioClassDescription, 12, 4);
ASSERT_OFF(CATAudioClassDescription, mType, 0);
ASSERT_OFF(CATAudioClassDescription, mSubType, 4);
ASSERT_OFF(CATAudioClassDescription, mManufacturer, 8);

ASSERT_SIZE(CATAudioFormatListItem, 48, 8);
ASSERT_OFF(CATAudioFormatListItem, mASBD, 0);
ASSERT_OFF(CATAudioFormatListItem, mChannelLayoutTag, 40);

ASSERT_SIZE(CATAudioValueRange, 16, 8);
ASSERT_OFF(CATAudioValueRange, mMinimum, 0);
ASSERT_OFF(CATAudioValueRange, mMaximum, 8);

ASSERT_SIZE(CATAudioValueTranslation, 32, 8);
ASSERT_OFF(CATAudioValueTranslation, mInputData, 0);
ASSERT_OFF(CATAudioValueTranslation, mInputDataSize, 8);
ASSERT_OFF(CATAudioValueTranslation, mOutputData, 16);
ASSERT_OFF(CATAudioValueTranslation, mOutputDataSize, 24);

int main(void)
{
    REPORT_SIZE(CATAudioBuffer);
    REPORT_OFF(CATAudioBuffer, mNumberChannels);
    REPORT_OFF(CATAudioBuffer, mDataByteSize);
    REPORT_OFF(CATAudioBuffer, mData);

    REPORT_SIZE(CATAudioBufferList);
    REPORT_OFF(CATAudioBufferList, mNumberBuffers);
    REPORT_OFF(CATAudioBufferList, mBuffers);

    REPORT_SIZE(CATAudioStreamBasicDescription);
    REPORT_OFF(CATAudioStreamBasicDescription, mSampleRate);
    REPORT_OFF(CATAudioStreamBasicDescription, mFormatID);
    REPORT_OFF(CATAudioStreamBasicDescription, mFormatFlags);
    REPORT_OFF(CATAudioStreamBasicDescription, mBytesPerPacket);
    REPORT_OFF(CATAudioStreamBasicDescription, mFramesPerPacket);
    REPORT_OFF(CATAudioStreamBasicDescription, mBytesPerFrame);
    REPORT_OFF(CATAudioStreamBasicDescription, mChannelsPerFrame);
    REPORT_OFF(CATAudioStreamBasicDescription, mBitsPerChannel);
    REPORT_OFF(CATAudioStreamBasicDescription, mReserved);

    REPORT_SIZE(CATAudioStreamPacketDescription);
    REPORT_OFF(CATAudioStreamPacketDescription, mStartOffset);
    REPORT_OFF(CATAudioStreamPacketDescription, mVariableFramesInPacket);
    REPORT_OFF(CATAudioStreamPacketDescription, mDataByteSize);

    REPORT_SIZE(CATAudioStreamPacketDependencyDescription);
    REPORT_OFF(CATAudioStreamPacketDependencyDescription, mIsIndependentlyDecodable);
    REPORT_OFF(CATAudioStreamPacketDependencyDescription, mPreRollCount);
    REPORT_OFF(CATAudioStreamPacketDependencyDescription, mFlags);
    REPORT_OFF(CATAudioStreamPacketDependencyDescription, mReserved);

    REPORT_SIZE(CATSMPTETime);
    REPORT_OFF(CATSMPTETime, mSubframes);
    REPORT_OFF(CATSMPTETime, mSubframeDivisor);
    REPORT_OFF(CATSMPTETime, mCounter);
    REPORT_OFF(CATSMPTETime, mType);
    REPORT_OFF(CATSMPTETime, mFlags);
    REPORT_OFF(CATSMPTETime, mHours);
    REPORT_OFF(CATSMPTETime, mMinutes);
    REPORT_OFF(CATSMPTETime, mSeconds);
    REPORT_OFF(CATSMPTETime, mFrames);

    REPORT_SIZE(CATAudioTimeStamp);
    REPORT_OFF(CATAudioTimeStamp, mSampleTime);
    REPORT_OFF(CATAudioTimeStamp, mHostTime);
    REPORT_OFF(CATAudioTimeStamp, mRateScalar);
    REPORT_OFF(CATAudioTimeStamp, mWordClockTime);
    REPORT_OFF(CATAudioTimeStamp, mSMPTETime);
    REPORT_OFF(CATAudioTimeStamp, mFlags);
    REPORT_OFF(CATAudioTimeStamp, mReserved);

    REPORT_SIZE(CATAudioChannelDescription);
    REPORT_OFF(CATAudioChannelDescription, mChannelLabel);
    REPORT_OFF(CATAudioChannelDescription, mChannelFlags);
    REPORT_OFF(CATAudioChannelDescription, mCoordinates);

    REPORT_SIZE(CATAudioChannelLayout);
    REPORT_OFF(CATAudioChannelLayout, mChannelLayoutTag);
    REPORT_OFF(CATAudioChannelLayout, mChannelBitmap);
    REPORT_OFF(CATAudioChannelLayout, mNumberChannelDescriptions);
    REPORT_OFF(CATAudioChannelLayout, mChannelDescriptions);

    REPORT_SIZE(CATAudioClassDescription);
    REPORT_OFF(CATAudioClassDescription, mType);
    REPORT_OFF(CATAudioClassDescription, mSubType);
    REPORT_OFF(CATAudioClassDescription, mManufacturer);

    REPORT_SIZE(CATAudioFormatListItem);
    REPORT_OFF(CATAudioFormatListItem, mASBD);
    REPORT_OFF(CATAudioFormatListItem, mChannelLayoutTag);

    REPORT_SIZE(CATAudioValueRange);
    REPORT_OFF(CATAudioValueRange, mMinimum);
    REPORT_OFF(CATAudioValueRange, mMaximum);

    REPORT_SIZE(CATAudioValueTranslation);
    REPORT_OFF(CATAudioValueTranslation, mInputData);
    REPORT_OFF(CATAudioValueTranslation, mInputDataSize);
    REPORT_OFF(CATAudioValueTranslation, mOutputData);
    REPORT_OFF(CATAudioValueTranslation, mOutputDataSize);

    printf(
        "TRAIL buffer_stride=%zu channel_desc_stride=%zu extra_buffers_4=%zu extra_channels_4=%zu\n",
        sizeof(struct CATAudioBuffer),
        sizeof(struct CATAudioChannelDescription),
        offsetof(struct CATAudioBufferList, mBuffers) + (4u * sizeof(struct CATAudioBuffer)),
        offsetof(struct CATAudioChannelLayout, mChannelDescriptions)
            + (4u * sizeof(struct CATAudioChannelDescription)));
    printf("COREAUDIOTYPES_C_LAYOUT_OK\n");
    return 0;
}
