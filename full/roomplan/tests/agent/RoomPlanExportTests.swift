import Foundation
import RoomPlan

func testExportInvalidScheme() {
    let room = CapturedRoom()
    do {
        try room.export(to: URL(string: "https://example.com/room.usdz")!)
        preconditionFailure("expected throw")
    } catch let error as CapturedRoom.Error {
        precondition(error == .urlInvalidScheme)
    } catch {
        preconditionFailure("wrong type")
    }
}

func testExportInvalidFilePath() {
    var components = URLComponents()
    components.scheme = "file"
    components.host = ""
    components.path = ""
    let url = components.url!
    do {
        try CapturedRoom().export(to: url)
        preconditionFailure("expected throw")
    } catch let error as CapturedRoom.Error {
        precondition(error == .urlInvalidFilePath || error == .urlMissingFileExtension)
    } catch {
        preconditionFailure("wrong type")
    }
}

func testExportMissingExtension() {
    do {
        try CapturedRoom().export(to: URL(fileURLWithPath: "/tmp/roomplan-no-ext"))
        preconditionFailure("expected throw")
    } catch let error as CapturedRoom.Error {
        precondition(error == .urlMissingFileExtension)
    } catch {
        preconditionFailure("wrong type")
    }
}

func testExportInvalidExtension() {
    do {
        try CapturedRoom().export(to: URL(fileURLWithPath: "/tmp/roomplan.txt"))
        preconditionFailure("expected throw")
    } catch let error as CapturedRoom.Error {
        precondition(error == .urlInvalidFileExtension)
    } catch {
        preconditionFailure("wrong type")
    }
}

func testExportDeviceNotSupported() {
    do {
        try CapturedRoom().export(to: URL(fileURLWithPath: "/tmp/roomplan-export.usdz"))
        preconditionFailure("expected throw")
    } catch let error as CapturedRoom.Error {
        precondition(error == .deviceNotSupported)
    } catch {
        preconditionFailure("wrong type")
    }
}

func testExportWithMetadataURL() {
    do {
        try CapturedRoom().export(
            to: URL(fileURLWithPath: "/tmp/roomplan-export.usdz"),
            metadataURL: URL(fileURLWithPath: "/tmp/roomplan-meta.json")
        )
        preconditionFailure("expected throw")
    } catch let error as CapturedRoom.Error {
        precondition(error == .urlInvalidFileExtension)
    } catch {
        preconditionFailure("wrong type")
    }
}

func testExportWithValidMetadataUSDZ() {
    do {
        try CapturedRoom().export(
            to: URL(fileURLWithPath: "/tmp/roomplan-export.usdz"),
            metadataURL: URL(fileURLWithPath: "/tmp/roomplan-meta.usdz"),
            modelProvider: CapturedRoom.ModelProvider(),
            exportOptions: .parametric
        )
        preconditionFailure("expected throw")
    } catch let error as CapturedRoom.Error {
        precondition(error == .deviceNotSupported)
    } catch {
        preconditionFailure("wrong type")
    }
}

func testStructureExportDeviceNotSupported() {
    let structure = CapturedStructure(rooms: [CapturedRoom()])
    do {
        try structure.export(to: URL(fileURLWithPath: "/tmp/structure.usdz"))
        preconditionFailure("expected throw")
    } catch let error as CapturedStructure.Error {
        precondition(error == .deviceNotSupported)
    } catch {
        preconditionFailure("wrong type")
    }
}

func testExportDefaultOptionsMesh() {
    do {
        try CapturedRoom().export(to: URL(fileURLWithPath: "/tmp/default.usdz"))
        preconditionFailure("expected throw")
    } catch let error as CapturedRoom.Error {
        precondition(error == .deviceNotSupported)
    } catch {
        preconditionFailure("wrong type")
    }
}

func testExportUSDExtensionsAcceptedThenFailClosed() {
    for name in ["room.usd", "room.usda", "room.usdc", "room.usdz"] {
        do {
            try CapturedRoom().export(to: URL(fileURLWithPath: "/tmp/\(name)"))
            preconditionFailure("expected throw")
        } catch let error as CapturedRoom.Error {
            precondition(error == .deviceNotSupported)
        } catch {
            preconditionFailure("wrong type")
        }
    }
}
