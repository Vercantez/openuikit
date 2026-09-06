#if canImport(Glibc)
import Glibc
#endif
import Foundation

private let SQLITE_OK: Int32 = 0
private let SQLITE_ROW: Int32 = 100
private let SQLITE_DONE: Int32 = 101
private typealias SQLiteDestructor = @convention(c) (UnsafeMutableRawPointer?) -> Void
private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: SQLiteDestructor.self)

private typealias SQLiteOpen = @convention(c) (UnsafePointer<CChar>?, UnsafeMutablePointer<OpaquePointer?>?) -> Int32
private typealias SQLiteClose = @convention(c) (OpaquePointer?) -> Int32
private typealias SQLiteExec = @convention(c) (
    OpaquePointer?,
    UnsafePointer<CChar>?,
    Optional<@convention(c) (UnsafeMutableRawPointer?, Int32, UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?, UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?) -> Int32>,
    UnsafeMutableRawPointer?,
    UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?
) -> Int32
private typealias SQLitePrepare = @convention(c) (
    OpaquePointer?,
    UnsafePointer<CChar>?,
    Int32,
    UnsafeMutablePointer<OpaquePointer?>?,
    UnsafeMutablePointer<UnsafePointer<CChar>?>?
) -> Int32
private typealias SQLiteStep = @convention(c) (OpaquePointer?) -> Int32
private typealias SQLiteFinalize = @convention(c) (OpaquePointer?) -> Int32
private typealias SQLiteBindText = @convention(c) (OpaquePointer?, Int32, UnsafePointer<CChar>?, Int32, SQLiteDestructor?) -> Int32
private typealias SQLiteColumnText = @convention(c) (OpaquePointer?, Int32) -> UnsafePointer<UInt8>?
private typealias SQLiteErrmsg = @convention(c) (OpaquePointer?) -> UnsafePointer<CChar>?
private typealias SQLiteFree = @convention(c) (UnsafeMutableRawPointer?) -> Void

private enum _CDSQLiteAPI {
    static let lock = NSLock()
    static var handle: UnsafeMutableRawPointer?
    static var open: SQLiteOpen?
    static var close: SQLiteClose?
    static var exec: SQLiteExec?
    static var prepare: SQLitePrepare?
    static var step: SQLiteStep?
    static var finalize: SQLiteFinalize?
    static var bindText: SQLiteBindText?
    static var columnText: SQLiteColumnText?
    static var errmsg: SQLiteErrmsg?
    static var free: SQLiteFree?

    static func load() throws {
        lock.lock()
        defer { lock.unlock() }
        if handle != nil { return }
        guard let loaded = dlopen("libsqlite3.so.0", RTLD_NOW) else {
            let message = dlerror().map { String(cString: $0) } ?? "dlopen failed"
            throw _CDMakeError(NSPersistentStoreOpenError, "libsqlite3.so.0 unavailable: \(message)")
        }
        func symbol<T>(_ name: String) throws -> T {
            guard let pointer = dlsym(loaded, name) else {
                throw _CDMakeError(NSSQLiteError, "missing sqlite symbol \(name)")
            }
            return unsafeBitCast(pointer, to: T.self)
        }
        handle = loaded
        open = try symbol("sqlite3_open")
        close = try symbol("sqlite3_close")
        exec = try symbol("sqlite3_exec")
        prepare = try symbol("sqlite3_prepare_v2")
        step = try symbol("sqlite3_step")
        finalize = try symbol("sqlite3_finalize")
        bindText = try symbol("sqlite3_bind_text")
        columnText = try symbol("sqlite3_column_text")
        errmsg = try symbol("sqlite3_errmsg")
        free = try symbol("sqlite3_free")
    }
}

final class _CDSQLiteConnection {
    private var db: OpaquePointer?

    init(path: String) throws {
        try _CDSQLiteAPI.load()
        var handle: OpaquePointer?
        let status = path.withCString { cPath in
            _CDSQLiteAPI.open?(cPath, &handle) ?? -1
        }
        db = handle
        if status != SQLITE_OK {
            let message = errorMessage()
            close()
            throw _CDMakeError(
                NSPersistentStoreOpenError,
                "sqlite3_open failed: \(message)",
                userInfo: [NSSQLiteErrorDomain: status]
            )
        }
    }

    deinit { close() }

    func close() {
        if let db {
            _ = _CDSQLiteAPI.close?(db)
            self.db = nil
        }
    }

    func errorMessage() -> String {
        guard let db, let message = _CDSQLiteAPI.errmsg?(db) else {
            return "sqlite error"
        }
        return String(cString: message)
    }

    func exec(_ sql: String) throws {
        var errorPointer: UnsafeMutablePointer<CChar>?
        let status = sql.withCString { cSQL in
            _CDSQLiteAPI.exec?(db, cSQL, nil, nil, &errorPointer) ?? -1
        }
        if let errorPointer {
            let message = String(cString: errorPointer)
            _CDSQLiteAPI.free?(UnsafeMutableRawPointer(errorPointer))
            if status != SQLITE_OK {
                throw _CDMakeError(NSSQLiteError, message)
            }
        } else if status != SQLITE_OK {
            throw _CDMakeError(NSSQLiteError, errorMessage())
        }
    }

    func query(_ sql: String, bind: [String] = []) throws -> [[String]] {
        var statement: OpaquePointer?
        let prepareStatus = sql.withCString { cSQL in
            _CDSQLiteAPI.prepare?(db, cSQL, -1, &statement, nil) ?? -1
        }
        guard prepareStatus == SQLITE_OK, let statement else {
            throw sqliteFailure(prepareStatus)
        }
        defer { _ = _CDSQLiteAPI.finalize?(statement) }
        for (index, value) in bind.enumerated() {
            let status = value.withCString { cValue in
                _CDSQLiteAPI.bindText?(statement, Int32(index + 1), cValue, -1, SQLITE_TRANSIENT) ?? -1
            }
            if status != SQLITE_OK {
                throw sqliteFailure(status)
            }
        }
        var rows: [[String]] = []
        while true {
            let step = _CDSQLiteAPI.step?(statement) ?? -1
            if step == SQLITE_DONE { break }
            if step != SQLITE_ROW {
                throw sqliteFailure(step)
            }
            var columns: [String] = []
            for column in 0..<8 {
                if let text = _CDSQLiteAPI.columnText?(statement, Int32(column)) {
                    columns.append(String(cString: text))
                } else {
                    columns.append("")
                }
            }
            rows.append(columns)
        }
        return rows
    }

    private func sqliteFailure(_ status: Int32) -> NSError {
        let message = errorMessage()
        if message.lowercased().contains("not a database") || message.lowercased().contains("malformed") {
            return _CDMakeError(NSPersistentStoreIncompatibleSchemaError, message)
        }
        return _CDMakeError(NSSQLiteError, message, userInfo: [NSSQLiteErrorDomain: status])
    }
}

protocol _CDRowStore: AnyObject {
    func _cdAllRows(entityNames: Set<String>) -> [_CDStoredRow]
    func _cdRow(for reference: String) -> _CDStoredRow?
    func _cdApplySave(inserted: [_CDStoredRow], updated: [_CDStoredRow], deleted: [String]) throws
}

func _CDApplySQLitePragmas(_ connection: _CDSQLiteConnection, options: [AnyHashable: Any]?) throws {
    let pragmas: [String: Any]
    if let typed = options?[NSSQLitePragmasOption] as? [String: Any] {
        pragmas = typed
    } else if let objects = options?[NSSQLitePragmasOption] as? [String: NSObject] {
        pragmas = objects
    } else {
        return
    }
    for (name, value) in pragmas {
        let safeName = String(name.filter { $0.isLetter || $0.isNumber || $0 == "_" })
        guard safeName == name, !name.isEmpty else { continue }
        let rendered: String
        if let number = value as? NSNumber {
            rendered = number.stringValue
        } else {
            rendered = String(describing: value)
        }
        let safeValue = String(rendered.filter { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" })
        guard !safeValue.isEmpty else { continue }
        try connection.exec("PRAGMA \(safeName) = \(safeValue)")
    }
}

extension _CDInMemoryPersistentStore: _CDRowStore {
    func _cdAllRows(entityNames: Set<String>) -> [_CDStoredRow] {
        backing.lock.lock()
        defer { backing.lock.unlock() }
        return backing.rows.values.filter { entityNames.contains($0.entityName) }
    }

    func _cdRow(for reference: String) -> _CDStoredRow? {
        backing.lock.lock()
        defer { backing.lock.unlock() }
        return backing.rows[reference]
    }

    func _cdApplySave(inserted: [_CDStoredRow], updated: [_CDStoredRow], deleted: [String]) throws {
        backing.lock.lock()
        defer { backing.lock.unlock() }
        for reference in deleted {
            backing.rows.removeValue(forKey: reference)
        }
        for row in inserted + updated {
            backing.rows[row.reference] = row
        }
    }
}

final class _CDSQLitePersistentStore: NSPersistentStore, _CDRowStore {
    private var connection: _CDSQLiteConnection?
    private let lock = NSLock()
    private var versionHashes: [String: String] = [:]

    override var type: String { NSSQLiteStoreType }

    required init(
        persistentStoreCoordinator root: NSPersistentStoreCoordinator?,
        configurationName name: String?,
        at url: URL,
        options: [AnyHashable: Any]? = nil
    ) {
        super.init(persistentStoreCoordinator: root, configurationName: name, at: url, options: options)
        metadata[NSStoreTypeKey] = NSSQLiteStoreType
    }

    override func loadMetadata() throws {
        guard let fileURL = url else {
            throw _CDMakeError(NSPersistentStoreOpenError, "SQLite store is missing a file URL")
        }
        if isReadOnly || (options?[NSReadOnlyPersistentStoreOption] as? Bool == true)
            || (options?[NSReadOnlyPersistentStoreOption] as? NSNumber)?.boolValue == true {
            isReadOnly = true
        }
        let conn = try _CDSQLiteConnection(path: fileURL.path)
        connection = conn
        do {
            try _CDApplySQLitePragmas(conn, options: options)
            try installSchemaIfNeeded(conn)
            try loadOrWriteMetadata(conn)
        } catch {
            conn.close()
            connection = nil
            throw error
        }
    }

    override func willRemove(from coordinator: NSPersistentStoreCoordinator?) {
        lock.lock()
        connection?.close()
        connection = nil
        lock.unlock()
        super.willRemove(from: coordinator)
    }

    func _cdAllRows(entityNames: Set<String>) -> [_CDStoredRow] {
        lock.lock()
        defer { lock.unlock() }
        guard let connection else { return [] }
        let sql = "SELECT reference, entity, payload FROM _cd_row"
        let rows = (try? connection.query(sql)) ?? []
        return rows.compactMap { columns in
            let reference = columns[0]
            let entity = columns[1]
            let payload = columns[2]
            guard entityNames.contains(entity),
                  let values = _CDDecodeStoredValues(payload) else {
                return nil
            }
            return _CDStoredRow(entityName: entity, reference: reference, values: values)
        }
    }

    func _cdRow(for reference: String) -> _CDStoredRow? {
        lock.lock()
        defer { lock.unlock() }
        guard let connection else { return nil }
        let rows = (try? connection.query(
            "SELECT reference, entity, payload FROM _cd_row WHERE reference = ?",
            bind: [reference]
        )) ?? []
        guard let columns = rows.first,
              let values = _CDDecodeStoredValues(columns[2]) else {
            return nil
        }
        return _CDStoredRow(entityName: columns[1], reference: columns[0], values: values)
    }

    func _cdApplySave(inserted: [_CDStoredRow], updated: [_CDStoredRow], deleted: [String]) throws {
        lock.lock()
        defer { lock.unlock() }
        if isReadOnly {
            throw _CDMakeError(NSPersistentStoreSaveError, "cannot save a read-only SQLite store")
        }
        guard let connection else {
            throw _CDMakeError(NSPersistentStoreSaveError, "SQLite store is not open")
        }
        try connection.exec("BEGIN")
        do {
            for reference in deleted {
                _ = try connection.query("DELETE FROM _cd_row WHERE reference = ?", bind: [reference])
            }
            for row in inserted + updated {
                let payload = try _CDEncodeStoredValues(row.values)
                _ = try connection.query(
                    "INSERT OR REPLACE INTO _cd_row(reference, entity, payload) VALUES (?, ?, ?)",
                    bind: [row.reference, row.entityName, payload]
                )
            }
            try connection.exec("COMMIT")
        } catch {
            try? connection.exec("ROLLBACK")
            throw error
        }
    }

    private func installSchemaIfNeeded(_ conn: _CDSQLiteConnection) throws {
        let tables = try conn.query("SELECT name FROM sqlite_master WHERE type = 'table'")
        let names = Set(tables.map { $0[0] }.filter { !$0.isEmpty })
        if names.isEmpty || names == ["sqlite_sequence"] {
            try conn.exec(
                """
                CREATE TABLE IF NOT EXISTS _cd_meta (
                    key TEXT PRIMARY KEY,
                    value TEXT NOT NULL
                );
                CREATE TABLE IF NOT EXISTS _cd_row (
                    reference TEXT PRIMARY KEY,
                    entity TEXT NOT NULL,
                    payload TEXT NOT NULL
                );
                CREATE INDEX IF NOT EXISTS _cd_row_entity ON _cd_row(entity);
                """
            )
            return
        }
        if names.contains("_cd_meta") && names.contains("_cd_row") {
            return
        }
        throw _CDMakeError(
            NSPersistentStoreIncompatibleSchemaError,
            "SQLite file is not a Linux CoreData store (missing _cd_meta/_cd_row)"
        )
    }

    private func loadOrWriteMetadata(_ conn: _CDSQLiteConnection) throws {
        let existing = (try? conn.query("SELECT key, value FROM _cd_meta")) ?? []
        var stored: [String: String] = [:]
        for row in existing where row.count >= 2 && !row[0].isEmpty {
            stored[row[0]] = row[1]
        }
        if let uuid = stored[NSStoreUUIDKey], !uuid.isEmpty {
            identifier = uuid
            metadata[NSStoreUUIDKey] = uuid
        }
        metadata[NSStoreTypeKey] = NSSQLiteStoreType
        if let hashes = stored[NSStoreModelVersionHashesKey], !hashes.isEmpty {
            versionHashes = _CDDecodeHashMap(hashes)
            let expected = _CDHashMap(persistentStoreCoordinator?.managedObjectModel)
            if !versionHashes.isEmpty, versionHashes != expected {
                throw _CDMakeError(
                    NSPersistentStoreIncompatibleVersionHashError,
                    "SQLite store model version hashes do not match the attached NSManagedObjectModel"
                )
            }
            metadata[NSStoreModelVersionHashesKey] = persistentStoreCoordinator?.managedObjectModel.entityVersionHashesByName
        } else if !isReadOnly {
            try persistMetadata(conn)
        }
    }

    private func persistMetadata(_ conn: _CDSQLiteConnection) throws {
        let uuid = identifier ?? UUID().uuidString
        identifier = uuid
        metadata[NSStoreUUIDKey] = uuid
        metadata[NSStoreTypeKey] = NSSQLiteStoreType
        let hashes = _CDHashMap(persistentStoreCoordinator?.managedObjectModel)
        versionHashes = hashes
        try conn.exec("DELETE FROM _cd_meta")
        _ = try conn.query(
            "INSERT INTO _cd_meta(key, value) VALUES (?, ?)",
            bind: [NSStoreTypeKey, NSSQLiteStoreType]
        )
        _ = try conn.query(
            "INSERT INTO _cd_meta(key, value) VALUES (?, ?)",
            bind: [NSStoreUUIDKey, uuid]
        )
        _ = try conn.query(
            "INSERT INTO _cd_meta(key, value) VALUES (?, ?)",
            bind: [NSStoreModelVersionHashesKey, _CDEncodeHashMap(hashes)]
        )
    }
}

func _CDReadSQLiteMetadata(at url: URL) throws -> [String: Any] {
    guard FileManager.default.fileExists(atPath: url.path) else {
        throw _CDMakeError(NSPersistentStoreOpenError, "SQLite store file does not exist")
    }
    let conn = try _CDSQLiteConnection(path: url.path)
    defer { conn.close() }
    let rows: [[String]]
    do {
        rows = try conn.query("SELECT key, value FROM _cd_meta")
    } catch {
        throw _CDMakeError(NSPersistentStoreIncompatibleSchemaError, "SQLite metadata table is missing")
    }
    var metadata: [String: Any] = [NSStoreTypeKey: NSSQLiteStoreType]
    for row in rows where row.count >= 2 && !row[0].isEmpty {
        if row[0] == NSStoreModelVersionHashesKey {
            metadata[row[0]] = _CDDecodeHashMap(row[1])
        } else {
            metadata[row[0]] = row[1]
        }
    }
    return metadata
}

func _CDWriteSQLiteMetadata(_ metadata: [String: Any]?, at url: URL) throws {
    guard FileManager.default.fileExists(atPath: url.path) else {
        throw _CDMakeError(NSPersistentStoreOpenError, "SQLite store file does not exist")
    }
    let conn = try _CDSQLiteConnection(path: url.path)
    defer { conn.close() }
    try conn.exec(
        """
        CREATE TABLE IF NOT EXISTS _cd_meta (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
        );
        """
    )
    try conn.exec("DELETE FROM _cd_meta")
    var payload = metadata ?? [:]
    payload[NSStoreTypeKey] = payload[NSStoreTypeKey] ?? NSSQLiteStoreType
    for (key, value) in payload {
        let text: String
        if let hashes = value as? [String: Data] {
            text = _CDEncodeHashMap(hashes.mapValues { $0.base64EncodedString() })
        } else {
            text = String(describing: value)
        }
        _ = try conn.query("INSERT INTO _cd_meta(key, value) VALUES (?, ?)", bind: [key, text])
    }
}

private func _CDHashMap(_ model: NSManagedObjectModel?) -> [String: String] {
    guard let model else { return [:] }
    var result: [String: String] = [:]
    for (name, data) in model.entityVersionHashesByName {
        result[name] = data.base64EncodedString()
    }
    return result
}

private func _CDEncodeHashMap(_ hashes: [String: String]) -> String {
    let object = hashes as NSDictionary
    if let data = try? JSONSerialization.data(withJSONObject: object),
       let text = String(data: data, encoding: .utf8) {
        return text
    }
    return "{}"
}

private func _CDDecodeHashMap(_ text: String) -> [String: String] {
    guard let data = text.data(using: .utf8),
          let object = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
        return [:]
    }
    return object
}

func _CDEncodeStoredValues(_ values: [String: Any]) throws -> String {
    var boxed: [String: Any] = [:]
    for (key, value) in values {
        boxed[key] = _CDJSONBox(value)
    }
    let data = try JSONSerialization.data(withJSONObject: boxed, options: [])
    return String(data: data, encoding: .utf8) ?? "{}"
}

func _CDDecodeStoredValues(_ payload: String) -> [String: Any]? {
    guard let data = payload.data(using: .utf8),
          let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        return [:]
    }
    var values: [String: Any] = [:]
    for (key, value) in object {
        values[key] = _CDJSONUnbox(value)
    }
    return values
}

private func _CDJSONBox(_ value: Any) -> Any {
    if value is NSNull {
        return NSNull()
    }
    if let token = value as? _CDRelationshipToken {
        return [
            "__cdRel": true,
            "toMany": token.isToMany,
            "uris": token.uris
        ] as [String: Any]
    }
    if let date = value as? Date {
        return ["__cdDate": date.timeIntervalSince1970] as [String: Any]
    }
    if let data = value as? Data {
        return ["__cdData": data.base64EncodedString()] as [String: Any]
    }
    if let uuid = value as? UUID {
        return ["__cdUUID": uuid.uuidString] as [String: Any]
    }
    if let url = value as? URL {
        return ["__cdURL": url.absoluteString] as [String: Any]
    }
    if let number = value as? NSNumber {
        return number
    }
    if let string = value as? String {
        return string
    }
    if let flag = value as? Bool {
        return NSNumber(value: flag)
    }
    if let number = value as? Int {
        return NSNumber(value: number)
    }
    if let number = value as? Int64 {
        return NSNumber(value: number)
    }
    if let number = value as? Double {
        return NSNumber(value: number)
    }
    if let number = value as? Float {
        return NSNumber(value: number)
    }
    return String(describing: value)
}

private func _CDJSONUnbox(_ value: Any) -> Any {
    if let dictionary = value as? [String: Any] {
        if dictionary["__cdRel"] as? Bool == true {
            return _CDRelationshipToken(
                uris: dictionary["uris"] as? [String] ?? [],
                isToMany: dictionary["toMany"] as? Bool ?? false
            )
        }
        if let interval = dictionary["__cdDate"] as? Double {
            return Date(timeIntervalSince1970: interval)
        }
        if let encoded = dictionary["__cdData"] as? String, let data = Data(base64Encoded: encoded) {
            return data
        }
        if let uuid = dictionary["__cdUUID"] as? String {
            return UUID(uuidString: uuid) ?? uuid
        }
        if let url = dictionary["__cdURL"] as? String {
            return URL(string: url) ?? url
        }
    }
    return value
}
