@_exported import Foundation

/// Portable Linux starting point for Apple's public `MediaPlayer` module.
///
/// This tranche reconstructs the Xcode 26.1 iPhoneOS Swift overlay from the
/// pinned symbol graph. It is an in-process surface: now-playing metadata and
/// remote-command handlers live in this process, the media library is empty,
/// and nothing here talks to Apple Music, Control Center, CarPlay, AirPlay,
/// or a hardware volume HUD.
///
/// UIKit, AVFoundation, and CoreMedia types are not available to this Linux
/// `swiftc` invocation, so view controllers, artwork images, movie-player
/// views, and `AVPlayer` session APIs are omitted rather than stubbed with
/// fake UIKit types.

/// Linux has no system volume HUD. These entry points are inert.
public func MPVolumeSettingsAlertShow() {}

public func MPVolumeSettingsAlertHide() {}

public func MPVolumeSettingsAlertIsVisible() -> Bool { false }
