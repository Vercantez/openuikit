@_spi(OpenUIKitHost) import BackgroundAssets
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

func testManifestFromJSONObject() {
    let json = Data(
        """
        {
          "assetPacks": [
            {
              "id": "models",
              "downloadSize": 2048,
              "version": 7,
              "url": "https://cdn.example/models.zip"
            },
            {
              "identifier": "voices",
              "downloadSize": 16,
              "version": 1
            }
          ]
        }
        """.utf8
    )
    let manifest = try! AssetPackManifest(from: json, appGroupID: "group.manifest")
    precondition(manifest.assetPacks.count == 2)
    let ids = Set(manifest.assetPacks.map(\.id))
    precondition(ids == ["models", "voices"])
    precondition(manifest.description.contains("2"))
    let downloads = manifest.allDownloads(for: .update)
    precondition(downloads.count == 2)
    precondition(downloads.allSatisfy { $0 is BAURLDownload })
}

func testManifestFromArrayAndAliases() {
    let json = Data(
        """
        [
          {"assetPackID":"alias-pack","downloadSize":3,"version":2,"userInfo":"aGVsbG8="}
        ]
        """.utf8
    )
    let manifest = try! AssetPackManifest(from: json, appGroupID: "group.alias")
    precondition(manifest.assetPacks.count == 1)
    let pack = manifest.assetPacks.first!
    precondition(pack.id == "alias-pack")
    precondition(pack.userInfo == Data("hello".utf8) || pack.userInfo == Data(base64Encoded: "aGVsbG8="))
}

func testManifestContentsOfFile() {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("ba-manifest-\(UUID().uuidString).json")
    let json = Data("{\"assetPacks\":[{\"id\":\"disk\",\"downloadSize\":1,\"version\":1}]}".utf8)
    try! json.write(to: url)
    defer { try? FileManager.default.removeItem(at: url) }
    let manifest = try! AssetPackManifest(contentsOf: url, appGroupID: "group.disk")
    precondition(manifest.assetPacks.first?.id == "disk")
}

func testManifestEncodeAndConfiguration() {
    let configuration = AssetPackManifest.DecodingConfiguration(appGroupID: "group.cfg")
    precondition(configuration.appGroupID == "group.cfg")
    precondition(configuration.description.contains("group.cfg"))

    let json = Data("{\"assetPacks\":[{\"id\":\"enc\",\"downloadSize\":2,\"version\":9}]}".utf8)
    let manifest = try! JSONDecoder().decode(
        AssetPackManifest.self,
        from: json,
        configuration: configuration
    )
    let encoded = try! JSONEncoder().encode(manifest)
    let object = try! JSONSerialization.jsonObject(with: encoded) as! [String: Any]
    let packs = object["assetPacks"] as! [[String: Any]]
    precondition(packs.contains { $0["id"] as? String == "enc" })
}

func testManifestMissingFile() {
    let missing = URL(fileURLWithPath: "/tmp/ba-manifest-does-not-exist-\(UUID().uuidString).json")
    do {
        _ = try AssetPackManifest(contentsOf: missing, appGroupID: "group.missing")
        preconditionFailure("missing file must throw")
    } catch {
        _ = error
    }
}
