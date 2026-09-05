@_spi(OpenUIKitHost) import BackgroundAssets
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

func testURLDownloadDesignatedInit() {
    let request = URLRequest(url: URL(string: "https://cdn.example/pack.bin")!)
    let download = BAURLDownload(
        identifier: "level-1",
        request: request,
        essential: true,
        fileSize: 4096,
        applicationGroupIdentifier: "group.example.assets",
        priority: .max
    )
    precondition(download.identifier == "level-1")
    precondition(download.isEssential)
    precondition(download.fileSize == 4096)
    precondition(download.priority == .max)
    precondition(download.state == .created)
    precondition(!download.uniqueIdentifier.isEmpty)
    precondition(download.request?.url?.absoluteString == "https://cdn.example/pack.bin")
    precondition(download.applicationGroupIdentifier == "group.example.assets")
}

func testURLDownloadConvenienceInits() {
    let request = URLRequest(url: URL(string: "https://cdn.example/b.bin")!)
    let basic = BAURLDownload(
        identifier: "b",
        request: request,
        applicationGroupIdentifier: "group.b"
    )
    precondition(basic.identifier == "b")
    precondition(!basic.isEssential)
    precondition(basic.priority == .default)
    precondition(basic.fileSize == 0)

    let withPriority = BAURLDownload(
        identifier: "c",
        request: request,
        applicationGroupIdentifier: "group.b",
        priority: .min
    )
    precondition(withPriority.priority == .min)
    precondition(!withPriority.isEssential)

    let withSize = BAURLDownload(
        identifier: "d",
        request: request,
        fileSize: 77,
        applicationGroupIdentifier: "group.b"
    )
    precondition(withSize.fileSize == 77)
    precondition(withSize.priority == .default)
}

func testRemovingEssential() {
    let request = URLRequest(url: URL(string: "https://cdn.example/e.bin")!)
    let essential = BAURLDownload(
        identifier: "e",
        request: request,
        essential: true,
        fileSize: 10,
        applicationGroupIdentifier: "group.e",
        priority: .default
    )
    let copy = essential.removingEssential()
    precondition(copy.identifier == "e")
    precondition(!copy.isEssential)
    precondition(essential.isEssential)
    precondition(copy.uniqueIdentifier != essential.uniqueIdentifier)
    precondition(type(of: copy) == BAURLDownload.self)
}

func testDownloadCopying() {
    let request = URLRequest(url: URL(string: "https://cdn.example/f.bin")!)
    let original = BAURLDownload(
        identifier: "f",
        request: request,
        essential: true,
        fileSize: 8,
        applicationGroupIdentifier: "group.f",
        priority: .min
    )
    let copied = original.copy() as! BAURLDownload
    precondition(copied.identifier == original.identifier)
    precondition(copied.uniqueIdentifier == original.uniqueIdentifier)
    precondition(copied.isEssential)
    precondition(copied.fileSize == 8)
    precondition(copied.priority == .min)
    precondition(copied !== original)
}

func testDownloadSecureCoding() {
    let request = URLRequest(url: URL(string: "https://cdn.example/g.bin")!)
    let original = BAURLDownload(
        identifier: "g",
        request: request,
        essential: true,
        fileSize: 12,
        applicationGroupIdentifier: "group.g",
        priority: .max
    )
    let data = try! NSKeyedArchiver.archivedData(withRootObject: original, requiringSecureCoding: true)
    let decoded = try! NSKeyedUnarchiver.unarchivedObject(ofClass: BAURLDownload.self, from: data)
    precondition(decoded?.identifier == "g")
    precondition(decoded?.isEssential == true)
    precondition(decoded?.fileSize == 12)
    precondition(decoded?.priority == .max)
    precondition(decoded?.state == .created)
    precondition(decoded?.applicationGroupIdentifier == "group.g")
    precondition(decoded?.request?.url?.absoluteString == "https://cdn.example/g.bin")
}

func testAppExtensionInfoCoderAndSPI() {
    let info = BAAppExtensionInfo(
        restrictedDownloadSizeRemaining: 2048,
        restrictedEssentialDownloadSizeRemaining: 512
    )
    precondition(info.restrictedDownloadSizeRemaining == 2048)
    precondition(info.restrictedEssentialDownloadSizeRemaining == 512)
    let data = try! NSKeyedArchiver.archivedData(withRootObject: info, requiringSecureCoding: true)
    let decoded = try! NSKeyedUnarchiver.unarchivedObject(ofClass: BAAppExtensionInfo.self, from: data)
    precondition(decoded?.restrictedDownloadSizeRemaining == 2048)
    precondition(decoded?.restrictedEssentialDownloadSizeRemaining == 512)

    let empty = BAAppExtensionInfo()
    precondition(empty.restrictedDownloadSizeRemaining == nil)
    precondition(empty.restrictedEssentialDownloadSizeRemaining == nil)
}
