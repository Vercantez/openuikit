import Foundation
import OSLog

/// Darwin uses `NSPredicate(format:)` (Apple Foundation). Linux corelibs
/// marks that initializer unavailable; the store evaluates `NSPredicate(block:)`
/// against the entry. The block replays the same documented keys the Darwin
/// parser reads off `predicateFormat`.
func oslogPredicate(_ format: String, _ args: CVarArg...) -> NSPredicate {
    oslogPredicateArgs(format, Array(args))
}

func oslogPredicateArgs(_ format: String, _ args: [Any]) -> NSPredicate {
#if os(Linux)
    return NSPredicate { object, _ in
        guard let entry = object as? OSLogEntry else { return false }
        return oslogLinuxFormatMatches(format, args, entry)
    }
#else
    return NSPredicate(format: format, argumentArray: args)
#endif
}

#if os(Linux)
func oslogLinuxFormatMatches(_ format: String, _ args: [Any], _ entry: OSLogEntry) -> Bool {
    var filled = ""
    var index = format.startIndex
    var argIndex = 0
    while index < format.endIndex {
        if format[index] == "%" {
            let next = format.index(after: index)
            if next < format.endIndex {
                let spec = format[next]
                if spec == "@" {
                    filled.append("\"")
                    filled.append(String(describing: args[argIndex]))
                    filled.append("\"")
                    argIndex += 1
                    index = format.index(after: next)
                    continue
                }
                if spec == "d" {
                    filled.append(String(describing: args[argIndex]))
                    argIndex += 1
                    index = format.index(after: next)
                    continue
                }
            }
        }
        filled.append(format[index])
        index = format.index(after: index)
    }
    return oslogLinuxEvalAnd(filled, entry)
}

func oslogLinuxEvalAnd(_ format: String, _ entry: OSLogEntry) -> Bool {
    var clause = ""
    var index = format.startIndex
    while index < format.endIndex {
        if format[index...].hasPrefix(" AND ") {
            if !oslogLinuxEvalClause(clause, entry) { return false }
            clause = ""
            index = format.index(index, offsetBy: 5)
            continue
        }
        clause.append(format[index])
        index = format.index(after: index)
    }
    return oslogLinuxEvalClause(clause, entry)
}

func oslogLinuxEvalClause(_ clause: String, _ entry: OSLogEntry) -> Bool {
    var text = clause
    while text.hasPrefix(" ") { text.removeFirst() }
    while text.hasSuffix(" ") { text.removeLast() }
    if let found = oslogLinuxSplit(text, " CONTAINS ") {
        return oslogLinuxContains(oslogLinuxValue(found.0, entry), found.1)
    }
    if let found = oslogLinuxSplit(text, " == ") {
        return oslogLinuxEqual(oslogLinuxValue(found.0, entry), found.1)
    }
    return true
}

func oslogLinuxSplit(_ text: String, _ token: String) -> (String, String)? {
    var index = text.startIndex
    while index < text.endIndex {
        if text[index...].hasPrefix(token) {
            let left = String(text[text.startIndex..<index])
            let right = String(text[text.index(index, offsetBy: token.count)...])
            return (left, right)
        }
        index = text.index(after: index)
    }
    return nil
}

func oslogLinuxValue(_ key: String, _ entry: OSLogEntry) -> Any? {
    if key == "composedMessage" || key == "eventMessage" {
        return entry.composedMessage
    }
    if let payload = entry as? OSLogEntryWithPayload {
        if key == "subsystem" { return payload.subsystem }
        if key == "category" { return payload.category }
    }
    if let log = entry as? OSLogEntryLog {
        if key == "level" { return log.level.rawValue }
        if key == "messageType" {
            switch log.level {
            case .debug: return 2
            case .info: return 1
            case .notice: return 0
            case .error: return 16
            case .fault: return 17
            case .undefined: return 0
            }
        }
    }
    return nil
}

func oslogLinuxEqual(_ lhs: Any?, _ rawRight: String) -> Bool {
    var right = rawRight
    while right.hasPrefix(" ") { right.removeFirst() }
    while right.hasSuffix(" ") { right.removeLast() }
    if right.hasPrefix("\"") && right.hasSuffix("\"") && right.count >= 2 {
        let inner = String(right.dropFirst().dropLast())
        if let name = oslogLinuxMessageTypeName(lhs) {
            return name == inner
        }
        return String(describing: lhs ?? "") == inner
    }
    if let ln = lhs as? Int, let rn = Int(right) {
        return ln == rn
    }
    return String(describing: lhs ?? "") == right
}

func oslogLinuxMessageTypeName(_ lhs: Any?) -> String? {
    guard let number = lhs as? Int else { return nil }
    switch number {
    case 0: return "default"
    case 1: return "info"
    case 2: return "debug"
    case 16: return "error"
    case 17: return "fault"
    default: return nil
    }
}

func oslogLinuxContains(_ lhs: Any?, _ rawRight: String) -> Bool {
    var right = rawRight
    while right.hasPrefix(" ") { right.removeFirst() }
    while right.hasSuffix(" ") { right.removeLast() }
    if right.hasPrefix("\"") && right.hasSuffix("\"") && right.count >= 2 {
        right = String(right.dropFirst().dropLast())
    }
    let haystack = String(describing: lhs ?? "")
    var index = haystack.startIndex
    while index < haystack.endIndex {
        if haystack[index...].hasPrefix(right) { return true }
        index = haystack.index(after: index)
    }
    return false
}
#endif

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
    let missing = oslogPredicate("subsystem == %@", "com.openuikit.oslog.never")
    let entries = try! store.getEntries(matching: missing)
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
    let subsystem = "com.openuikit.oslog.getentries"
    let logger = Logger(subsystem: subsystem, category: "rows")
    logger.notice("GET first")
    logger.error("GET second")
    let store = try! OSLogStore(scope: .currentProcessIdentifier)
    let predicate = oslogPredicate("subsystem == %@", subsystem)
    let forward = Array(try! store.getEntries(matching: predicate))
    precondition(forward.count == 2)
    precondition(forward[0].composedMessage == "GET first")
    precondition(forward[1].composedMessage == "GET second")
    let reversed = Array(try! store.getEntries(with: .reverse, matching: predicate))
    precondition(reversed.count == 2)
    precondition(reversed[0].composedMessage == "GET second")
    precondition(reversed[1].composedMessage == "GET first")
    let early = store.position(date: Date(timeIntervalSince1970: 1))
    let sinceEpoch = Array(try! store.getEntries(at: early, matching: predicate))
    precondition(sinceEpoch.count == 2)
    let future = store.position(date: Date().addingTimeInterval(3600))
    let none = Array(try! store.getEntries(at: future, matching: predicate))
    precondition(none.isEmpty)
}

func testOSLogStoreClassIdentity() {
    let store = try! OSLogStore(scope: .currentProcessIdentifier)
    precondition(String(describing: type(of: store)) == "OSLogStore")
    precondition(String(describing: OSLogStore.self).hasSuffix("OSLogStore"))
    precondition(String(describing: OSLogPosition.self).hasSuffix("OSLogPosition"))
}

func testOSLogEntryFromStore() {
    let subsystem = "com.openuikit.oslog.entry"
    Logger(subsystem: subsystem, category: "base").notice("ENTRY hello")
    let store = try! OSLogStore(scope: .currentProcessIdentifier)
    let rows = Array(
        try! store.getEntries(
            matching: oslogPredicate("subsystem == %@", subsystem)
        )
    )
    precondition(rows.count == 1)
    let entry = rows[0]
    precondition(entry.composedMessage == "ENTRY hello")
    precondition(entry.date.timeIntervalSinceNow < 5)
    precondition(entry.storeCategory == .undefined)
    precondition(entry.storeCategory.rawValue == 0)
    precondition(type(of: entry) == OSLogEntryLog.self)
}

func testOSLogEntryLogFields() {
    let subsystem = "com.openuikit.oslog.logfields"
    Logger(subsystem: subsystem, category: "net").error("LOG fields")
    let store = try! OSLogStore(scope: .currentProcessIdentifier)
    let rows = Array(
        try! store.getEntries(
            matching: oslogPredicate("subsystem == %@", subsystem)
        )
    )
    precondition(rows.count == 1)
    let log = rows[0] as! OSLogEntryLog
    precondition(log.level == .error)
    precondition(log.subsystem == subsystem)
    precondition(log.category == "net")
    precondition(log.formatString == "LOG fields")
    precondition(log.process == ProcessInfo.processInfo.processName)
    precondition(log.sender == log.process)
    precondition(log.processIdentifier == pid_t(ProcessInfo.processInfo.processIdentifier))
    precondition(log.threadIdentifier != 0)
    precondition(log.activityIdentifier == 0)
    let from: OSLogEntryFromProcess = log
    precondition(from.process == log.process)
    let payload: OSLogEntryWithPayload = log
    precondition(payload.subsystem == subsystem)
}

func testOSLogEntrySignpostFields() {
    let subsystem = "com.openuikit.oslog.sign"
    let poster = OSSignposter(subsystem: subsystem, category: "span")
    let sid = poster.makeSignpostID()
    precondition(sid != .invalid)
    precondition(sid != .null)
    precondition(OSSignpostID.exclusive.rawValue == 0xEEEEB0B5B2B2EEEE)
    precondition(OSSignpostID.invalid.rawValue == UInt64.max)
    precondition(OSSignpostID.null.rawValue == 0)
    let state = poster.beginInterval("work", id: sid)
    poster.emitEvent("tick", id: sid)
    poster.endInterval("work", state)
    let store = try! OSLogStore(scope: .currentProcessIdentifier)
    let rows = Array(
        try! store.getEntries(
            matching: oslogPredicate("subsystem == %@", subsystem)
        )
    )
    precondition(rows.count == 3)
    let begin = rows[0] as! OSLogEntrySignpost
    let event = rows[1] as! OSLogEntrySignpost
    let end = rows[2] as! OSLogEntrySignpost
    precondition(begin.signpostName == "work")
    precondition(begin.signpostType == .intervalBegin)
    precondition(begin.signpostIdentifier == sid.rawValue)
    precondition(event.signpostType == .event)
    precondition(event.signpostName == "tick")
    precondition(end.signpostType == .intervalEnd)
    precondition(end.signpostIdentifier == begin.signpostIdentifier)
}

func testOSLogMessageComponentFromStore() {
    let subsystem = "com.openuikit.oslog.components"
    let logger = Logger(subsystem: subsystem, category: "args")
    logger.log("STR \("hunter2", privacy: .public)")
    logger.log("INT \(Int64(42), privacy: .public)")
    logger.log("DBL \(1.5, privacy: .public)")
    logger.log("U64 \(UInt64(9), privacy: .public)")
    logger.log("DAT \(Data([0x6F, 0x73]), privacy: .public)")
    let store = try! OSLogStore(scope: .currentProcessIdentifier)
    let rows = Array(
        try! store.getEntries(
            matching: oslogPredicate("subsystem == %@", subsystem)
        )
    ).compactMap { $0 as? OSLogEntryLog }
    precondition(rows.count == 5)

    let str = rows[0].components[0]
    precondition(str.argumentCategory == .string)
    precondition(str.argumentStringValue == "hunter2")
    precondition(str.placeholder == "%{public}s")
    precondition(str.formatSubstring == "STR ")
    switch str.argument {
    case .string(let value):
        precondition(value == "hunter2")
    default:
        preconditionFailure("string argument")
    }
    precondition(rows[0].components.count == 2)
    precondition(rows[0].components[1].argumentCategory == .undefined)

    let intc = rows[1].components[0]
    precondition(intc.argumentCategory == .int64)
    precondition(intc.argumentInt64Value == 42)
    precondition(intc.argumentNumberValue?.int64Value == 42)
    switch intc.argument {
    case .signed(let value):
        precondition(value == 42)
    default:
        preconditionFailure("signed argument")
    }

    let dbl = rows[2].components[0]
    precondition(dbl.argumentCategory == .double)
    precondition(dbl.argumentDoubleValue == 1.5)

    let u64 = rows[3].components[0]
    precondition(u64.argumentCategory == .uInt64)
    precondition(u64.argumentUInt64Value == 9)
    switch u64.argument {
    case .unsigned(let value):
        precondition(value == 9)
    default:
        preconditionFailure("unsigned argument")
    }

    let data = rows[4].components[0]
    precondition(data.argumentCategory == .data)
    precondition(data.argumentDataValue == Data([0x6F, 0x73]))
    switch data.argument {
    case .data(let value):
        precondition(value == Data([0x6F, 0x73]))
    default:
        preconditionFailure("data argument")
    }
}

func testOSLogEnumeratorYieldsEntries() {
    let subsystem = "com.openuikit.oslog.enum"
    Logger(subsystem: subsystem, category: "walk").notice("ENUM a")
    Logger(subsystem: subsystem, category: "walk").notice("ENUM b")
    let store = try! OSLogStore(scope: .currentProcessIdentifier)
    let sequence = try! store.getEntries(
        matching: oslogPredicate("subsystem == %@", subsystem)
    )
    var seen: [String] = []
    for entry in sequence {
        seen.append(entry.composedMessage)
    }
    precondition(seen.count == 2)
    precondition(seen[0] == "ENUM a")
    precondition(seen[1] == "ENUM b")
    precondition(String(describing: OSLogEnumerator.self).hasSuffix("OSLogEnumerator"))
}

func testOSLogPrivacyRedaction() {
    let subsystem = "com.openuikit.oslog.privacy"
    let logger = Logger(subsystem: subsystem, category: "priv")
    logger.log("PUB \("visible", privacy: .public)")
    logger.log("PRV \("hunter2", privacy: .private)")
    logger.log("SEN \("hunter2", privacy: .sensitive)")
    logger.log("HSH \("hunter2", privacy: .private(mask: .hash))")
    logger.log("SINT \(42, privacy: .sensitive)")
    let store = try! OSLogStore(scope: .currentProcessIdentifier)
    let rows = Array(
        try! store.getEntries(
            matching: oslogPredicate("subsystem == %@", subsystem)
        )
    )
    precondition(rows[0].composedMessage == "PUB visible")
    // Probe: private is visible in currentProcessIdentifier composedMessage.
    precondition(rows[1].composedMessage == "PRV hunter2")
    // Probe + Apple docs: sensitive is "<private>" even in-process.
    precondition(rows[2].composedMessage == "SEN <private>")
    precondition(rows[3].composedMessage == "HSH hunter2")
    let hashed = rows[3] as! OSLogEntryLog
    precondition(hashed.formatString == "HSH %{private,mask.hash}s")
    precondition(rows[4].composedMessage == "SINT <private>")
}

func testOSLogLoggerLevels() {
    let subsystem = "com.openuikit.oslog.levels"
    let logger = Logger(subsystem: subsystem, category: "lvl")
    logger.log("L log")
    logger.trace("L trace")
    logger.debug("L debug")
    logger.info("L info")
    logger.notice("L notice")
    logger.warning("L warning")
    logger.error("L error")
    logger.critical("L critical")
    logger.fault("L fault")
    logger.log(level: .info, "L log-info")
    logger.log(level: .default, "L log-default")
    logger.log(level: .error, "L log-error")
    logger.log(level: .fault, "L log-fault")
    logger.log(level: .debug, "L log-debug")
    let store = try! OSLogStore(scope: .currentProcessIdentifier)
    let rows = Array(
        try! store.getEntries(
            matching: oslogPredicate("subsystem == %@", subsystem)
        )
    ).compactMap { $0 as? OSLogEntryLog }
    func level(of message: String) -> OSLogEntryLog.Level {
        rows.first(where: { $0.composedMessage == message })!.level
    }
    precondition(level(of: "L log") == .notice)
    precondition(level(of: "L trace") == .debug)
    precondition(level(of: "L debug") == .debug)
    precondition(level(of: "L info") == .info)
    precondition(level(of: "L notice") == .notice)
    precondition(level(of: "L warning") == .error)
    precondition(level(of: "L error") == .error)
    precondition(level(of: "L critical") == .fault)
    precondition(level(of: "L fault") == .fault)
    precondition(level(of: "L log-info") == .info)
    precondition(level(of: "L log-default") == .notice)
    precondition(level(of: "L log-error") == .error)
    precondition(level(of: "L log-fault") == .fault)
    precondition(level(of: "L log-debug") == .debug)
    precondition(OSLogType.default.rawValue == 0)
    precondition(OSLogType.info.rawValue == 1)
    precondition(OSLogType.debug.rawValue == 2)
    precondition(OSLogType.error.rawValue == 0x10)
    precondition(OSLogType.fault.rawValue == 0x11)
}

func testOSLogPredicateKeys() {
    let subsystem = "com.openuikit.oslog.pred"
    Logger(subsystem: subsystem, category: "one").info("PRED info")
    Logger(subsystem: subsystem, category: "one").notice("PRED notice")
    Logger(subsystem: subsystem, category: "two").error("PRED error")
    Logger(subsystem: subsystem, category: "two").fault("PRED fault")
    let store = try! OSLogStore(scope: .currentProcessIdentifier)
    func count(_ format: String, _ args: CVarArg...) -> Int {
        let predicate = oslogPredicateArgs(format, Array(args))
        return Array(try! store.getEntries(matching: predicate)).count
    }
    precondition(count("subsystem == %@", subsystem) == 4)
    precondition(count("subsystem == %@ AND category == %@", subsystem, "two") == 2)
    precondition(count("subsystem == %@ AND messageType == %@", subsystem, "error") == 1)
    precondition(count("subsystem == %@ AND messageType == %d", subsystem, 0x10) == 1)
    precondition(count("subsystem == %@ AND messageType == %@", subsystem, "default") == 1)
    precondition(count("subsystem == %@ AND messageType == %d", subsystem, 0) == 1)
    precondition(count("subsystem == %@ AND messageType == %@", subsystem, "fault") == 1)
    precondition(count("subsystem == %@ AND messageType == %d", subsystem, 17) == 1)
    precondition(count("subsystem == %@ AND messageType == %@", subsystem, "info") == 1)
    precondition(count("subsystem == %@ AND level == %d", subsystem, 4) == 1)
    precondition(count("subsystem == %@ AND eventMessage CONTAINS %@", subsystem, "PRED error") == 1)
    precondition(count("subsystem == %@", "com.openuikit.oslog.never") == 0)
}

func testOSLogCFormat() {
    let log = OSLog(subsystem: "com.openuikit.oslog.cformat", category: "clog")
    os_log("%@", log: log, type: .info, "visible-at" as NSString)
    os_log("%{public}@", log: log, type: .info, "visible-public" as NSString)
    os_log("%{private}@", log: log, type: .info, "hidden-private" as NSString)
    os_log("%d", log: log, type: .default, 7)
    os_log("%{public}d", log: log, type: .default, 8)
    os_log("%{private}d", log: log, type: .default, 9)
    os_log("%{public}s", log: log, type: .info, "cstr-public")
    os_log("%s", log: log, type: .info, "cstr-auto")
    let store = try! OSLogStore(scope: .currentProcessIdentifier)
    let rows = Array(
        try! store.getEntries(
            matching: oslogPredicate("subsystem == %@", log.subsystem)
        )
    )
    precondition(rows.count == 8)
    precondition(rows[0].composedMessage == "visible-at")
    precondition(rows[1].composedMessage == "visible-public")
    precondition(rows[2].composedMessage == "hidden-private")
    precondition(rows[3].composedMessage == "7")
    precondition(rows[4].composedMessage == "8")
    precondition(rows[5].composedMessage == "9")
    precondition(rows[6].composedMessage == "cstr-public")
    precondition(rows[7].composedMessage == "cstr-auto")
    let info = rows[0] as! OSLogEntryLog
    precondition(info.level == .info)
    precondition(info.formatString == "%@")
}
