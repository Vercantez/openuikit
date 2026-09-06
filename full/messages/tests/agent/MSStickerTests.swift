import Foundation
import Messages

let messagesMinimalPNG: Data = Data([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
    0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, 0x54,
    0x08, 0xD7, 0x63, 0xF8, 0x0F, 0x00, 0x00, 0x01,
    0x01, 0x01, 0x00, 0x1B, 0xB6, 0xEE, 0x56,
    0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44,
    0xAE, 0x42, 0x60, 0x82,
])

func messagesWriteTempPNG() -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("messages-\(UUID().uuidString).png")
    try! messagesMinimalPNG.write(to: url)
    return url
}

func messagesMakePNGSticker() -> MSSticker {
    try! MSSticker(
        contentsOfFileURL: messagesWriteTempPNG(),
        localizedDescription: "test sticker"
    )
}

func testStickerRejectsNonFileURL() {
    do {
        _ = try MSSticker(
            contentsOfFileURL: URL(string: "https://example.com/a.png")!,
            localizedDescription: "remote"
        )
        preconditionFailure("expected improperFileURL")
    } catch let error as NSError {
        precondition(error.domain == MSMessagesErrorDomain)
        precondition(error.code == MSMessageErrorCode.improperFileURL.rawValue)
    } catch {
        preconditionFailure("expected NSError")
    }
}

func testStickerFileNotFound() {
    let missing = URL(fileURLWithPath: "/tmp/messages-absent-\(UUID().uuidString).png")
    do {
        _ = try MSSticker(contentsOfFileURL: missing, localizedDescription: "missing")
        preconditionFailure("expected fileNotFound")
    } catch let error as NSError {
        precondition(error.code == MSMessageErrorCode.fileNotFound.rawValue)
    } catch {
        preconditionFailure("expected NSError")
    }
}

func testStickerRejectsDirectory() {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("messages-dir-\(UUID().uuidString)", isDirectory: true)
    try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    do {
        _ = try MSSticker(contentsOfFileURL: dir, localizedDescription: "dir")
        preconditionFailure("expected improperFileType")
    } catch let error as NSError {
        precondition(error.code == MSMessageErrorCode.improperFileType.rawValue)
    } catch {
        preconditionFailure("expected NSError")
    }
}

func testStickerRejectsBadFormat() {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("messages-\(UUID().uuidString).png")
    try! Data("not an image".utf8).write(to: url)
    do {
        _ = try MSSticker(contentsOfFileURL: url, localizedDescription: "bad")
        preconditionFailure("expected improperFileFormat")
    } catch let error as NSError {
        precondition(error.code == MSMessageErrorCode.stickerFileImproperFileFormat.rawValue)
    } catch {
        preconditionFailure("expected NSError")
    }
}

func testStickerRejectsEmptyDescription() {
    let url = messagesWriteTempPNG()
    do {
        _ = try MSSticker(contentsOfFileURL: url, localizedDescription: "   ")
        preconditionFailure("expected improperFileAttributes")
    } catch let error as NSError {
        precondition(error.code == MSMessageErrorCode.stickerFileImproperFileAttributes.rawValue)
    } catch {
        preconditionFailure("expected NSError")
    }
}

func testStickerLoadsPNG() {
    let url = messagesWriteTempPNG()
    let sticker = try! MSSticker(
        contentsOfFileURL: url,
        localizedDescription: "png sticker"
    )
    precondition(sticker.imageFileURL == url)
    precondition(sticker.localizedDescription == "png sticker")
}

func testStickerLoadsGIFMagic() {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("messages-\(UUID().uuidString).gif")
    var gif = Data("GIF89a".utf8)
    gif.append(contentsOf: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
    try! gif.write(to: url)
    let sticker = try! MSSticker(
        contentsOfFileURL: url,
        localizedDescription: "gif"
    )
    precondition(sticker.localizedDescription == "gif")
}
