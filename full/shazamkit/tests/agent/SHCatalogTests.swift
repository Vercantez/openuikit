import Foundation
import ShazamKit

func testSHCatalogType() {
    let catalog = SHSession().catalog
    precondition(type(of: catalog) == SHCatalog.self)
}

func testSHCatalogMinimumQuerySignatureDuration() {
    precondition(SHSession().catalog.minimumQuerySignatureDuration == 0)
}

func testSHCatalogMaximumQuerySignatureDuration() {
    precondition(SHSession().catalog.maximumQuerySignatureDuration == 0)
}

func testSHCustomCatalogType() {
    precondition(type(of: SHCustomCatalog()) == SHCustomCatalog.self)
}

func testSHCustomCatalogInit() {
    let catalog = SHCustomCatalog()
    precondition(catalog.minimumQuerySignatureDuration == 0)
    precondition(catalog.maximumQuerySignatureDuration == TimeInterval.greatestFiniteMagnitude)
}

func testSHCustomCatalogAddReferenceSignature() {
    let catalog = SHCustomCatalog()
    try! catalog.addReferenceSignature(
        shazamKitSignature([0x70]),
        representing: [SHMediaItem(properties: [.title: "Ref"])]
    )
    let session = SHSession(catalog: catalog)
    let delegate = ShazamKitRecordingDelegate()
    session.delegate = delegate
    session.match(shazamKitSignature([0x70]))
    precondition(delegate.match?.mediaItems.first?.title == "Ref")
}

func testSHCustomCatalogDataRepresentation() {
    let catalog = SHCustomCatalog()
    try! catalog.addReferenceSignature(
        shazamKitSignature([0x71]),
        representing: [SHMediaItem(properties: [.title: "Blob"])]
    )
    let data = catalog.dataRepresentation
    precondition(!data.isEmpty)
}

func testSHCustomCatalogInitDataRepresentation() {
    let original = SHCustomCatalog()
    try! original.addReferenceSignature(
        shazamKitSignature([0x72]),
        representing: [SHMediaItem(properties: [.artist: "RoundTrip"])]
    )
    let restored = try! SHCustomCatalog(dataRepresentation: original.dataRepresentation)
    let session = SHSession(catalog: restored)
    let delegate = ShazamKitRecordingDelegate()
    session.delegate = delegate
    session.match(shazamKitSignature([0x72]))
    precondition(delegate.match?.mediaItems.first?.artist == "RoundTrip")
}

func testSHCustomCatalogInitInvalidData() {
    do {
        _ = try SHCustomCatalog(dataRepresentation: Data([0x00, 0x01]))
        preconditionFailure("invalid catalog bytes must fail closed")
    } catch {
        precondition(SHError.Code.customCatalogInvalid ~= error, "expected customCatalogInvalid, got \(error)")
        return
    }
}

func testSHCustomCatalogWriteToURL() {
    let catalog = SHCustomCatalog()
    try! catalog.addReferenceSignature(
        shazamKitSignature([0x73]),
        representing: [SHMediaItem(properties: [.title: "Disk"])]
    )
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("shazamkit-catalog-\(UUID().uuidString).plist")
    try! catalog.write(to: url)
    precondition(FileManager.default.fileExists(atPath: url.path))
    try? FileManager.default.removeItem(at: url)
}

func testSHCustomCatalogAddFromURL() {
    let original = SHCustomCatalog()
    try! original.addReferenceSignature(
        shazamKitSignature([0x74]),
        representing: [SHMediaItem(properties: [.title: "Loaded"])]
    )
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("shazamkit-add-\(UUID().uuidString).plist")
    try! original.write(to: url)
    let loaded = SHCustomCatalog()
    try! loaded.add(from: url)
    let session = SHSession(catalog: loaded)
    let delegate = ShazamKitRecordingDelegate()
    session.delegate = delegate
    session.match(shazamKitSignature([0x74]))
    precondition(delegate.match?.mediaItems.first?.title == "Loaded")
    try? FileManager.default.removeItem(at: url)
}

func testSHCustomCatalogAddFromInvalidURL() {
    let catalog = SHCustomCatalog()
    let missing = URL(fileURLWithPath: "/tmp/shazamkit-missing-\(UUID().uuidString).catalog")
    do {
        try catalog.add(from: missing)
        preconditionFailure("missing catalog URL must fail closed")
    } catch {
        precondition(SHError.Code.customCatalogInvalidURL ~= error, "expected customCatalogInvalidURL, got \(error)")
        return
    }
}
