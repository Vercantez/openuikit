import TabularData
import Foundation

func testCSVRoundTrip() {
    let csv = "name,age\na,10\nb,20\n"
    let frame = try! DataFrame(csvData: Data(csv.utf8))
    precondition(frame.shape.rows == 2)
    precondition(frame["name"].count == 2)
    let data = try! frame.csvRepresentation()
    precondition(!data.isEmpty)
    let json = try! frame.jsonRepresentation()
    precondition(!json.isEmpty)
    let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("td-round.csv")
    try! frame.writeCSV(to: tmp)
    let fromFile = try! DataFrame(contentsOfCSVFile: tmp)
    precondition(fromFile.shape.rows == 2)
    try! frame.writeJSON(to: tmp.appendingPathExtension("json"))
}

func testCSVColumnSelectionAndTypes() {
    let csv = "name,age,ok,score\na,1,true,1.5\nb,2,false,2.5\n"
    let frame = try! DataFrame(
        csvData: Data(csv.utf8),
        columns: ["name", "age"],
        rows: 0..<2,
        types: ["age": .integer, "name": .string]
    )
    precondition(frame.containsColumn("name"))
    precondition(!frame.containsColumn("score"))
    let typed = try! DataFrame(
        csvData: Data(csv.utf8),
        columns: ColumnID("age", Int.self)
    )
    precondition(typed.containsColumn("age"))
}

func testCSVBooleanAndNil() {
    let csv = "flag,note\ntrue,NA\nfalse,\n1,hello\n"
    let frame = try! DataFrame(
        csvData: Data(csv.utf8),
        types: ["flag": .boolean, "note": .string]
    )
    let flags: Column<Bool> = frame["flag", Bool.self]
    precondition(flags[0] == true)
}

func testCSVQuotedAndErrors() {
    let quoted = "name,note\n\"a,b\",\"x\"\"y\"\n"
    let frame = try! DataFrame(csvData: Data(quoted.utf8))
    precondition(frame.shape.rows == 1)
    do {
        _ = try DataFrame(csvData: Data([0xFF, 0xFE]))
        precondition(false)
    } catch is CSVReadingError {
    } catch {
        precondition(false, "unexpected \(error)")
    }
    do {
        _ = try DataFrame(csvData: Data("a,b\n1\n".utf8))
        precondition(false)
    } catch is CSVReadingError {
    } catch {
        precondition(false)
    }
    do {
        _ = try DataFrame(csvData: Data("a,b\n1,2\n".utf8), columns: ["missing"])
        precondition(false)
    } catch is CSVReadingError {
    } catch {
        precondition(false)
    }
}

func testCSVFilePackInit() {
    let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("td-pack.csv")
    try! Data("n,x\n1,2\n".utf8).write(to: tmp)
    let frame = try! DataFrame(contentsOfCSVFile: tmp, columns: ColumnID("n", Int.self))
    precondition(frame.containsColumn("n"))
}

func testJSONRoundTrip() {
    let json = """
    [{"name":"a","age":10},{"name":"b","age":20}]
    """
    let frame = try! DataFrame(jsonData: Data(json.utf8))
    precondition(frame.shape.rows == 2)
    let encoded = try! frame.jsonRepresentation(options: JSONWritingOptions())
    let again = try! DataFrame(jsonData: encoded)
    precondition(again.shape.rows == 2)
    let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("td.json")
    try! Data(json.utf8).write(to: tmp)
    let fromFile = try! DataFrame(contentsOfJSONFile: tmp)
    precondition(fromFile.shape.rows == 2)
}

func testJSONColumnDictionaryAndTypes() {
    let json = """
    {"name":["a","b"],"age":[1,2]}
    """
    let frame = try! DataFrame(jsonData: Data(json.utf8), columns: ["name"], types: ["name": .string])
    precondition(frame.shape.columns == 1)
}

func testJSONErrors() {
    do {
        _ = try DataFrame(jsonData: Data("123".utf8))
        precondition(false)
    } catch JSONReadingError.unsupportedStructure {
    } catch {
        precondition(false)
    }
}

func testSFrameFailClosed() {
    do {
        _ = try DataFrame(contentsOfSFrameDirectory: URL(fileURLWithPath: "/tmp/missing.sframe"))
        precondition(false)
    } catch let error as SFrameReadingError {
        switch error {
        case .unsupportedArchive:
            break
        default:
            precondition(false, "expected unsupportedArchive")
        }
    } catch {
        precondition(false)
    }
}

func testCSVWritingOptionsRoundTrip() {
    var options = CSVWritingOptions(includesHeader: true, nilEncoding: "NA")
    options.trueEncoding = "Y"
    let frame = DataFrame(columns: [
        AnyColumn(Column<Bool>(name: "ok", contents: [true, false, nil]))
    ])
    let data = try! frame.csvRepresentation(options: options)
    precondition(String(data: data, encoding: .utf8)!.contains("Y"))
}
