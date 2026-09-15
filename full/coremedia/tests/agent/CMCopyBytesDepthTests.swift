import CoreMedia
import Foundation

/// Exercises every `DataProtocol` / `ContiguousBytes` `copyBytes` overload the
/// Apple surface synthesizes for the three byte-projection hosts that carry no
/// custom shadowing overload: `CMReadOnlyDataBlockBuffer` and both
/// `BlockRegion` types. Each call checks byte fidelity against a known source.
/// Synchronous; no queues, no run loop, no waiting.
func testCMDataBlockBufferCopyBytesOverloads() {
    let source: [UInt8] = [0x10, 0x20, 0x30, 0x40]
    let readOnly = CMReadOnlyDataBlockBuffer(Data(source))
    let readRegion = readOnly.regions[0]
    var mutable = CMMutableDataBlockBuffer(count: 4)
    mutable[0] = 0x10
    mutable[1] = 0x20
    mutable[2] = 0x30
    mutable[3] = 0x40
    let mutableRegion = mutable.withUnsafeMutableBlockRegions { $0[0] }
    precondition(mutableRegion.count == 4)

    // copyBytes(to: UnsafeMutableRawBufferPointer, from:) -> Int.
    var raw = [UInt8](repeating: 0, count: 8)
    precondition(raw.withUnsafeMutableBytes { readOnly.copyBytes(to: $0, from: 0..<4) } == 4)
    precondition(Array(raw[0..<4]) == source)
    raw = [UInt8](repeating: 0, count: 8)
    precondition(raw.withUnsafeMutableBytes { readRegion.copyBytes(to: $0, from: 0..<4) } == 4)
    precondition(Array(raw[0..<4]) == source)
    raw = [UInt8](repeating: 0, count: 8)
    precondition(raw.withUnsafeMutableBytes { mutableRegion.copyBytes(to: $0, from: 0..<4) } == 4)
    precondition(Array(raw[0..<4]) == source)

    // copyBytes(to: UnsafeMutableBufferPointer, from:) -> Int.
    var typed = [UInt8](repeating: 0, count: 8)
    precondition(typed.withUnsafeMutableBufferPointer { readOnly.copyBytes(to: $0, from: 0..<4) } == 4)
    precondition(Array(typed[0..<4]) == source)
    typed = [UInt8](repeating: 0, count: 8)
    precondition(typed.withUnsafeMutableBufferPointer { readRegion.copyBytes(to: $0, from: 0..<4) } == 4)
    precondition(Array(typed[0..<4]) == source)
    typed = [UInt8](repeating: 0, count: 8)
    precondition(typed.withUnsafeMutableBufferPointer { mutableRegion.copyBytes(to: $0, from: 0..<4) } == 4)
    precondition(Array(typed[0..<4]) == source)

    // copyBytes(to: UnsafeMutableRawBufferPointer, count:) -> Int.
    var counted = [UInt8](repeating: 0, count: 8)
    precondition(counted.withUnsafeMutableBytes { readOnly.copyBytes(to: $0, count: 2) } == 2)
    precondition(Array(counted[0..<2]) == Array(source[0..<2]))
    precondition(counted[2] == 0)
    counted = [UInt8](repeating: 0, count: 8)
    precondition(counted.withUnsafeMutableBytes { readRegion.copyBytes(to: $0, count: 2) } == 2)
    precondition(Array(counted[0..<2]) == Array(source[0..<2]))
    counted = [UInt8](repeating: 0, count: 8)
    precondition(counted.withUnsafeMutableBytes { mutableRegion.copyBytes(to: $0, count: 2) } == 2)
    precondition(Array(counted[0..<2]) == Array(source[0..<2]))

    // copyBytes(to: UnsafeMutableBufferPointer, count:) -> Int (read-only host).
    var typedCounted = [UInt8](repeating: 0, count: 8)
    precondition(typedCounted.withUnsafeMutableBufferPointer { readOnly.copyBytes(to: $0, count: 2) } == 2)
    precondition(Array(typedCounted[0..<2]) == Array(source[0..<2]))

    // copyBytes(to:) -> Int, whole contents.
    var whole = [UInt8](repeating: 0, count: 8)
    precondition(whole.withUnsafeMutableBytes { readOnly.copyBytes(to: $0) } == 4)
    precondition(Array(whole[0..<4]) == source)
    whole = [UInt8](repeating: 0, count: 8)
    precondition(whole.withUnsafeMutableBytes { readRegion.copyBytes(to: $0) } == 4)
    precondition(Array(whole[0..<4]) == source)
    whole = [UInt8](repeating: 0, count: 8)
    precondition(whole.withUnsafeMutableBytes { mutableRegion.copyBytes(to: $0) } == 4)
    precondition(Array(whole[0..<4]) == source)
    var wholeTyped = [UInt8](repeating: 0, count: 8)
    precondition(wholeTyped.withUnsafeMutableBufferPointer { readOnly.copyBytes(to: $0) } == 4)
    precondition(Array(wholeTyped[0..<4]) == source)

    // ContiguousBytes-constrained copyBytes(to:from:) -> Void, exact fit.
    var exactRead = [UInt8](repeating: 0, count: 4)
    exactRead.withUnsafeMutableBufferPointer { readRegion.copyBytes(to: $0, from: 0..<4) }
    precondition(exactRead == source)
    var exactMutable = [UInt8](repeating: 0, count: 4)
    exactMutable.withUnsafeMutableBufferPointer { mutableRegion.copyBytes(to: $0, from: 0..<4) }
    precondition(exactMutable == source)
}
