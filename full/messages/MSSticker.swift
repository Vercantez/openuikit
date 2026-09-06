import Foundation

/// A sticker backed by a local image file.
///
/// Linux validates the file URL, existence, regular-file type, a
/// non-empty accessibility string, and PNG / GIF / JPEG magic bytes. It
/// does not decode pixels or enforce Darwin's unobserved byte-size cap.
open class MSSticker: NSObject {
    public let imageFileURL: URL
    public let localizedDescription: String

    public init(contentsOfFileURL fileURL: URL, localizedDescription: String) throws {
        guard fileURL.isFileURL else {
            throw MessagesLinuxSupport.messageError(
                .improperFileURL,
                userInfo: [NSLocalizedDescriptionKey: "MSSticker requires a file URL."]
            )
        }
        let trimmed = localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw MessagesLinuxSupport.messageError(
                .stickerFileImproperFileAttributes,
                userInfo: [NSLocalizedDescriptionKey: "MSSticker requires a localized description."]
            )
        }

        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(
            atPath: fileURL.path,
            isDirectory: &isDirectory
        )
        guard exists else {
            throw MessagesLinuxSupport.messageError(.fileNotFound)
        }
        guard !isDirectory.boolValue else {
            throw MessagesLinuxSupport.messageError(.improperFileType)
        }
        guard FileManager.default.isReadableFile(atPath: fileURL.path) else {
            throw MessagesLinuxSupport.messageError(.fileUnreadable)
        }

        let handle = try FileHandle(forReadingFrom: fileURL)
        let prefix = handle.readData(ofLength: 16)
        try handle.close()
        guard Self.recognizedImageMagic(prefix) else {
            throw MessagesLinuxSupport.messageError(.stickerFileImproperFileFormat)
        }

        self.imageFileURL = fileURL
        self.localizedDescription = localizedDescription
        super.init()
    }

    private static func recognizedImageMagic(_ data: Data) -> Bool {
        let bytes = [UInt8](data)
        if bytes.count >= 8
            && bytes[0] == 0x89
            && bytes[1] == 0x50
            && bytes[2] == 0x4E
            && bytes[3] == 0x47
        {
            return true
        }
        if bytes.count >= 6 {
            let gif87 = Array("GIF87a".utf8)
            let gif89 = Array("GIF89a".utf8)
            if Array(bytes.prefix(6)) == gif87 || Array(bytes.prefix(6)) == gif89 {
                return true
            }
        }
        if bytes.count >= 3
            && bytes[0] == 0xFF
            && bytes[1] == 0xD8
            && bytes[2] == 0xFF
        {
            return true
        }
        return false
    }
}
