import Foundation
import Cinematic

func testCNDetectionTypeRawValues() {
    precondition(CNDetectionType.unknown.rawValue == 0)
    precondition(CNDetectionType.humanFace.rawValue == 1)
    precondition(CNDetectionType.humanHead.rawValue == 2)
    precondition(CNDetectionType.humanTorso.rawValue == 3)
    precondition(CNDetectionType.catBody.rawValue == 4)
    precondition(CNDetectionType.dogBody.rawValue == 5)
    precondition(CNDetectionType.catHead.rawValue == 9)
    precondition(CNDetectionType.dogHead.rawValue == 10)
    precondition(CNDetectionType.sportsBall.rawValue == 11)
    precondition(CNDetectionType.autoFocus.rawValue == 100)
    precondition(CNDetectionType.fixedFocus.rawValue == 101)
    precondition(CNDetectionType.custom.rawValue == 102)
}

func testCNDetectionTypeInitRawValue() {
    precondition(CNDetectionType(rawValue: 1) == .humanFace)
    precondition(CNDetectionType(rawValue: 6) == nil)
    precondition(CNDetectionType(rawValue: 7) == nil)
    precondition(CNDetectionType(rawValue: 8) == nil)
    precondition(CNDetectionType(rawValue: 99) == nil)
}

func testCNDetectionTypeInequalityAndHashable() {
    precondition(CNDetectionType.humanFace != .dogBody)
    precondition(!(CNDetectionType.unknown != .unknown))
    precondition(CNDetectionType.custom.hashValue == CNDetectionType.custom.hashValue)
    precondition(CNDetectionType.custom.hashValue != CNDetectionType.autoFocus.hashValue)
    var hasher = Hasher()
    CNDetectionType.sportsBall.hash(into: &hasher)
    _ = hasher.finalize()
}

func testCNRenderingQualityRawValues() {
    precondition(CNRenderingQuality.thumbnail.rawValue == 0)
    precondition(CNRenderingQuality.preview.rawValue == 1)
    precondition(CNRenderingQuality.export.rawValue == 2)
    precondition(CNRenderingQuality.exportHigh.rawValue == 3)
}

func testCNRenderingQualityInitRawValue() {
    precondition(CNRenderingQuality(rawValue: 0) == .thumbnail)
    precondition(CNRenderingQuality(rawValue: 2) == .export)
    precondition(CNRenderingQuality(rawValue: 4) == nil)
}

func testCNRenderingQualityInequalityAndHashable() {
    precondition(CNRenderingQuality.preview != .export)
    precondition(CNRenderingQuality.thumbnail.hashValue != CNRenderingQuality.exportHigh.hashValue)
    var hasher = Hasher()
    CNRenderingQuality.export.hash(into: &hasher)
    _ = hasher.finalize()
}

func testCNSpatialAudioContentTypeRawValues() {
    precondition(CNSpatialAudioContentType.stereo.rawValue == 0)
    precondition(CNSpatialAudioContentType.spatial.rawValue == 1)
}

func testCNSpatialAudioContentTypeInitRawValue() {
    precondition(CNSpatialAudioContentType(rawValue: 0) == .stereo)
    precondition(CNSpatialAudioContentType(rawValue: 1) == .spatial)
    precondition(CNSpatialAudioContentType(rawValue: 2) == nil)
}

func testCNSpatialAudioContentTypeInequalityAndHashable() {
    precondition(CNSpatialAudioContentType.stereo != .spatial)
    precondition(CNSpatialAudioContentType.stereo.hashValue != CNSpatialAudioContentType.spatial.hashValue)
    var hasher = Hasher()
    CNSpatialAudioContentType.spatial.hash(into: &hasher)
    _ = hasher.finalize()
}

func testCNSpatialAudioRenderingStyleRawValues() {
    precondition(CNSpatialAudioRenderingStyle.cinematic.rawValue == 0)
    precondition(CNSpatialAudioRenderingStyle.studio.rawValue == 1)
    precondition(CNSpatialAudioRenderingStyle.inFrame.rawValue == 2)
    precondition(CNSpatialAudioRenderingStyle.cinematicBackgroundStem.rawValue == 3)
    precondition(CNSpatialAudioRenderingStyle.cinematicForegroundStem.rawValue == 4)
    precondition(CNSpatialAudioRenderingStyle.studioForegroundStem.rawValue == 5)
    precondition(CNSpatialAudioRenderingStyle.inFrameForegroundStem.rawValue == 6)
    precondition(CNSpatialAudioRenderingStyle.standard.rawValue == 7)
    precondition(CNSpatialAudioRenderingStyle.studioBackgroundStem.rawValue == 8)
    precondition(CNSpatialAudioRenderingStyle.inFrameBackgroundStem.rawValue == 9)
}

func testCNSpatialAudioRenderingStyleInitRawValue() {
    precondition(CNSpatialAudioRenderingStyle(rawValue: 0) == .cinematic)
    precondition(CNSpatialAudioRenderingStyle(rawValue: 7) == .standard)
    precondition(CNSpatialAudioRenderingStyle(rawValue: 10) == nil)
}

func testCNSpatialAudioRenderingStyleInequalityAndHashable() {
    precondition(CNSpatialAudioRenderingStyle.cinematic != .studio)
    precondition(
        CNSpatialAudioRenderingStyle.standard.hashValue !=
            CNSpatialAudioRenderingStyle.inFrame.hashValue
    )
    var hasher = Hasher()
    CNSpatialAudioRenderingStyle.studio.hash(into: &hasher)
    _ = hasher.finalize()
}
