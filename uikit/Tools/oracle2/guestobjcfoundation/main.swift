// Swift and Objective-C sharing one Foundation: every Objective-C object in
// this file comes from scenario/*.m and every Swift value crosses the bridge
// the way an unmodified app's does (NetNewsWire's RSDatabase over FMDB).
import Foundation
import OFScenario
import RSDatabaseObjC

func line(_ items: Any...) {
    print(items.map { "\($0)" }.joined(separator: " "))
}

OFFoundationScenario()

let probe = OFBridgeProbe(name: "Sw\u{00ef}ft")
line("bridge greeting", probe.greeting(), probe.name.count)
line("bridge length", probe.utf16Length(of: "h\u{00e9}llo \u{1F600}"))
let record = probe.record()
line("bridge record", record.count, record["title"] as? String ?? "?", record["count"] as? Int ?? -1,
     record["ratio"] as? Double ?? -1, record["flag"] as? Bool ?? false, (record["tags"] as? [String])?.joined(separator: "+") ?? "?",
     record["none"] is NSNull)
line("bridge describe", probe.describe(["b": 2, "a": "x", "c": [1, 2], "d": ["k": "v"]]))
line("bridge sum", probe.sum(of: [1, 2, 3, 40]))
line("bridge words", probe.words("one two three").joined(separator: "|"))
line("bridge data", probe.data(for: "d\u{00e4}ta").map { Array($0) } ?? [])
line("bridge set", probe.uniqueWords(["x", "y", "x"]).sorted().joined(separator: ","))
line("bridge date", probe.date(atInterval: 1234.5).timeIntervalSince1970)
do {
    try probe.fail(withCode: 0)
    line("bridge error none")
    try probe.fail(withCode: 42)
    line("bridge error missing")
} catch {
    let nsError = error as NSError
    line("bridge error", nsError.domain, nsError.code, nsError.localizedDescription)
}
line("bridge block", probe.transform("abc") { $0.uppercased() + "!" })

OFFMDBScenario()

// NetNewsWire's Swift call shapes (Modules/RSDatabase, ArticlesDatabase).
let database = FMDatabase(path: nil)!
line("swift fmdb open", database.open())
line("swift fmdb create", database.executeStatements("CREATE TABLE feeds (feedID TEXT PRIMARY KEY, name TEXT, unread INTEGER, updated DOUBLE)"))
let inserted = database.executeUpdate("INSERT INTO feeds VALUES (?, ?, ?, ?)",
                                      withArgumentsIn: ["feed1", "Daring Fireball", 7, Date(timeIntervalSince1970: 1_700_000_000)])
line("swift fmdb insert", inserted, database.lastInsertRowId(), database.changes())
line("swift fmdb rs insert", database.rs_insertRow(with: ["feedID": "feed2", "name": "Six Colors", "unread": 0], insertType: .orReplace, tableName: "feeds"))
if let results = database.executeQuery("SELECT * FROM feeds ORDER BY feedID", withArgumentsIn: []) {
    while results.next() {
        line("swift fmdb row", results.string(forColumn: "feedID") ?? "nil", results.string(forColumn: "name") ?? "nil",
             results.int(forColumn: "unread"), results.date(forColumn: "updated")?.timeIntervalSince1970 ?? -1,
             results.columnIsNull("updated"))
    }
    results.close()
}
if let ids = database.rs_selectColumn(withKey: "feedID", tableName: "feeds") {
    line("swift fmdb ids", ids.rs_arrayForSingleColumnResultSet().compactMap { $0 as? String }.sorted().joined(separator: ","))
}
line("swift fmdb placeholders", NSString.rs_SQLValueList(withPlaceholders: 2) ?? "nil")
line("swift fmdb close", database.close())
