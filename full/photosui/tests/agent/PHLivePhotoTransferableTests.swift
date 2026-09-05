import Foundation
@_spi(OpenUIKitHost) import PhotosUI

func testLivePhotoSuggestedFilename() {
    precondition(PHLivePhoto().suggestedFilename == nil)
}

func testLivePhotoExportedContentTypesStatic() {
    precondition(PHLivePhoto.exportedContentTypes(visibility: .all).isEmpty)
}

func testLivePhotoExportedContentTypesInstance() {
    precondition(PHLivePhoto().exportedContentTypes(.all).isEmpty)
}

func testLivePhotoImportedContentTypes() {
    precondition(PHLivePhoto().importedContentTypes().isEmpty)
}

func testLivePhotoTransferRepresentation() {
    _ = PHLivePhoto.transferRepresentation
    typealias Representation = PHLivePhoto.Representation
    _ = Representation.self
}

func testLivePhotoExportedThrows() {
    do {
        _ = try PHLivePhoto().exported(as: .jpeg)
        preconditionFailure("exported must fail closed")
    } catch let error as PhotosUIUnavailable {
        precondition(error == .linuxHost(operation: "PHLivePhoto.exported"))
    } catch {
        preconditionFailure("unexpected error")
    }
}

func testLivePhotoExportThrows() {
    do {
        _ = try PHLivePhoto().export(to: URL(fileURLWithPath: "/tmp"), contentType: .jpeg)
        preconditionFailure("export must fail closed")
    } catch let error as PhotosUIUnavailable {
        precondition(error == .linuxHost(operation: "PHLivePhoto.export"))
    } catch {
        preconditionFailure("unexpected error")
    }
}

func testLivePhotoWithExportedFileThrows() {
    do {
        _ = try PHLivePhoto().withExportedFile(contentType: .jpeg) { _ in 0 }
        preconditionFailure("withExportedFile must fail closed")
    } catch let error as PhotosUIUnavailable {
        precondition(error == .linuxHost(operation: "PHLivePhoto.withExportedFile"))
    } catch {
        preconditionFailure("unexpected error")
    }
}

func testLivePhotoImportFileThrows() {
    do {
        _ = try PHLivePhoto(importing: URL(fileURLWithPath: "/tmp/missing"), contentType: .jpeg)
        preconditionFailure("import file must fail closed")
    } catch let error as PhotosUIUnavailable {
        precondition(error == .linuxHost(operation: "PHLivePhoto.init(importing:file)"))
    } catch {
        preconditionFailure("unexpected error")
    }
}

func testLivePhotoImportDataThrows() {
    do {
        _ = try PHLivePhoto(importing: Data(), contentType: .jpeg)
        preconditionFailure("import data must fail closed")
    } catch let error as PhotosUIUnavailable {
        precondition(error == .linuxHost(operation: "PHLivePhoto.init(importing:data)"))
    } catch {
        preconditionFailure("unexpected error")
    }
}
