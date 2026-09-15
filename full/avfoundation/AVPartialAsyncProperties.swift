import Foundation

// Wave 12: Apple-mirroring AVPartialAsyncProperty tokens for the remaining
// Root families. Each static vends an AVAsyncProperty key object whose
// portableKey records the property name; loading itself stays synchronous and
// fail-closed on this host (no media service). Exact names and value types
// are pinned by the iPhoneOS 26.1 symbol graph
// (AVPartialAsyncProperty<Root>.name static-var rows).

extension AVPartialAsyncProperty where Root: AVAssetTrack {
  public static var availableTrackAssociationTypes: AVAsyncProperty<Root, [AVAssetTrack.AssociationType]> {
    AVAsyncProperty(portableKey: "availableTrackAssociationTypes")
  }
  public static var isPlayable: AVAsyncProperty<Root, Bool> {
    AVAsyncProperty(portableKey: "isPlayable")
  }
  public static var isDecodable: AVAsyncProperty<Root, Bool> {
    AVAsyncProperty(portableKey: "isDecodable")
  }
  public static var naturalSize: AVAsyncProperty<Root, CGSize> {
    AVAsyncProperty(portableKey: "naturalSize")
  }
  public static var languageCode: AVAsyncProperty<Root, String?> {
    AVAsyncProperty(portableKey: "languageCode")
  }
  public static var commonMetadata: AVAsyncProperty<Root, [AVMetadataItem]> {
    AVAsyncProperty(portableKey: "commonMetadata")
  }
  public static var isSelfContained: AVAsyncProperty<Root, Bool> {
    AVAsyncProperty(portableKey: "isSelfContained")
  }
  public static var preferredVolume: AVAsyncProperty<Root, Float> {
    AVAsyncProperty(portableKey: "preferredVolume")
  }
  public static var minFrameDuration: AVAsyncProperty<Root, CMTime> {
    AVAsyncProperty(portableKey: "minFrameDuration")
  }
  public static var naturalTimeScale: AVAsyncProperty<Root, CMTimeScale> {
    AVAsyncProperty(portableKey: "naturalTimeScale")
  }
  public static var nominalFrameRate: AVAsyncProperty<Root, Float> {
    AVAsyncProperty(portableKey: "nominalFrameRate")
  }
  public static var estimatedDataRate: AVAsyncProperty<Root, Float> {
    AVAsyncProperty(portableKey: "estimatedDataRate")
  }
  public static var formatDescriptions: AVAsyncProperty<Root, [CMFormatDescription]> {
    AVAsyncProperty(portableKey: "formatDescriptions")
  }
  public static var preferredTransform: AVAsyncProperty<Root, CGAffineTransform> {
    AVAsyncProperty(portableKey: "preferredTransform")
  }
  public static var extendedLanguageTag: AVAsyncProperty<Root, String?> {
    AVAsyncProperty(portableKey: "extendedLanguageTag")
  }
  public static var mediaCharacteristics: AVAsyncProperty<Root, [AVMediaCharacteristic]> {
    AVAsyncProperty(portableKey: "mediaCharacteristics")
  }
  public static var totalSampleDataLength: AVAsyncProperty<Root, Int64> {
    AVAsyncProperty(portableKey: "totalSampleDataLength")
  }
  public static var canProvideSampleCursors: AVAsyncProperty<Root, Bool> {
    AVAsyncProperty(portableKey: "canProvideSampleCursors")
  }
  public static var requiresFrameReordering: AVAsyncProperty<Root, Bool> {
    AVAsyncProperty(portableKey: "requiresFrameReordering")
  }
  public static var availableMetadataFormats: AVAsyncProperty<Root, [AVMetadataFormat]> {
    AVAsyncProperty(portableKey: "availableMetadataFormats")
  }
  public static var hasAudioSampleDependencies: AVAsyncProperty<Root, Bool> {
    AVAsyncProperty(portableKey: "hasAudioSampleDependencies")
  }
  public static var metadata: AVAsyncProperty<Root, [AVMetadataItem]> {
    AVAsyncProperty(portableKey: "metadata")
  }
  public static var segments: AVAsyncProperty<Root, [AVAssetTrackSegment]> {
    AVAsyncProperty(portableKey: "segments")
  }
  public static var isEnabled: AVAsyncProperty<Root, Bool> {
    AVAsyncProperty(portableKey: "isEnabled")
  }
  public static var timeRange: AVAsyncProperty<Root, CMTimeRange> {
    AVAsyncProperty(portableKey: "timeRange")
  }
}

extension AVPartialAsyncProperty where Root: AVComposition {
  public static var tracks: AVAsyncProperty<Root, [AVCompositionTrack]> {
    AVAsyncProperty(portableKey: "tracks")
  }
}

extension AVPartialAsyncProperty where Root: AVMetadataItem {
  public static var numberValue: AVAsyncProperty<Root, NSNumber?> {
    AVAsyncProperty(portableKey: "numberValue")
  }
  public static var stringValue: AVAsyncProperty<Root, String?> {
    AVAsyncProperty(portableKey: "stringValue")
  }
  public static var extraAttributes: AVAsyncProperty<Root, [AVMetadataExtraAttributeKey : Any]?> {
    AVAsyncProperty(portableKey: "extraAttributes")
  }
  public static var value: AVAsyncProperty<Root, (any NSCopying & NSObjectProtocol)?> {
    AVAsyncProperty(portableKey: "value")
  }
  public static var dataValue: AVAsyncProperty<Root, Data?> {
    AVAsyncProperty(portableKey: "dataValue")
  }
  public static var dateValue: AVAsyncProperty<Root, Date?> {
    AVAsyncProperty(portableKey: "dateValue")
  }
}

extension AVPartialAsyncProperty where Root: AVMutableMovie {
  public static var tracks: AVAsyncProperty<Root, [AVMutableMovieTrack]> {
    AVAsyncProperty(portableKey: "tracks")
  }
}

extension AVPartialAsyncProperty where Root: AVFragmentedAsset {
  public static var tracks: AVAsyncProperty<Root, [AVFragmentedAssetTrack]> {
    AVAsyncProperty(portableKey: "tracks")
  }
}

extension AVPartialAsyncProperty where Root: AVFragmentedMovie {
  public static var tracks: AVAsyncProperty<Root, [AVFragmentedMovieTrack]> {
    AVAsyncProperty(portableKey: "tracks")
  }
}

extension AVPartialAsyncProperty where Root: AVMutableComposition {
  public static var tracks: AVAsyncProperty<Root, [AVMutableCompositionTrack]> {
    AVAsyncProperty(portableKey: "tracks")
  }
}

extension AVPartialAsyncProperty where Root: AVMovie {
  public static var tracks: AVAsyncProperty<Root, [AVMovieTrack]> {
    AVAsyncProperty(portableKey: "tracks")
  }
}

extension AVPartialAsyncProperty where Root: AVAsset {
  public static var availableMediaCharacteristicsWithMediaSelectionOptions: AVAsyncProperty<Root, [AVMediaCharacteristic]> {
    AVAsyncProperty(portableKey: "availableMediaCharacteristicsWithMediaSelectionOptions")
  }
  public static var trackGroups: AVAsyncProperty<Root, [AVAssetTrackGroup]> {
    AVAsyncProperty(portableKey: "trackGroups")
  }
  public static var creationDate: AVAsyncProperty<Root, AVMetadataItem?> {
    AVAsyncProperty(portableKey: "creationDate")
  }
  public static var preferredRate: AVAsyncProperty<Root, Float> {
    AVAsyncProperty(portableKey: "preferredRate")
  }
  public static var preferredVolume: AVAsyncProperty<Root, Float> {
    AVAsyncProperty(portableKey: "preferredVolume")
  }
  public static var containsFragments: AVAsyncProperty<Root, Bool> {
    AVAsyncProperty(portableKey: "containsFragments")
  }
  public static var allMediaSelections: AVAsyncProperty<Root, [AVMediaSelection]> {
    AVAsyncProperty(portableKey: "allMediaSelections")
  }
  public static var preferredTransform: AVAsyncProperty<Root, CGAffineTransform> {
    AVAsyncProperty(portableKey: "preferredTransform")
  }
  public static var canContainFragments: AVAsyncProperty<Root, Bool> {
    AVAsyncProperty(portableKey: "canContainFragments")
  }
  public static var hasProtectedContent: AVAsyncProperty<Root, Bool> {
    AVAsyncProperty(portableKey: "hasProtectedContent")
  }
  public static var overallDurationHint: AVAsyncProperty<Root, CMTime> {
    AVAsyncProperty(portableKey: "overallDurationHint")
  }
  public static var availableChapterLocales: AVAsyncProperty<Root, [Locale]> {
    AVAsyncProperty(portableKey: "availableChapterLocales")
  }
  public static var preferredMediaSelection: AVAsyncProperty<Root, AVMediaSelection> {
    AVAsyncProperty(portableKey: "preferredMediaSelection")
  }
  public static var availableMetadataFormats: AVAsyncProperty<Root, [AVMetadataFormat]> {
    AVAsyncProperty(portableKey: "availableMetadataFormats")
  }
  public static var minimumTimeOffsetFromLive: AVAsyncProperty<Root, CMTime> {
    AVAsyncProperty(portableKey: "minimumTimeOffsetFromLive")
  }
  public static var isCompatibleWithAirPlayVideo: AVAsyncProperty<Root, Bool> {
    AVAsyncProperty(portableKey: "isCompatibleWithAirPlayVideo")
  }
  public static var isCompatibleWithSavedPhotosAlbum: AVAsyncProperty<Root, Bool> {
    AVAsyncProperty(portableKey: "isCompatibleWithSavedPhotosAlbum")
  }
  public static var providesPreciseDurationAndTiming: AVAsyncProperty<Root, Bool> {
    AVAsyncProperty(portableKey: "providesPreciseDurationAndTiming")
  }
}
