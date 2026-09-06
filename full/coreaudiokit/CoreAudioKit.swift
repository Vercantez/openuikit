@_exported import Foundation

#if canImport(AudioToolbox)
import AudioToolbox
#endif
#if canImport(UIKit)
import UIKit
#endif

/// Linux starting point for Apple's public `CoreAudioKit` module.
///
/// Isolated host compilation has Foundation only. AudioToolbox / UIKit types
/// use the lookalikes in `CoreAudioKitLookalikes.swift` until those modules
/// are on the link line. Linux has no Audio Unit custom view chrome,
/// Bluetooth MIDI radio, or Inter-App Audio host: those paths stay
/// fail-closed and never invent a successful Apple service result.

/// Linux host-test control. Hidden from ordinary `import CoreAudioKit`
/// clients and not part of Apple's public CoreAudioKit surface.
@_spi(OpenUIKitHost)
public enum CoreAudioKitHostControl {
    public static func scheduledUpdatesTimerIsActive(_ view: AUGenericViewInternal) -> Bool {
        view.hostScheduledUpdatesTimerIsActive
    }

    public static func armScheduledUpdatesTimer(_ view: AUGenericViewInternal) {
        view.hostArmScheduledUpdatesTimer()
    }

    public static func lastDisplayedItemIndexPath(
        _ view: AUGenericViewInternal
    ) -> IndexPath? {
        view.hostLastDisplayedItemIndexPath
    }

    public static func lastDisplayedSupplementaryKind(
        _ view: AUGenericViewInternal
    ) -> String? {
        view.hostLastDisplayedSupplementaryKind
    }

    public static func lastDisplayedSupplementaryIndexPath(
        _ view: AUGenericViewInternal
    ) -> IndexPath? {
        view.hostLastDisplayedSupplementaryIndexPath
    }

    public static func lastTraitCollection(
        _ view: AUGenericViewInternal
    ) -> UITraitCollection? {
        view.hostLastTraitCollection
    }

    public static func selectedViewConfiguration(
        _ unit: AUAudioUnit
    ) -> AUAudioUnitViewConfiguration? {
        AUAudioUnitViewSelection.selected(for: unit)
    }

    public static func attachedOutputAudioUnit(
        of view: CAInterAppAudioSwitcherView
    ) -> AudioUnit? {
        view.hostAttachedOutputAudioUnit
    }

    public static func attachedOutputAudioUnit(
        of view: CAInterAppAudioTransportView
    ) -> AudioUnit? {
        view.hostAttachedOutputAudioUnit
    }

    public static func discoveredBluetoothMIDIPeripheralCount(
        _ controller: CABTMIDICentralViewController
    ) -> Int {
        controller.hostDiscoveredPeripheralCount
    }

    public static func localMIDIPeripheralAdvertising(
        _ controller: CABTMIDILocalPeripheralViewController
    ) -> Bool {
        controller.hostIsAdvertising
    }
}
