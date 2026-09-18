import Foundation

// Wave 14: Apple-mirroring async key-value-loading twins for AVAssetTrack
// and AVMetadataItem. The iPhoneOS 26.1 census records SYNTHESIZED
// AVAsynchronousKeyValueLoading `load` / `status` witnesses for both
// classes; AVAsset's twins (extension AVAsset in AVPlaybackRuntime.swift)
// already converted that class's rows, so these extensions project the same
// fail-closed semantics onto track/item stored state: `load` marks the key
// loaded and returns the synchronously projected value, or throws
// `mediaServiceUnavailable` when the key has no projectable value on this
// host. `status` reports `.loaded` only after `load` marked the key.
// Nothing is awaited from a service, daemon, or hardware, so every `await`
// completes immediately on the sealed gate.

extension AVAssetTrack {
  public func status<Root: AVAssetTrack, T>(
    of property: AVAsyncProperty<Root, T>
  ) -> AVAsyncProperty<Root, T>.Status {
    if trackLoadState.isLoaded(property.portableKey),
      let value: T = portableTrackValue(forKey: property.portableKey) {
      return .loaded(value)
    }
    return .notYetLoaded
  }

  public func load<Root: AVAssetTrack, T>(
    _ property: AVAsyncProperty<Root, T>,
    isolation: (any Actor)? = nil
  ) async throws -> T {
    _ = isolation
    trackLoadState.markLoaded([property.portableKey])
    if let value: T = portableTrackValue(forKey: property.portableKey) {
      return value
    }
    throw AVFoundationPortableError.mediaServiceUnavailable
  }

  public func load<Root: AVAssetTrack, A, B>(
    _ firstProperty: AVAsyncProperty<Root, A>,
    _ secondProperty: AVAsyncProperty<Root, B>,
    isolation: (any Actor)? = nil
  ) async throws -> (A, B) {
    let first = try await load(firstProperty, isolation: isolation)
    let second = try await load(secondProperty, isolation: isolation)
    return (first, second)
  }

  public func load<Root: AVAssetTrack, A, B, C>(
    _ firstProperty: AVAsyncProperty<Root, A>,
    _ secondProperty: AVAsyncProperty<Root, B>,
    _ thirdProperty: AVAsyncProperty<Root, C>,
    isolation: (any Actor)? = nil
  ) async throws -> (A, B, C) {
    let first = try await load(firstProperty, isolation: isolation)
    let second = try await load(secondProperty, isolation: isolation)
    let third = try await load(thirdProperty, isolation: isolation)
    return (first, second, third)
  }

  func portableTrackValue<T>(forKey key: String) -> T? {
    switch key {
    case "availableTrackAssociationTypes":
      return availableTrackAssociationTypes as? T
    case "isPlayable":
      return isPlayable as? T
    case "isDecodable":
      return isDecodable as? T
    case "naturalSize":
      return naturalSize as? T
    case "languageCode":
      return languageCode as? T
    case "commonMetadata":
      return commonMetadata as? T
    case "isSelfContained":
      return isSelfContained as? T
    case "preferredVolume":
      return preferredVolume as? T
    case "minFrameDuration":
      return minFrameDuration as? T
    case "naturalTimeScale":
      return naturalTimeScale as? T
    case "nominalFrameRate":
      return nominalFrameRate as? T
    case "estimatedDataRate":
      return estimatedDataRate as? T
    case "preferredTransform":
      return preferredTransform as? T
    case "extendedLanguageTag":
      return extendedLanguageTag as? T
    case "totalSampleDataLength":
      return totalSampleDataLength as? T
    case "canProvideSampleCursors":
      return canProvideSampleCursors as? T
    case "requiresFrameReordering":
      return requiresFrameReordering as? T
    case "availableMetadataFormats":
      return availableMetadataFormats as? T
    case "hasAudioSampleDependencies":
      return hasAudioSampleDependencies as? T
    case "metadata":
      return metadata as? T
    case "segments":
      return segments as? T
    case "isEnabled":
      return isEnabled as? T
    case "timeRange":
      return timeRange as? T
    default:
      // `formatDescriptions` projects `[Any]` while its token is
      // `[CMFormatDescription]`, and `mediaCharacteristics` has no stored
      // projection at all; both stay fail-closed (load throws,
      // status stays `.notYetLoaded`) rather than fabricating media data.
      return nil
    }
  }
}

extension AVMetadataItem {
  public func status<Root: AVMetadataItem, T>(
    of property: AVAsyncProperty<Root, T>
  ) -> AVAsyncProperty<Root, T>.Status {
    if itemLoadState.isLoaded(property.portableKey),
      let value: T = portableItemValue(forKey: property.portableKey) {
      return .loaded(value)
    }
    return .notYetLoaded
  }

  public func load<Root: AVMetadataItem, T>(
    _ property: AVAsyncProperty<Root, T>,
    isolation: (any Actor)? = nil
  ) async throws -> T {
    _ = isolation
    itemLoadState.markLoaded([property.portableKey])
    if let value: T = portableItemValue(forKey: property.portableKey) {
      return value
    }
    throw AVFoundationPortableError.mediaServiceUnavailable
  }

  public func load<Root: AVMetadataItem, A, B>(
    _ firstProperty: AVAsyncProperty<Root, A>,
    _ secondProperty: AVAsyncProperty<Root, B>,
    isolation: (any Actor)? = nil
  ) async throws -> (A, B) {
    let first = try await load(firstProperty, isolation: isolation)
    let second = try await load(secondProperty, isolation: isolation)
    return (first, second)
  }

  public func load<Root: AVMetadataItem, A, B, C>(
    _ firstProperty: AVAsyncProperty<Root, A>,
    _ secondProperty: AVAsyncProperty<Root, B>,
    _ thirdProperty: AVAsyncProperty<Root, C>,
    isolation: (any Actor)? = nil
  ) async throws -> (A, B, C) {
    let first = try await load(firstProperty, isolation: isolation)
    let second = try await load(secondProperty, isolation: isolation)
    let third = try await load(thirdProperty, isolation: isolation)
    return (first, second, third)
  }

  func portableItemValue<T>(forKey key: String) -> T? {
    switch key {
    case "numberValue":
      return numberValue as? T
    case "stringValue":
      return stringValue as? T
    case "extraAttributes":
      return extraAttributes as? T
    case "value":
      return value as? T
    case "dataValue":
      return dataValue as? T
    case "dateValue":
      return dateValue as? T
    default:
      return nil
    }
  }
}
