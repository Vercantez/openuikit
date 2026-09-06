// Harness, not Focus source. Generated Metrics.swift / AppNimbus.swift
// are absent from pin a2832521 (`expected_generated_missing` in
// full/focus-ios/focus-main-sources.json). Types live in the Blockzilla
// module so TipViewController.swift:14 can name AppNimbus without an
// import, matching the Xcode generated-file layout.
// EraseIntent is the Siri intent class the real target generates from
// Intents.intentdefinition.
// MEASURED Blockzilla 2026-09-06: AppNimbus / EraseIntent / throw String.

import FocusAppServices
import Fuzi
import Intents
import OpenUIKit

typealias AppNimbus = FocusAppServices.AppNimbus
typealias Timer = OpenUIKit.Timer
typealias NSAttributedString = OpenUIKit.NSAttributedString
typealias NSMutableAttributedString = OpenUIKit.NSMutableAttributedString
typealias XMLElement = Fuzi.XMLElement

final class EraseIntent: INIntent {
    nonisolated override init() {
        super.init()
    }
}

extension String: Error {}
