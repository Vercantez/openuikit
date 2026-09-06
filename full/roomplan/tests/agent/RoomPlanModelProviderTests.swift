import Foundation
import RoomPlan

func roomPlanTemporaryModelURL() -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("roomplan-model-\(UUID().uuidString).usdz")
    try! Data([0x75, 0x73, 0x64]).write(to: url)
    return url
}

func testModelProviderInitEmpty() {
    let provider = CapturedRoom.ModelProvider()
    precondition(provider.modelFileURLs.isEmpty)
}

func testModelProviderSetAndGetCategory() {
    let url = roomPlanTemporaryModelURL()
    defer { try? FileManager.default.removeItem(at: url) }
    var provider = CapturedRoom.ModelProvider()
    try! provider.setModelFileURL(url, for: .chair)
    let fetched = try! provider.modelFileURL(for: .chair)
    precondition(fetched == url)
    precondition(try! provider.modelFileURL(for: .sofa) == nil)
}

func testModelProviderMissingFile() {
    var provider = CapturedRoom.ModelProvider()
    let missing = URL(fileURLWithPath: "/tmp/roomplan-absent-\(UUID().uuidString).usdz")
    do {
        try provider.setModelFileURL(missing, for: .table)
        preconditionFailure("expected throw")
    } catch CapturedRoom.ModelProvider.Error.nonExistingFile(let url) {
        precondition(url.path == missing.path)
    } catch {
        preconditionFailure("wrong error")
    }
}

func testModelProviderClearURL() {
    let url = roomPlanTemporaryModelURL()
    defer { try? FileManager.default.removeItem(at: url) }
    var provider = CapturedRoom.ModelProvider()
    try! provider.setModelFileURL(url, for: .storage)
    try! provider.setModelFileURL(nil, for: .storage)
    precondition(try! provider.modelFileURL(for: .storage) == nil)
}

func testModelProviderAttributeCombination() {
    let url = roomPlanTemporaryModelURL()
    defer { try? FileManager.default.removeItem(at: url) }
    var provider = CapturedRoom.ModelProvider()
    try! provider.setModelFileURL(url, for: [ChairType.stool, ChairLegType.star])
    let fetched = try! provider.modelFileURL(for: [ChairType.stool, ChairLegType.star])
    precondition(fetched == url)
}

func testModelProviderUnsupportedCombination() {
    var provider = CapturedRoom.ModelProvider()
    let url = roomPlanTemporaryModelURL()
    defer { try? FileManager.default.removeItem(at: url) }
    do {
        try provider.setModelFileURL(url, for: [ChairType.stool, SofaType.rectangular])
        preconditionFailure("expected throw")
    } catch CapturedRoom.ModelProvider.Error.attributeCombinationNotSupported {
        // expected
    } catch {
        preconditionFailure("wrong error")
    }
    do {
        _ = try provider.modelFileURL(for: [ChairType.dining, SofaType.lShaped])
        preconditionFailure("expected throw")
    } catch CapturedRoom.ModelProvider.Error.attributeCombinationNotSupported {
        // expected
    } catch {
        preconditionFailure("wrong error")
    }
}

func testModelProviderObjectLookup() {
    let categoryURL = roomPlanTemporaryModelURL()
    let attributeURL = roomPlanTemporaryModelURL()
    defer {
        try? FileManager.default.removeItem(at: categoryURL)
        try? FileManager.default.removeItem(at: attributeURL)
    }
    var provider = CapturedRoom.ModelProvider()
    try! provider.setModelFileURL(categoryURL, for: .chair)
    try! provider.setModelFileURL(attributeURL, for: [ChairType.stool])
    let attributed = CapturedRoom.Object(category: .chair, attributes: [ChairType.stool])
    let plain = CapturedRoom.Object(category: .chair)
    precondition(try! provider.modelFileURL(for: attributed) == attributeURL)
    precondition(try! provider.modelFileURL(for: plain) == categoryURL)
}

func testModelProviderModelFileURLs() {
    let urlA = roomPlanTemporaryModelURL()
    let urlB = roomPlanTemporaryModelURL()
    defer {
        try? FileManager.default.removeItem(at: urlA)
        try? FileManager.default.removeItem(at: urlB)
    }
    var provider = CapturedRoom.ModelProvider()
    try! provider.setModelFileURL(urlA, for: .sofa)
    try! provider.setModelFileURL(urlB, for: [StorageType.cabinet])
    let urls = provider.modelFileURLs.map(\.path)
    precondition(urls.contains(urlA.path))
    precondition(urls.contains(urlB.path))
}

func testModelProviderStaleFileThrows() {
    let url = roomPlanTemporaryModelURL()
    var provider = CapturedRoom.ModelProvider()
    try! provider.setModelFileURL(url, for: .bed)
    try! FileManager.default.removeItem(at: url)
    do {
        _ = try provider.modelFileURL(for: .bed)
        preconditionFailure("expected throw")
    } catch CapturedRoom.ModelProvider.Error.nonExistingFile(let missing) {
        precondition(missing.path == url.path)
    } catch {
        preconditionFailure("wrong error")
    }
}
