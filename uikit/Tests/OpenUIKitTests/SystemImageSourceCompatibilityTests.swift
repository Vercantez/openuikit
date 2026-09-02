// This file deliberately imports the literal UIKit bridge rather than the
// implementation module. The expressions below are copied from the unchanged
// Reminder source surface; compiling this file is the source-compatibility
// gate that a same-module @testable test cannot provide.
import Foundation
import UIKit
import XCTest

// These declarations live in the external OpenUIKitTests module and import
// only the literal UIKit bridge. They prove the Objective-C importer surface
// remains externally subclassable rather than merely subclassable inside the
// implementation module.
private final class ExternalImageConfiguration: UIImage.Configuration,
                                                @unchecked Sendable {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

private final class ExternalSymbolConfiguration: UIImage.SymbolConfiguration,
                                                 @unchecked Sendable {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

/// Exercises the deliberately bounded pure-Swift class-factory route. Native
/// UIKit's Objective-C factory bypasses this coder; OpenUIKit must use it to
/// retain inherited source spelling and the external dynamic type. Every
/// common absent-key query must therefore be benign rather than NSCoder's
/// abstract-method exception.
private final class SeedInspectingSymbolConfiguration:
    UIImage.SymbolConfiguration, @unchecked Sendable {
    nonisolated(unsafe) static var coderCalls = 0

    let hasPointSize: Bool
    let hasWeight: Bool
    let hasUnknown: Bool
    let absentBool: Bool
    let absentFloat: Float
    let absentInt32: Int32
    let absentInt64: Int64
    let absentObjectIsNil: Bool

    required init?(coder: NSCoder) {
        Self.coderCalls += 1
        hasPointSize = coder.containsValue(forKey: "OpenUIKit.pointSize")
        hasWeight = coder.containsValue(forKey: "OpenUIKit.weight")
        hasUnknown = coder.containsValue(forKey: "External.unknown")
        absentBool = coder.decodeBool(forKey: "External.unknown")
        absentFloat = coder.decodeFloat(forKey: "External.unknown")
        absentInt32 = coder.decodeInt32(forKey: "External.unknown")
        absentInt64 = coder.decodeInt64(forKey: "External.unknown")
        absentObjectIsNil = coder.decodeObject(forKey: "External.unknown") == nil
        super.init(coder: coder)
    }
}

@MainActor
final class SystemImageSourceCompatibilityTests: XCTestCase {
    func testReminderSystemImageSpellingsCompileAndConstruct() {
        XCTAssertNotNil(UIImage(systemName: "calendar"))
        XCTAssertNotNil(UIImage(systemName: "clock"))
        XCTAssertNotNil(UIImage(systemName: "multiply"))
        XCTAssertNotNil(UIImage(systemName: "circlebadge"))
        XCTAssertNotNil(UIImage(systemName: "checkmark.circle.fill"))

        let configuration = UIImage.SymbolConfiguration(pointSize: 56,
                                                          weight: .regular)
        XCTAssertNotNil(UIImage(systemName: "plus.circle.fill",
                                withConfiguration: configuration))
    }

    func testConfigurationHasUIKitFoundationContracts() {
        func acceptsUIKitConfiguration(_ value: UIImage.Configuration) {
            _ = value
        }
        func acceptsFoundationContracts<T>(_ value: T)
        where T: NSObjectProtocol & NSCopying & NSSecureCoding {
            _ = value
        }

        let configuration = UIImage.SymbolConfiguration(pointSize: 56,
                                                          weight: .regular)
        acceptsUIKitConfiguration(configuration)
        acceptsFoundationContracts(configuration)

        // Native UIImage.SymbolConfiguration(pointSize:weight:) imports as
        // an inherited convenience initializer, not a designated initializer.
        // The literal external subclass must therefore construct with it and
        // retain its dynamic type without redeclaring the initializer.
        let external = ExternalSymbolConfiguration(pointSize: 12,
                                                     weight: .regular)
        XCTAssertTrue(type(of: external) == ExternalSymbolConfiguration.self)
        guard let externalCopy = external.copy() as? ExternalSymbolConfiguration else {
            XCTFail("copy erased the external SymbolConfiguration subclass")
            return
        }
        XCTAssertFalse(externalCopy === external)
        XCTAssertTrue(externalCopy.isEqual(external))
    }

    func testPureSwiftSubclassSeedHasSafeKeyedDefaultsAndBoundedRouting() {
        SeedInspectingSymbolConfiguration.coderCalls = 0
        let configuration = SeedInspectingSymbolConfiguration(
            pointSize: 12,
            weight: .regular
        )
        XCTAssertEqual(SeedInspectingSymbolConfiguration.coderCalls, 1)
        XCTAssertTrue(configuration.hasPointSize)
        XCTAssertTrue(configuration.hasWeight)
        XCTAssertFalse(configuration.hasUnknown)
        XCTAssertFalse(configuration.absentBool)
        XCTAssertEqual(configuration.absentFloat, 0)
        XCTAssertEqual(configuration.absentInt32, 0)
        XCTAssertEqual(configuration.absentInt64, 0)
        XCTAssertTrue(configuration.absentObjectIsNil)

        guard let copy = configuration.copy()
            as? SeedInspectingSymbolConfiguration else {
            XCTFail("seed copy erased the external dynamic type")
            return
        }
        XCTAssertEqual(SeedInspectingSymbolConfiguration.coderCalls, 2)
        XCTAssertFalse(copy === configuration)
        XCTAssertTrue(copy.isEqual(configuration))
        XCTAssertFalse(copy.hasUnknown)
        XCTAssertTrue(copy.absentObjectIsNil)
    }
}
