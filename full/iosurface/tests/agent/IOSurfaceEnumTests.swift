import Foundation
import IOSurface

func testComponentNameValues() {
    precondition(IOSurfaceComponentName.unknown.rawValue == 0)
    precondition(IOSurfaceComponentName.alpha.rawValue == 1)
    precondition(IOSurfaceComponentName.red.rawValue == 2)
    precondition(IOSurfaceComponentName.green.rawValue == 3)
    precondition(IOSurfaceComponentName.blue.rawValue == 4)
    precondition(IOSurfaceComponentName.luma.rawValue == 5)
    precondition(IOSurfaceComponentName.chromaRed.rawValue == 6)
    precondition(IOSurfaceComponentName.chromaBlue.rawValue == 7)
    precondition(IOSurfaceComponentName(rawValue: 4) == .blue)
    precondition(IOSurfaceComponentName(rawValue: 99) == nil)
    precondition(IOSurfaceComponentName.red != .blue)
    var hasher = Hasher()
    IOSurfaceComponentName.luma.hash(into: &hasher)
    _ = IOSurfaceComponentName.alpha.hashValue
}

func testComponentRangeValues() {
    precondition(IOSurfaceComponentRange.unknown.rawValue == 0)
    precondition(IOSurfaceComponentRange.fullRange.rawValue == 1)
    precondition(IOSurfaceComponentRange.videoRange.rawValue == 2)
    precondition(IOSurfaceComponentRange.wideRange.rawValue == 3)
    precondition(IOSurfaceComponentRange(rawValue: 2) == .videoRange)
    precondition(IOSurfaceComponentRange(rawValue: -1) == nil)
    precondition(IOSurfaceComponentRange.fullRange != .videoRange)
    var hasher = Hasher()
    IOSurfaceComponentRange.fullRange.hash(into: &hasher)
    _ = IOSurfaceComponentRange.wideRange.hashValue
}

func testComponentTypeValues() {
    precondition(IOSurfaceComponentType.unknown.rawValue == 0)
    precondition(IOSurfaceComponentType.unsignedInteger.rawValue == 1)
    precondition(IOSurfaceComponentType.signedInteger.rawValue == 2)
    precondition(IOSurfaceComponentType.float.rawValue == 3)
    precondition(IOSurfaceComponentType.signedNormalized.rawValue == 4)
    precondition(IOSurfaceComponentType(rawValue: 3) == .float)
    precondition(IOSurfaceComponentType(rawValue: 8) == nil)
    precondition(IOSurfaceComponentType.float != .unsignedInteger)
    var hasher = Hasher()
    IOSurfaceComponentType.float.hash(into: &hasher)
    _ = IOSurfaceComponentType.signedInteger.hashValue
}

func testSubsamplingValues() {
    precondition(IOSurfaceSubsampling.subsamplingUnknown.rawValue == 0)
    precondition(IOSurfaceSubsampling.subsamplingNone.rawValue == 1)
    precondition(IOSurfaceSubsampling.subsampling422.rawValue == 2)
    precondition(IOSurfaceSubsampling.subsampling420.rawValue == 3)
    precondition(IOSurfaceSubsampling.subsampling411.rawValue == 4)
    precondition(IOSurfaceSubsampling(rawValue: 3) == .subsampling420)
    precondition(IOSurfaceSubsampling(rawValue: 40) == nil)
    precondition(IOSurfaceSubsampling.subsampling420 != .subsampling422)
    var hasher = Hasher()
    IOSurfaceSubsampling.subsampling411.hash(into: &hasher)
    _ = IOSurfaceSubsampling.subsamplingNone.hashValue
}

func testMemoryLedgerTagsValues() {
    precondition(IOSurfaceMemoryLedgerTags.default.rawValue == 0x0000_0001)
    precondition(IOSurfaceMemoryLedgerTags.network.rawValue == 0x0000_0002)
    precondition(IOSurfaceMemoryLedgerTags.media.rawValue == 0x0000_0003)
    precondition(IOSurfaceMemoryLedgerTags.graphics.rawValue == 0x0000_0004)
    precondition(IOSurfaceMemoryLedgerTags.neural.rawValue == 0x0000_0005)
    precondition(IOSurfaceMemoryLedgerTags(rawValue: 4) == .graphics)
    precondition(IOSurfaceMemoryLedgerTags(rawValue: 0) == nil)
    precondition(IOSurfaceMemoryLedgerTags.media != .network)
    var hasher = Hasher()
    IOSurfaceMemoryLedgerTags.graphics.hash(into: &hasher)
    _ = IOSurfaceMemoryLedgerTags.neural.hashValue
}
