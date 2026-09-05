import Foundation
@_spi(OpenUIKitHost) import PhotosUI

private final class HostPickerDelegate: PHPickerViewControllerDelegate, @unchecked Sendable {
    private(set) var last: [PHPickerResult] = []
    private(set) var onMain = false

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        _ = picker
        last = results
        onMain = Thread.isMainThread
    }
}

private func libraryFixture() -> [PHPickerHostAsset] {
    [
        PHPickerHostAsset(
            identifier: "jpeg-1",
            mediaKind: .image,
            typeIdentifier: UTType.jpeg.identifier,
            payload: Data("jpeg-bytes".utf8),
            playbackStyle: .image
        ),
        PHPickerHostAsset(
            identifier: "shot-1",
            mediaKind: .image,
            typeIdentifier: UTType.jpeg.identifier,
            payload: Data("shot-bytes".utf8),
            isScreenshot: true
        ),
        PHPickerHostAsset(
            identifier: "movie-1",
            mediaKind: .video,
            typeIdentifier: UTType.movie.identifier,
            payload: Data("movie-bytes".utf8),
            playbackStyle: .video
        ),
        PHPickerHostAsset(
            identifier: "live-1",
            mediaKind: .image,
            typeIdentifier: UTType.livePhoto.identifier,
            payload: Data("live-bytes".utf8),
            playbackStyle: .livePhoto,
            isLivePhoto: true
        ),
    ]
}

func testPickerHostLibraryFilterAndLimit() {
    var configuration = PHPickerConfiguration()
    configuration.filter = .images
    configuration.selectionLimit = 2
    configuration.selection = .ordered
    configuration.preselectedAssetIdentifiers = ["shot-1", "missing", "movie-1"]
    let picker = PHPickerViewController(configuration: configuration)
    picker._installLibrary(libraryFixture())
    // movie-1 is filtered out; missing is unknown; shot-1 remains.
    precondition(picker._selectedIdentifiers == ["shot-1"])

    picker._hostSelect(["jpeg-1", "live-1", "movie-1"])
    // Limit 2 keeps the preselected screenshot plus the first matching add.
    precondition(picker._selectedIdentifiers == ["shot-1", "jpeg-1"])
    precondition(picker._effectiveSelectionLimit == 2)

    let probe = HostPickerDelegate()
    picker.delegate = probe
    picker._present()
    precondition(probe.onMain)
    precondition(probe.last.map(\.assetIdentifier) == ["shot-1", "jpeg-1"])
    precondition(probe.last[0].itemProvider.hasItemConformingToTypeIdentifier(UTType.jpeg.identifier))
    precondition(probe.last[1].itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier))
}

func testPickerDeselectAndMoveAsset() {
    var configuration = PHPickerConfiguration()
    configuration.selectionLimit = 0
    configuration.selection = .ordered
    configuration.preselectedAssetIdentifiers = ["jpeg-1", "shot-1", "live-1"]
    let picker = PHPickerViewController(configuration: configuration)
    picker._installLibrary(libraryFixture())
    precondition(picker._selectedIdentifiers == ["jpeg-1", "shot-1", "live-1"])

    picker.deselectAssets(withIdentifiers: ["shot-1", "absent"])
    precondition(picker._selectedIdentifiers == ["jpeg-1", "live-1"])

    picker.moveAsset(withIdentifier: "live-1", afterAssetWithIdentifier: nil)
    precondition(picker._selectedIdentifiers == ["live-1", "jpeg-1"])

    picker.moveAsset(withIdentifier: "jpeg-1", afterAssetWithIdentifier: "live-1")
    precondition(picker._selectedIdentifiers == ["live-1", "jpeg-1"])

    picker.moveAsset(withIdentifier: "live-1", afterAssetWithIdentifier: "jpeg-1")
    precondition(picker._selectedIdentifiers == ["jpeg-1", "live-1"])

    picker.moveAsset(withIdentifier: "missing", afterAssetWithIdentifier: nil)
    precondition(picker._selectedIdentifiers == ["jpeg-1", "live-1"])
}

func testPickerUpdateConfigurationAppliesLimitAndEdges() {
    var configuration = PHPickerConfiguration()
    configuration.selectionLimit = 3
    configuration.edgesWithoutContentMargins = .top
    configuration.preselectedAssetIdentifiers = ["jpeg-1", "shot-1", "live-1"]
    let picker = PHPickerViewController(configuration: configuration)
    picker._installLibrary(libraryFixture())
    precondition(picker._selectedIdentifiers.count == 3)
    precondition(picker._effectiveEdgesWithoutContentMargins.contains(.top))

    var update = PHPickerConfiguration.Update()
    update.selectionLimit = 1
    update.edgesWithoutContentMargins = .all
    picker.updatePicker(using: update)
    precondition(picker._appliedUpdate?.selectionLimit == 1)
    precondition(picker._effectiveSelectionLimit == 1)
    precondition(picker._selectedIdentifiers == ["jpeg-1"])
    precondition(picker._effectiveEdgesWithoutContentMargins == .all)

    picker._hostSelect(["shot-1"])
    precondition(picker._selectedIdentifiers == ["jpeg-1"])
}

func testPickerScrollAndZoomHostObservation() {
    let picker = PHPickerViewController(configuration: PHPickerConfiguration())
    precondition(!picker._didScrollToInitialPosition)
    precondition(picker._zoomSteps == 0)
    picker.scrollToInitialPosition()
    picker.zoomIn()
    picker.zoomIn()
    picker.zoomOut()
    precondition(picker._didScrollToInitialPosition)
    precondition(picker._zoomSteps == 1)
}

func testPickerHostLibraryDelegateTypeIdentifiers() {
    var configuration = PHPickerConfiguration()
    configuration.filter = .videos
    configuration.selectionLimit = 1
    let picker = PHPickerViewController(configuration: configuration)
    picker._installLibrary(libraryFixture())
    picker._hostSelect(["movie-1", "jpeg-1"])
    precondition(picker._selectedIdentifiers == ["movie-1"])

    let probe = HostPickerDelegate()
    picker.delegate = probe
    picker._present()
    precondition(probe.last.count == 1)
    let provider = probe.last[0].itemProvider
    precondition(probe.last[0].assetIdentifier == "movie-1")
    precondition(provider.registeredTypeIdentifiers.contains(UTType.movie.identifier))
    precondition(provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier))
    precondition(provider.hasItemConformingToTypeIdentifier(UTType.video.identifier))
}

func testPickerContinuousSelectionDoesNotReorderOnSelect() {
    var configuration = PHPickerConfiguration()
    configuration.selection = .continuous
    configuration.selectionLimit = 0
    configuration.preselectedAssetIdentifiers = ["jpeg-1"]
    let picker = PHPickerViewController(configuration: configuration)
    picker._installLibrary(libraryFixture())
    picker._hostSelect(["live-1", "shot-1"])
    precondition(picker._selectedIdentifiers == ["jpeg-1", "live-1", "shot-1"])
    picker._hostSelect(["jpeg-1"])
    precondition(picker._selectedIdentifiers == ["jpeg-1", "live-1", "shot-1"])
}
