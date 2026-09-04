import Foundation
import OSLog

func testOSLogPortableContract() {
    precondition(OSLogPortable.backend == .standardError)
    precondition(!OSLogPortable.supportsUnifiedLogging)
    precondition(OSLogPortable.supportsSignposts)
    precondition(OSLogPortable.signpostIdentityScope == "process-local")
    precondition(OSLogPortable.StoreError.logArchiveUnavailable.code == 1)
}

func testOSLogEntryLogLevel() {
    let levels: [OSLogEntryLog.Level] = [
        .undefined, .debug, .info, .notice, .error, .fault
    ]
    let raw = [0, 1, 2, 3, 4, 5]
    for (level, value) in zip(levels, raw) {
        precondition(level.rawValue == value)
        precondition(OSLogEntryLog.Level(rawValue: value) == level)
    }
    precondition(OSLogEntryLog.Level(rawValue: 99) == nil)
    precondition(OSLogEntryLog.Level.debug != .error)
    precondition(OSLogEntryLog.Level.debug == .debug)
    var hasher = Hasher()
    OSLogEntryLog.Level.notice.hash(into: &hasher)
    _ = hasher.finalize()
    _ = OSLogEntryLog.Level.fault.hashValue
}

func testOSLogEntrySignpostType() {
    let types: [OSLogEntrySignpost.SignpostType] = [
        .undefined, .intervalBegin, .intervalEnd, .event
    ]
    let raw = [0, 1, 2, 3]
    for (type, value) in zip(types, raw) {
        precondition(type.rawValue == value)
        precondition(OSLogEntrySignpost.SignpostType(rawValue: value) == type)
    }
    precondition(OSLogEntrySignpost.SignpostType(rawValue: -1) == nil)
    precondition(OSLogEntrySignpost.SignpostType.event != .intervalBegin)
    var hasher = Hasher()
    OSLogEntrySignpost.SignpostType.intervalEnd.hash(into: &hasher)
    _ = hasher.finalize()
    _ = OSLogEntrySignpost.SignpostType.undefined.hashValue
}

func testOSLogEntryStoreCategory() {
    let categories: [OSLogEntry.StoreCategory] = [
        .undefined, .metadata, .shortTerm, .longTermAuto,
        .longTerm1, .longTerm3, .longTerm7, .longTerm14, .longTerm30
    ]
    let raw = [0, 1, 2, 3, 4, 5, 6, 7, 8]
    for (category, value) in zip(categories, raw) {
        precondition(category.rawValue == value)
        precondition(OSLogEntry.StoreCategory(rawValue: value) == category)
    }
    precondition(OSLogEntry.StoreCategory(rawValue: 42) == nil)
    precondition(OSLogEntry.StoreCategory.shortTerm != .metadata)
    var hasher = Hasher()
    OSLogEntry.StoreCategory.longTerm7.hash(into: &hasher)
    _ = hasher.finalize()
    _ = OSLogEntry.StoreCategory.longTerm30.hashValue
}

func testOSLogMessageComponentArgumentCategory() {
    let categories: [OSLogMessageComponent.ArgumentCategory] = [
        .undefined, .data, .double, .int64, .string, .uInt64
    ]
    let raw = [0, 1, 2, 3, 4, 5]
    for (category, value) in zip(categories, raw) {
        precondition(category.rawValue == value)
        precondition(OSLogMessageComponent.ArgumentCategory(rawValue: value) == category)
    }
    precondition(OSLogMessageComponent.ArgumentCategory(rawValue: 6) == nil)
    precondition(
        OSLogMessageComponent.ArgumentCategory.string
            != OSLogMessageComponent.ArgumentCategory.int64
    )
    var hasher = Hasher()
    OSLogMessageComponent.ArgumentCategory.double.hash(into: &hasher)
    _ = hasher.finalize()
    _ = OSLogMessageComponent.ArgumentCategory.uInt64.hashValue
}

func testOSLogStoreScope() {
    precondition(OSLogStore.Scope.currentProcessIdentifier.rawValue == 1)
    precondition(OSLogStore.Scope(rawValue: 1) == .currentProcessIdentifier)
    precondition(OSLogStore.Scope(rawValue: 0) == nil)
    precondition(OSLogStore.Scope(rawValue: 2) == nil)
    let scope = OSLogStore.Scope.currentProcessIdentifier
    precondition(scope == .currentProcessIdentifier)
    precondition(!(scope != .currentProcessIdentifier))
    var hasher = Hasher()
    scope.hash(into: &hasher)
    _ = hasher.finalize()
    _ = scope.hashValue
}

func testOSLogEnumeratorOptions() {
    var empty = OSLogEnumerator.Options()
    precondition(empty.isEmpty)
    precondition(empty.rawValue == 0)
    precondition(!empty.contains(.reverse))

    let reverse = OSLogEnumerator.Options.reverse
    precondition(reverse.rawValue == 1)
    precondition(OSLogEnumerator.Options(rawValue: 1) == reverse)
    precondition(OSLogEnumerator.Options(arrayLiteral: .reverse) == reverse)

    let fromSequence = OSLogEnumerator.Options([.reverse])
    precondition(fromSequence == reverse)

    precondition(reverse.contains(.reverse))
    precondition(reverse.isDisjoint(with: empty))
    precondition(!reverse.isDisjoint(with: reverse))
    precondition(reverse.isSuperset(of: empty))
    precondition(reverse.isSuperset(of: reverse))
    precondition(empty.isSubset(of: reverse))
    precondition(empty.isStrictSubset(of: reverse))
    precondition(reverse.isStrictSuperset(of: empty))
    precondition(!reverse.isStrictSubset(of: reverse))
    precondition(!reverse.isStrictSuperset(of: reverse))

    let unioned = empty.union(reverse)
    precondition(unioned == reverse)
    let intersected = reverse.intersection(reverse)
    precondition(intersected == reverse)
    precondition(reverse.intersection(empty).isEmpty)
    let subtracted = reverse.subtracting(reverse)
    precondition(subtracted.isEmpty)
    let symmetric = reverse.symmetricDifference(empty)
    precondition(symmetric == reverse)
    precondition(reverse.symmetricDifference(reverse).isEmpty)
    precondition(reverse != empty)

    empty.formUnion(reverse)
    precondition(empty == reverse)
    empty.formIntersection(.reverse)
    precondition(empty == reverse)
    empty.formSymmetricDifference(.reverse)
    precondition(empty.isEmpty)
    empty.insert(.reverse)
    precondition(empty.contains(.reverse))
    let removed = empty.remove(.reverse)
    precondition(removed == .reverse)
    precondition(empty.isEmpty)
    let updated = empty.update(with: .reverse)
    precondition(updated == nil)
    empty.subtract(.reverse)
    precondition(empty.isEmpty)

    var hasher = Hasher()
    reverse.hash(into: &hasher)
    _ = hasher.finalize()
}

func testOSLogMessageComponentArgument() {
    let undefined = OSLogMessageComponent.Argument.undefined
    let data = OSLogMessageComponent.Argument.data(Data([0x01, 0x02]))
    let double = OSLogMessageComponent.Argument.double(1.5)
    let signed = OSLogMessageComponent.Argument.signed(-7)
    let string = OSLogMessageComponent.Argument.string("visible")
    let unsigned = OSLogMessageComponent.Argument.unsigned(9)
    switch undefined {
    case .undefined:
        break
    default:
        preconditionFailure("undefined case")
    }
    switch data {
    case .data(let value):
        precondition(value == Data([0x01, 0x02]))
    default:
        preconditionFailure("data case")
    }
    switch double {
    case .double(let value):
        precondition(value == 1.5)
    default:
        preconditionFailure("double case")
    }
    switch signed {
    case .signed(let value):
        precondition(value == -7)
    default:
        preconditionFailure("signed case")
    }
    switch string {
    case .string(let value):
        precondition(value == "visible")
    default:
        preconditionFailure("string case")
    }
    switch unsigned {
    case .unsigned(let value):
        precondition(value == 9)
    default:
        preconditionFailure("unsigned case")
    }
}

func testOSLogStoreCurrentProcessEmpty() {
    let store = try! OSLogStore(scope: .currentProcessIdentifier)
    let entries = try! store.getEntries()
    precondition(Array(entries).isEmpty)
}

func testOSLogStoreURLFailClosed() {
    let url = URL(fileURLWithPath: "/tmp/oslog-missing.logarchive")
    var urlFailed = false
    do {
        _ = try OSLogStore(url: url)
    } catch let error as OSLogPortable.StoreError {
        precondition(error == .logArchiveUnavailable)
        urlFailed = true
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
    precondition(urlFailed)

    var labeledFailed = false
    do {
        _ = try OSLogStore(URL: url)
    } catch let error as OSLogPortable.StoreError {
        precondition(error == .logArchiveUnavailable)
        labeledFailed = true
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
    precondition(labeledFailed)
}

func testOSLogStorePosition() {
    let store = try! OSLogStore(scope: .currentProcessIdentifier)
    let date = Date(timeIntervalSince1970: 0)
    let atDate = store.position(date: date)
    let sinceEnd = store.position(timeIntervalSinceEnd: 30)
    let sinceBoot = store.position(timeIntervalSinceLatestBoot: 1.5)
    precondition(atDate !== sinceEnd)
    precondition(atDate !== sinceBoot)
    precondition(sinceEnd !== sinceBoot)
    precondition(String(describing: type(of: atDate)) == "OSLogPosition")
    precondition(String(describing: type(of: sinceEnd)) == "OSLogPosition")
    precondition(String(describing: type(of: sinceBoot)) == "OSLogPosition")
}

func testOSLogStoreGetEntries() {
    let store = try! OSLogStore(scope: .currentProcessIdentifier)
    let position = store.position(date: Date(timeIntervalSince1970: 1))
    let predicate = NSPredicate(value: true)
    let empty = try! store.getEntries(
        with: .reverse,
        at: position,
        matching: predicate
    )
    precondition(Array(empty).isEmpty)
    let defaults = try! store.getEntries(with: [], at: nil, matching: nil)
    precondition(Array(defaults).isEmpty)
}

func testOSLogStoreClassIdentity() {
    let store = try! OSLogStore(scope: .currentProcessIdentifier)
    precondition(String(describing: type(of: store)) == "OSLogStore")
    precondition(String(describing: OSLogStore.self).contains("OSLogStore"))
    precondition(String(describing: OSLogPosition.self).contains("OSLogPosition"))
}
