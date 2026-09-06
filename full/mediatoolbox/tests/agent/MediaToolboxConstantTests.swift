import Foundation
import MediaToolbox

func testFlagAndVersionConstants() {
    mtExpect(kMTAudioProcessingTapCallbacksVersion_0 == 0, "callbacks version 0")
    mtExpect(
        kMTAudioProcessingTapCreationFlag_PreEffects == 1,
        "PreEffects is 1 << 0"
    )
    mtExpect(
        kMTAudioProcessingTapCreationFlag_PostEffects == 2,
        "PostEffects is 1 << 1"
    )
    mtExpect(
        kMTAudioProcessingTapFlag_StartOfStream == 256,
        "StartOfStream is 1 << 8"
    )
    mtExpect(
        kMTAudioProcessingTapFlag_EndOfStream == 512,
        "EndOfStream is 1 << 9"
    )
    mtExpect(
        (kMTAudioProcessingTapCreationFlag_PreEffects
            | kMTAudioProcessingTapCreationFlag_PostEffects) == 3,
        "creation flags combine"
    )
    mtExpect(
        (kMTAudioProcessingTapFlag_StartOfStream
            | kMTAudioProcessingTapFlag_EndOfStream) == 768,
        "stream flags combine"
    )
    mtExpect(kMTAudioProcessingTapInvalidArgumentErr == -12780, "invalid argument")
}
