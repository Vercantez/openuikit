import Foundation

/// Linux MediaPlayer module. Now Playing, remote commands, media items,
/// queries, and the music-player state machine are in-process. Artwork /
/// volume / picker use OpenUIKit when imported, else isolated-host lookalikes.

public func MPVolumeSettingsAlertHide() {}

public func MPVolumeSettingsAlertShow() {}

public func MPVolumeSettingsAlertIsVisible() -> Bool { false }
