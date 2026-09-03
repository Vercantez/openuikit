import Foundation

/// Linux starting implementation of Apple's public `MediaPlayer` module.
/// Playback, library, CarPlay, and Now Playing sessions fail closed. UIKit
/// artwork and view types are omitted rather than faked.

public func MPVolumeSettingsAlertHide() {}

public func MPVolumeSettingsAlertShow() {}

public func MPVolumeSettingsAlertIsVisible() -> Bool { false }
