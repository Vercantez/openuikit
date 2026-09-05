@_spi(OpenUIKitHost) import BackgroundAssets
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

func testAssetPackStatusMembers() {
    precondition(AssetPack.Status.downloadAvailable.rawValue == 1 << 0)
    precondition(AssetPack.Status.updateAvailable.rawValue == 1 << 1)
    precondition(AssetPack.Status.upToDate.rawValue == 1 << 2)
    precondition(AssetPack.Status.outOfDate.rawValue == 1 << 3)
    precondition(AssetPack.Status.obsolete.rawValue == 1 << 4)
    precondition(AssetPack.Status.downloading.rawValue == 1 << 5)
    precondition(AssetPack.Status.downloaded.rawValue == 1 << 6)
    let constructed = AssetPack.Status(rawValue: 1 << 0 | 1 << 6)
    precondition(constructed.contains(.downloadAvailable))
    precondition(constructed.contains(.downloaded))
    precondition(AssetPack.Status.downloadAvailable != .obsolete)
}

func testAssetPackStatusSetAlgebra() {
    let status = AssetPack.Status()
    precondition(status.isEmpty)
    precondition(status.rawValue == 0)

    let fromLiteral: AssetPack.Status = [.downloadAvailable, .downloading]
    precondition(fromLiteral.contains(.downloadAvailable))
    precondition(fromLiteral.contains(.downloading))

    let fromSequence = AssetPack.Status([.upToDate, .downloaded])
    precondition(fromSequence.contains(.upToDate))
    precondition(fromSequence.contains(.downloaded))

    let union = AssetPack.Status.downloadAvailable.union(.updateAvailable)
    precondition(union.contains(.downloadAvailable))
    precondition(union.contains(.updateAvailable))

    var formUnion = AssetPack.Status.downloadAvailable
    formUnion.formUnion(.obsolete)
    precondition(formUnion.contains(.obsolete))

    let intersection = fromLiteral.intersection(.downloading)
    precondition(intersection == .downloading)

    var formIntersection = fromLiteral
    formIntersection.formIntersection(.downloading)
    precondition(formIntersection == .downloading)

    let symmetric = AssetPack.Status.downloadAvailable.symmetricDifference(.updateAvailable)
    precondition(symmetric.contains(.downloadAvailable))
    precondition(symmetric.contains(.updateAvailable))

    var formSymmetric = AssetPack.Status.downloadAvailable
    formSymmetric.formSymmetricDifference(.downloadAvailable)
    precondition(formSymmetric.isEmpty)

    let subtracted = fromLiteral.subtracting(.downloading)
    precondition(subtracted == .downloadAvailable)
    var subtract = fromLiteral
    subtract.subtract(.downloading)
    precondition(subtract == .downloadAvailable)

    precondition(fromLiteral.isSuperset(of: .downloading))
    precondition(fromLiteral.isSubset(of: [.downloadAvailable, .downloading, .downloaded]))
    precondition(fromLiteral.isStrictSubset(of: [.downloadAvailable, .downloading, .downloaded]))
    precondition(AssetPack.Status.downloadAvailable.isStrictSuperset(of: []))
    precondition(AssetPack.Status.downloadAvailable.isDisjoint(with: .obsolete))

    var insertable = AssetPack.Status.downloadAvailable
    let inserted = insertable.insert(.downloaded)
    precondition(inserted.inserted)
    precondition(insertable.contains(.downloaded))
    let removed = insertable.remove(.downloaded)
    precondition(removed == .downloaded)
    let updated = insertable.update(with: .upToDate)
    precondition(updated == nil || updated == .upToDate)

    let _: AssetPack.Status.ArrayLiteralElement = .obsolete
    let _: AssetPack.Status.Element = .downloaded
    let _: AssetPack.Status.RawValue = AssetPack.Status.upToDate.rawValue
}

func testAssetPackValueAndHashable() {
    let info = Data("{\"k\":1}".utf8)
    let pack = AssetPack(
        id: "tutorial",
        downloadSize: 100,
        version: 2,
        userInfo: info,
        downloadURL: URL(string: "https://cdn.example/tutorial.zip"),
        appGroupID: "group.packs"
    )
    precondition(pack.id == "tutorial")
    precondition(pack.downloadSize == 100)
    precondition(pack.version == 2)
    precondition(pack.userInfo == info)
    precondition(pack.description.contains("tutorial"))
    let id: AssetPack.ID = pack.id
    precondition(id == "tutorial")

    let same = AssetPack(id: "tutorial", downloadSize: 100, version: 2, userInfo: info)
    let other = AssetPack(id: "other", downloadSize: 100, version: 2, userInfo: info)
    precondition(pack == same)
    precondition(pack != other)
    precondition(pack.hashValue == same.hashValue)
    var hasher = Hasher()
    pack.hash(into: &hasher)
    _ = hasher.finalize()
}

func testAssetPackDownloadForRequest() {
    let pack = AssetPack(
        id: "voice",
        downloadSize: 50,
        version: 1,
        downloadURL: URL(string: "https://cdn.example/voice.zip"),
        appGroupID: "group.voice"
    )
    let download = pack.download(for: .install)
    precondition(download.identifier == "voice")
    precondition(download.fileSize == 50)
    precondition((download as? BAURLDownload)?.request?.url?.absoluteString == "https://cdn.example/voice.zip")
    let nilRequest = pack.download(for: nil)
    precondition(nilRequest.identifier == "voice")
}

func testAssetPackCodableRoundTrip() {
    let configuration = AssetPackManifest.DecodingConfiguration(appGroupID: "group.rt")
    let json = Data(
        """
        {"id":"p1","downloadSize":9,"version":4,"url":"https://cdn.example/p1.zip"}
        """.utf8
    )
    let pack = try! JSONDecoder().decode(AssetPack.self, from: json, configuration: configuration)
    precondition(pack.id == "p1")
    precondition(pack.downloadSize == 9)
    precondition(pack.version == 4)
    let encoded = try! JSONEncoder().encode(pack)
    let object = try! JSONSerialization.jsonObject(with: encoded) as! [String: Any]
    precondition(object["id"] as? String == "p1")
    precondition(object["downloadSize"] as? Int == 9)
}
