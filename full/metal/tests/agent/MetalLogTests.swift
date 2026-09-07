import Foundation
import Metal

/// Exercises the host log container as an empty, deterministic Sequence.  The
/// software command buffer never fabricates GPU shader log entries.
func testLogContainerSequenceSurface() {
    let logs = MTLCreateSystemDefaultDevice()!.makeCommandQueue()!.makeCommandBuffer()!.logs
    precondition(Array(logs).isEmpty)
    precondition(logs.underestimatedCount == 0)
    precondition(logs.allSatisfy { _ in false })
    precondition(logs.first(where: { _ in true }) == nil)
    precondition(logs.filter { _ in true }.isEmpty)
    precondition(logs.compactMap { _ in Optional<Int>.some(1) }.isEmpty)
    precondition(logs.flatMap { _ in [1] }.isEmpty)
    precondition(logs.reduce(0) { value, _ in value + 1 } == 0)
    let reduced = logs.reduce(into: 0) { value, _ in value += 1 }
    precondition(reduced == 0)
    precondition(Array(logs.enumerated()).isEmpty)
    precondition(Array(logs.prefix(2)).isEmpty)
    precondition(logs.prefix { _ in true }.isEmpty)
    precondition(logs.suffix(2).isEmpty)
    precondition(Array(logs.dropFirst()).isEmpty)
    precondition(logs.dropLast().isEmpty)
    precondition(Array(logs.drop { _ in false }).isEmpty)
    precondition(logs.reversed().isEmpty)
    precondition(logs.split(whereSeparator: { _ in false }).isEmpty)
    precondition(Array(logs.lazy).prefix(1).isEmpty)
    var visits = 0
    logs.forEach { _ in visits += 1 }
    precondition(visits == 0)
    precondition(logs.elementsEqual(logs, by: { _, _ in true }))
    precondition(!logs.lexicographicallyPrecedes(logs, by: { _, _ in false }))
    precondition(logs.starts(with: logs, by: { _, _ in true }))
    precondition(logs.sorted(by: { _, _ in false }).isEmpty)
    _ = logs.withContiguousStorageIfAvailable { $0.count }
    var generator = SystemRandomNumberGenerator()
    precondition(logs.shuffled(using: &generator).isEmpty)
    precondition(logs.shuffled().isEmpty)
}
