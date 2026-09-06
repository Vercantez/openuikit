import Foundation
@_spi(OpenUIKitHost) import GameSave

func testGSSyncStateType() {
    let values: [GSSyncState] = [
        .ready, .offline, .local, .syncing, .conflicted, .error, .closed,
    ]
    precondition(values.count == 7)
    precondition(type(of: GSSyncState.ready) == GSSyncState.self)
}

func testGSSyncStateRawValues() {
    let table: [(GSSyncState, Int)] = [
        (.ready, 0),
        (.offline, 1),
        (.local, 2),
        (.syncing, 3),
        (.conflicted, 4),
        (.error, 5),
        (.closed, 6),
    ]
    precondition(Set(table.map(\.0)).count == 7)
    precondition(Set(table.map(\.1)).count == 7)
    for (value, raw) in table {
        precondition(value.rawValue == raw)
        precondition(GSSyncState(rawValue: raw) == value)
    }
}

func testGSSyncStateInitRawValue() {
    precondition(GSSyncState(rawValue: 0) == .ready)
    precondition(GSSyncState(rawValue: 6) == .closed)
    precondition(GSSyncState(rawValue: 7) == nil)
    precondition(GSSyncState(rawValue: -1) == nil)
    precondition(GSSyncState(rawValue: Int.max) == nil)
}

func testGSSyncStateInequality() {
    precondition(GSSyncState.ready != .closed)
    precondition(GSSyncState.local != .syncing)
    precondition(!(GSSyncState.ready != .ready))
    precondition(GSSyncState.offline == .offline)
}

func testGSSyncStateHashValue() {
    precondition(GSSyncState.ready.hashValue == GSSyncState.ready.hashValue)
    precondition(GSSyncState.closed.hashValue == GSSyncState.closed.hashValue)
    precondition(GSSyncState.ready.hashValue != GSSyncState.closed.hashValue)
    _ = GSSyncState.syncing.hashValue
}

func testGSSyncStateHashInto() {
    var hasherA = Hasher()
    GSSyncState.conflicted.hash(into: &hasherA)
    var hasherB = Hasher()
    GSSyncState.conflicted.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())

    var hasherReady = Hasher()
    GSSyncState.ready.hash(into: &hasherReady)
    var hasherError = Hasher()
    GSSyncState.error.hash(into: &hasherError)
    precondition(hasherReady.finalize() != hasherError.finalize())
}
