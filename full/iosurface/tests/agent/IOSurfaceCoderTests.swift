import Foundation
import IOSurface

func testCoderRoundTrip() {
    guard let surface = IOSurface(properties: [
        .width: 4,
        .height: 1,
        .pixelFormat: UInt32(0x4247_5241),
        .name: "coded",
    ]) else {
        preconditionFailure("coder source")
    }
    _ = surface.lock(options: [], seed: nil)
    surface.baseAddress.storeBytes(of: UInt32(0x1122_3344), as: UInt32.self)
    _ = surface.unlock(options: [], seed: nil)
    do {
        let data = try NSKeyedArchiver.archivedData(withRootObject: surface, requiringSecureCoding: true)
        guard let restored = try NSKeyedUnarchiver.unarchivedObject(ofClass: IOSurface.self, from: data) else {
            preconditionFailure("missing restored surface")
        }
        precondition(restored.width == 4)
        precondition(restored.height == 1)
        precondition(restored.pixelFormat == 0x4247_5241)
        precondition(restored.baseAddress.load(as: UInt32.self) == 0x1122_3344)
    } catch {
        preconditionFailure("coder round-trip \(error)")
    }
}

func testCoderMissingKeys() {
    let empty = NSKeyedArchiver(requiringSecureCoding: true)
    empty.encode(Int64(0), forKey: "not-a-surface")
    let data = empty.encodedData
    do {
        let restored = try NSKeyedUnarchiver.unarchivedObject(ofClass: IOSurface.self, from: data)
        precondition(restored == nil)
    } catch {
        // Fail-closed: a coder without geometry keys must not invent a surface.
    }
}
