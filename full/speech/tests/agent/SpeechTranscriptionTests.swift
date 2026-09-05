@_spi(OpenUIKitHost) import Speech
import Foundation

func testSFAcousticFeature() {
    let feature = SFAcousticFeature(frameDuration: 0.01, acousticFeatureValuePerFrame: [0.5, 0.25])
    precondition(feature.frameDuration == 0.01)
    precondition(feature.acousticFeatureValuePerFrame == [0.5, 0.25])
    let copied = feature.copy() as! SFAcousticFeature
    precondition(copied.isEqual(feature))
    precondition(copied !== feature)
    precondition(SFAcousticFeature(coder: NSCoder()) == nil)
}

func testSFVoiceAnalytics() {
    let feature = SFAcousticFeature(frameDuration: 0.01, acousticFeatureValuePerFrame: [0.5])
    let analytics = SFVoiceAnalytics(jitter: feature, pitch: feature, shimmer: feature, voicing: feature)
    precondition(analytics.jitter.isEqual(feature))
    precondition(analytics.pitch.isEqual(feature))
    precondition(analytics.shimmer.isEqual(feature))
    precondition(analytics.voicing.isEqual(feature))
    precondition((analytics.copy() as! SFVoiceAnalytics).isEqual(analytics))
    precondition(SFVoiceAnalytics(coder: NSCoder()) == nil)
}

func testSFTranscriptionSegment() {
    let feature = SFAcousticFeature(frameDuration: 0.01, acousticFeatureValuePerFrame: [0.5])
    let analytics = SFVoiceAnalytics(jitter: feature, pitch: feature, shimmer: feature, voicing: feature)
    let segment = SFTranscriptionSegment(
        substring: "hello",
        substringRange: NSRange(location: 0, length: 5),
        timestamp: 0.1,
        duration: 0.4,
        confidence: 0.92,
        alternativeSubstrings: ["helloo"],
        voiceAnalytics: analytics
    )
    precondition(segment.substring == "hello")
    precondition(segment.substringRange.location == 0)
    precondition(segment.timestamp == 0.1)
    precondition(segment.duration == 0.4)
    precondition(segment.confidence == 0.92)
    precondition(segment.alternativeSubstrings == ["helloo"])
    precondition(segment.voiceAnalytics != nil)
    precondition(SFTranscriptionSegment(coder: NSCoder()) == nil)
}

func testSFTranscription() {
    let segment = SFTranscriptionSegment(
        substring: "hello",
        substringRange: NSRange(location: 0, length: 5),
        timestamp: 0.1,
        duration: 0.4,
        confidence: 0.92,
        alternativeSubstrings: [],
        voiceAnalytics: nil
    )
    let transcription = SFTranscription(
        formattedString: "hello",
        segments: [segment],
        speakingRate: 120,
        averagePauseDuration: 0.05
    )
    precondition(transcription.formattedString == "hello")
    precondition(transcription.segments.count == 1)
    precondition(transcription.speakingRate == 120)
    precondition(transcription.averagePauseDuration == 0.05)
    precondition(SFTranscription(coder: NSCoder()) == nil)
}

func testSFSpeechRecognitionMetadata() {
    let feature = SFAcousticFeature(frameDuration: 0.01, acousticFeatureValuePerFrame: [0.5])
    let analytics = SFVoiceAnalytics(jitter: feature, pitch: feature, shimmer: feature, voicing: feature)
    let metadata = SFSpeechRecognitionMetadata(
        averagePauseDuration: 0.05,
        speakingRate: 120,
        speechDuration: 0.5,
        speechStartTimestamp: 0.1,
        voiceAnalytics: analytics
    )
    precondition(metadata.averagePauseDuration == 0.05)
    precondition(metadata.speakingRate == 120)
    precondition(metadata.speechDuration == 0.5)
    precondition(metadata.speechStartTimestamp == 0.1)
    precondition(metadata.voiceAnalytics != nil)
    precondition(SFSpeechRecognitionMetadata(coder: NSCoder()) == nil)
}

func testSFSpeechRecognitionResult() {
    let transcription = SFTranscription(formattedString: "hello")
    let metadata = SFSpeechRecognitionMetadata(
        averagePauseDuration: 0.05,
        speakingRate: 120,
        speechDuration: 0.5,
        speechStartTimestamp: 0.1,
        voiceAnalytics: nil
    )
    let result = SFSpeechRecognitionResult(
        bestTranscription: transcription,
        transcriptions: [transcription, SFTranscription(formattedString: "halo")],
        isFinal: true,
        speechRecognitionMetadata: metadata
    )
    precondition(result.isFinal)
    precondition(result.bestTranscription.formattedString == "hello")
    precondition(result.transcriptions.count == 2)
    precondition(result.speechRecognitionMetadata?.speechDuration == 0.5)
    precondition(SFSpeechRecognitionResult(coder: NSCoder()) == nil)
}
