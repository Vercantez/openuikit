import Foundation
@_spi(OpenUIKitHost) import PhotosUI

func testPickerConfigurationInit() {
    let configuration = PHPickerConfiguration()
    precondition(configuration.selectionLimit == 1)
    precondition(configuration.filter == nil)
    precondition(configuration.selection == .default)
    precondition(configuration.mode == .default)
}

func testPickerConfigurationSelectionLimit() {
    var configuration = PHPickerConfiguration()
    precondition(configuration.selectionLimit == 1)
    configuration.selectionLimit = 4
    precondition(configuration.selectionLimit == 4)
    configuration.selectionLimit = 0
    precondition(configuration.selectionLimit == 0)
}

func testPickerConfigurationFilter() {
    var configuration = PHPickerConfiguration()
    precondition(configuration.filter == nil)
    configuration.filter = .images
    precondition(configuration.filter == .images)
    configuration.filter = .any(of: [.images, .videos])
    precondition(configuration.filter == PHPickerFilter.any(of: [.images, .videos]))
}

func testPickerConfigurationMode() {
    var configuration = PHPickerConfiguration()
    precondition(configuration.mode == .default)
    configuration.mode = .compact
    precondition(configuration.mode == .compact)
    configuration.mode = .default
    precondition(configuration.mode == .default)
}

func testPickerConfigurationPreferredAssetRepresentationMode() {
    var configuration = PHPickerConfiguration()
    precondition(configuration.preferredAssetRepresentationMode == .automatic)
    configuration.preferredAssetRepresentationMode = .current
    precondition(configuration.preferredAssetRepresentationMode == .current)
    configuration.preferredAssetRepresentationMode = .compatible
    precondition(configuration.preferredAssetRepresentationMode == .compatible)
}

func testPickerConfigurationSelection() {
    var configuration = PHPickerConfiguration()
    precondition(configuration.selection == .default)
    configuration.selection = .ordered
    precondition(configuration.selection == .ordered)
    configuration.selection = .continuous
    precondition(configuration.selection == .continuous)
    configuration.selection = .continuousAndOrdered
    precondition(configuration.selection == .continuousAndOrdered)
}

func testPickerConfigurationPreselectedAssetIdentifiers() {
    var configuration = PHPickerConfiguration()
    precondition(configuration.preselectedAssetIdentifiers.isEmpty)
    configuration.preselectedAssetIdentifiers = ["a", "b"]
    precondition(configuration.preselectedAssetIdentifiers == ["a", "b"])
}

func testPickerConfigurationDisabledCapabilities() {
    var configuration = PHPickerConfiguration()
    precondition(configuration.disabledCapabilities.isEmpty)
    configuration.disabledCapabilities = [.search, .stagingArea]
    precondition(configuration.disabledCapabilities.contains(.search))
    precondition(configuration.disabledCapabilities.contains(.stagingArea))
    precondition(!configuration.disabledCapabilities.contains(.selectionActions))
}

func testPickerConfigurationEdgesWithoutContentMargins() {
    var configuration = PHPickerConfiguration()
    precondition(configuration.edgesWithoutContentMargins.isEmpty)
    configuration.edgesWithoutContentMargins = .top
    precondition(configuration.edgesWithoutContentMargins.contains(.top))
    configuration.edgesWithoutContentMargins = .all
    precondition(configuration.edgesWithoutContentMargins == .all)
}

func testPickerConfigurationEqualityAndHash() {
    let first = PHPickerConfiguration()
    let again = PHPickerConfiguration()
    precondition(first == again)
    precondition(!(first != again))
    var hasher = Hasher()
    first.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(first.hashValue == again.hashValue)
    var mutated = first
    mutated.selectionLimit = 9
    precondition(mutated != first)
}

func testPickerConfigurationPhotoLibraryInit() {
    let configuration = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared)
    precondition(configuration.selectionLimit == 1)
    precondition(configuration.filter == nil)
    precondition(configuration.mode == .default)
    precondition(configuration.selection == .default)
}

func testPickerUpdateInit() {
    let update = PHPickerConfiguration.Update()
    precondition(update.selectionLimit == nil)
    precondition(update.edgesWithoutContentMargins == nil)
}

func testPickerUpdateSelectionLimit() {
    var update = PHPickerConfiguration.Update()
    update.selectionLimit = 8
    precondition(update.selectionLimit == 8)
    update.selectionLimit = 0
    precondition(update.selectionLimit == 0)
}

func testPickerUpdateEdgesWithoutContentMargins() {
    var update = PHPickerConfiguration.Update()
    update.edgesWithoutContentMargins = .leading
    precondition(update.edgesWithoutContentMargins == .leading)
    update.edgesWithoutContentMargins = .all
    precondition(update.edgesWithoutContentMargins == .all)
}

func testPickerUpdateEqualityAndHash() {
    var first = PHPickerConfiguration.Update()
    first.selectionLimit = 2
    var again = PHPickerConfiguration.Update()
    again.selectionLimit = 2
    precondition(first == again)
    precondition(!(first != again))
    var hasher = Hasher()
    first.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(first.hashValue == again.hashValue)
    again.edgesWithoutContentMargins = .top
    precondition(first != again)
}
