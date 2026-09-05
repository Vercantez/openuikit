import Foundation
@_spi(OpenUIKitHost) import PhotosUI

private final class DataBox: @unchecked Sendable {
    var bytes: Data?
}

func testPickerResultRegistersConcreteAndConformingTypes() {
    let jpeg = Data("host-jpeg".utf8)
    let result = PHPickerResult._hostResult(
        assetIdentifier: "asset-jpeg",
        typeIdentifier: UTType.jpeg.identifier,
        payload: jpeg
    )
    precondition(result.assetIdentifier == "asset-jpeg")
    let provider = result.itemProvider
    precondition(provider.registeredTypeIdentifiers == [UTType.jpeg.identifier])
    precondition(provider.hasItemConformingToTypeIdentifier(UTType.jpeg.identifier))
    precondition(provider.hasItemConformingToTypeIdentifier(UTType.image.identifier))
    precondition(!provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier))

    let box = DataBox()
    let progress = provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
        precondition(error == nil)
        box.bytes = data
    }
    precondition(progress.isFinished)
    precondition(box.bytes == jpeg)
}

func testPickerResultMovieTypeIdentifier() {
    let movie = Data("host-movie".utf8)
    let result = PHPickerResult._hostResult(
        assetIdentifier: "asset-movie",
        typeIdentifier: UTType.movie.identifier,
        payload: movie
    )
    let provider = result.itemProvider
    precondition(provider.registeredTypeIdentifiers == [UTType.movie.identifier])
    precondition(provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier))
    precondition(provider.hasItemConformingToTypeIdentifier(UTType.video.identifier))
    precondition(!provider.hasItemConformingToTypeIdentifier(UTType.jpeg.identifier))
    precondition(result.assetIdentifier == "asset-movie")
}

func testPickerResultLivePhotoTypeIdentifier() {
    let payload = Data("host-live".utf8)
    let result = PHPickerResult._hostResult(
        assetIdentifier: "asset-live",
        typeIdentifier: UTType.livePhoto.identifier,
        payload: payload
    )
    let provider = result.itemProvider
    precondition(provider.registeredTypeIdentifiers == [UTType.livePhoto.identifier])
    precondition(provider.hasItemConformingToTypeIdentifier(UTType.livePhoto.identifier))
    precondition(provider.hasItemConformingToTypeIdentifier(UTType.image.identifier))
}
