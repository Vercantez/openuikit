import Foundation
@_spi(OpenUIKitHost) import PhotosUI

func testPhotosPickerMultiLibraryInit() {
    var items: [PhotosPickerItem] = []
    let picker = PhotosPicker(
        selection: Binding(get: { items }, set: { items = $0 }),
        maxSelectionCount: 4,
        selectionBehavior: .ordered,
        matching: .images,
        preferredItemEncoding: .current,
        photoLibrary: PHPhotoLibrary.shared,
        label: { Text("Pick") }
    )
    precondition(picker._maxSelectionCount == 4)
    precondition(picker._selectionBehavior == .ordered)
    precondition(picker._filter == .images)
    precondition(picker._preferredItemEncoding == .current)
    precondition(picker._usesPhotoLibrary)
    precondition(picker._allowsMultipleSelection)
    _ = picker.body
}

func testPhotosPickerMultiInit() {
    var items: [PhotosPickerItem] = []
    let picker = PhotosPicker(
        selection: Binding(get: { items }, set: { items = $0 }),
        maxSelectionCount: 2,
        selectionBehavior: .continuous,
        matching: .videos,
        preferredItemEncoding: .compatible,
        label: { Text("Pick") }
    )
    precondition(picker._maxSelectionCount == 2)
    precondition(picker._selectionBehavior == .continuous)
    precondition(picker._filter == .videos)
    precondition(picker._preferredItemEncoding == .compatible)
    precondition(!picker._usesPhotoLibrary)
}

func testPhotosPickerSingleLibraryInit() {
    var single: PhotosPickerItem?
    let picker = PhotosPicker(
        selection: Binding(get: { single }, set: { single = $0 }),
        matching: .livePhotos,
        preferredItemEncoding: .automatic,
        photoLibrary: PHPhotoLibrary.shared,
        label: { Text("One") }
    )
    precondition(picker._maxSelectionCount == 1)
    precondition(!picker._allowsMultipleSelection)
    precondition(picker._usesPhotoLibrary)
    precondition(picker._filter == .livePhotos)
}

func testPhotosPickerSingleInit() {
    var single: PhotosPickerItem?
    let picker = PhotosPicker(
        selection: Binding(get: { single }, set: { single = $0 }),
        matching: .screenshots,
        preferredItemEncoding: .current,
        label: { Text("One") }
    )
    precondition(picker._maxSelectionCount == 1)
    precondition(!picker._allowsMultipleSelection)
    precondition(!picker._usesPhotoLibrary)
    precondition(picker._filter == .screenshots)
    precondition(picker._preferredItemEncoding == .current)
}

func testPhotosPickerTitleMultiLibraryInit() {
    var items: [PhotosPickerItem] = []
    let keyed = PhotosPicker(
        LocalizedStringKey("Photos"),
        selection: Binding(get: { items }, set: { items = $0 }),
        maxSelectionCount: 3,
        selectionBehavior: .continuousAndOrdered,
        matching: .any(of: [.images, .videos]),
        preferredItemEncoding: .automatic,
        photoLibrary: PHPhotoLibrary.shared
    )
    precondition(keyed._maxSelectionCount == 3)
    precondition(keyed._selectionBehavior == .continuousAndOrdered)
    precondition(keyed._usesPhotoLibrary)
    let titled = PhotosPicker(
        "Choose",
        selection: Binding(get: { items }, set: { items = $0 }),
        maxSelectionCount: 5,
        selectionBehavior: .default,
        matching: .images,
        preferredItemEncoding: .compatible,
        photoLibrary: PHPhotoLibrary.shared
    )
    precondition(titled._maxSelectionCount == 5)
    precondition(titled._usesPhotoLibrary)
}

func testPhotosPickerTitleMultiInit() {
    var items: [PhotosPickerItem] = []
    let keyed = PhotosPicker(
        LocalizedStringKey("Photos"),
        selection: Binding(get: { items }, set: { items = $0 }),
        maxSelectionCount: 8,
        matching: .videos
    )
    precondition(keyed._maxSelectionCount == 8)
    precondition(!keyed._usesPhotoLibrary)
    let titled = PhotosPicker(
        "Choose",
        selection: Binding(get: { items }, set: { items = $0 }),
        maxSelectionCount: 6,
        selectionBehavior: .ordered,
        matching: .images
    )
    precondition(titled._selectionBehavior == .ordered)
    precondition(!titled._usesPhotoLibrary)
}

func testPhotosPickerTitleSingleLibraryInit() {
    var single: PhotosPickerItem?
    let keyed = PhotosPicker(
        LocalizedStringKey("Photo"),
        selection: Binding(get: { single }, set: { single = $0 }),
        matching: .images,
        preferredItemEncoding: .compatible,
        photoLibrary: PHPhotoLibrary.shared
    )
    precondition(keyed._usesPhotoLibrary)
    precondition(!keyed._allowsMultipleSelection)
    let titled = PhotosPicker(
        "One",
        selection: Binding(get: { single }, set: { single = $0 }),
        matching: .videos,
        preferredItemEncoding: .current,
        photoLibrary: PHPhotoLibrary.shared
    )
    precondition(titled._filter == .videos)
    precondition(titled._usesPhotoLibrary)
}

func testPhotosPickerTitleSingleInit() {
    var single: PhotosPickerItem?
    let keyed = PhotosPicker(
        LocalizedStringKey("Photo"),
        selection: Binding(get: { single }, set: { single = $0 }),
        matching: .livePhotos
    )
    precondition(!keyed._usesPhotoLibrary)
    precondition(keyed._filter == .livePhotos)
    let titled = PhotosPicker(
        "One",
        selection: Binding(get: { single }, set: { single = $0 }),
        matching: .screenshots,
        preferredItemEncoding: .automatic
    )
    precondition(titled._filter == .screenshots)
}

func testPhotosPickerBodyAndStyleModifier() {
    var items: [PhotosPickerItem] = []
    let picker = PhotosPicker(
        selection: Binding(get: { items }, set: { items = $0 }),
        matching: .images,
        label: { Text("Pick") }
    )
    precondition(picker._appliedStyle == .presentation)
    let styled = picker.photosPickerStyle(.inline)
    precondition(styled._appliedStyle == .inline)
    let compact = styled.photosPickerStyle(.compact)
    precondition(compact._appliedStyle == .compact)
    _ = compact.body
}

func testPhotosPickerAccessoryVisibilityModifier() {
    var items: [PhotosPickerItem] = []
    let picker = PhotosPicker(
        selection: Binding(get: { items }, set: { items = $0 }),
        label: { Text("Pick") }
    )
    precondition(picker._accessoryVisibility == .automatic)
    let hidden = picker.photosPickerAccessoryVisibility(.hidden, edges: .top)
    precondition(hidden._accessoryVisibility == .hidden)
    precondition(hidden._accessoryEdges == .top)
}

func testPhotosPickerDisabledCapabilitiesModifier() {
    var items: [PhotosPickerItem] = []
    let picker = PhotosPicker(
        selection: Binding(get: { items }, set: { items = $0 }),
        label: { Text("Pick") }
    )
    precondition(picker._disabledCapabilities.isEmpty)
    let disabled = picker.photosPickerDisabledCapabilities(.search)
    precondition(disabled._disabledCapabilities.contains(.search))
}

func testPhotosPickerSharedAlbumItemsFailClosed() {
    var items: [PhotosPickerItem] = []
    var presented = true
    var sawError = false
    let picker = PhotosPicker(
        selection: Binding(get: { items }, set: { items = $0 }),
        label: { Text("Pick") }
    )
    _ = picker.postToPhotosSharedAlbumSheet(
        isPresented: Binding(get: { presented }, set: { presented = $0 }),
        items: [] as [PhotosPickerItem],
        photoLibrary: PHPhotoLibrary.shared,
        completion: { result in
            if case .failure = result { sawError = true }
        }
    )
    precondition(!presented)
    precondition(sawError)
}

func testPhotosPickerSharedAlbumResultsFailClosed() {
    var items: [PhotosPickerItem] = []
    var presented = true
    let picker = PhotosPicker(
        selection: Binding(get: { items }, set: { items = $0 }),
        label: { Text("Pick") }
    )
    _ = picker.postToPhotosSharedAlbumSheet(
        isPresented: Binding(get: { presented }, set: { presented = $0 }),
        items: [] as [PHPickerResult],
        photoLibrary: PHPhotoLibrary.shared
    )
    precondition(!presented)
}

func testPhotosPickerModifierMulti() {
    var items: [PhotosPickerItem] = []
    var presented = false
    let picker = PhotosPicker(
        selection: Binding(get: { items }, set: { items = $0 }),
        maxSelectionCount: 1,
        matching: .images,
        label: { Text("Pick") }
    )
    precondition(!picker._presentsUsingModifier)
    let modified = picker.photosPicker(
        isPresented: Binding(get: { presented }, set: { presented = $0 }),
        selection: Binding(get: { items }, set: { items = $0 }),
        maxSelectionCount: 3,
        selectionBehavior: .ordered,
        matching: .videos,
        preferredItemEncoding: .current
    )
    precondition(modified._presentsUsingModifier)
    precondition(modified._maxSelectionCount == 3)
    precondition(modified._selectionBehavior == .ordered)
    precondition(modified._filter == .videos)
    precondition(modified._preferredItemEncoding == .current)
    precondition(modified._allowsMultipleSelection)
    precondition(!modified._usesPhotoLibrary)
}

func testPhotosPickerModifierMultiLibrary() {
    var items: [PhotosPickerItem] = []
    var presented = false
    let picker = PhotosPicker(
        selection: Binding(get: { items }, set: { items = $0 }),
        label: { Text("Pick") }
    )
    let modified = picker.photosPicker(
        isPresented: Binding(get: { presented }, set: { presented = $0 }),
        selection: Binding(get: { items }, set: { items = $0 }),
        maxSelectionCount: 7,
        selectionBehavior: .continuous,
        matching: .livePhotos,
        preferredItemEncoding: .compatible,
        photoLibrary: PHPhotoLibrary.shared
    )
    precondition(modified._presentsUsingModifier)
    precondition(modified._maxSelectionCount == 7)
    precondition(modified._selectionBehavior == .continuous)
    precondition(modified._filter == .livePhotos)
    precondition(modified._usesPhotoLibrary)
    precondition(modified._allowsMultipleSelection)
}

func testPhotosPickerModifierSingle() {
    var items: [PhotosPickerItem] = []
    var single: PhotosPickerItem?
    var presented = false
    let picker = PhotosPicker(
        selection: Binding(get: { items }, set: { items = $0 }),
        maxSelectionCount: 4,
        matching: .images,
        label: { Text("Pick") }
    )
    let modified = picker.photosPicker(
        isPresented: Binding(get: { presented }, set: { presented = $0 }),
        selection: Binding(get: { single }, set: { single = $0 }),
        matching: .screenshots,
        preferredItemEncoding: .current
    )
    precondition(modified._presentsUsingModifier)
    precondition(modified._maxSelectionCount == 1)
    precondition(!modified._allowsMultipleSelection)
    precondition(!modified._usesPhotoLibrary)
    precondition(modified._filter == .screenshots)
    precondition(modified._preferredItemEncoding == .current)
}

func testPhotosPickerModifierSingleLibrary() {
    var items: [PhotosPickerItem] = []
    var single: PhotosPickerItem?
    var presented = false
    let picker = PhotosPicker(
        selection: Binding(get: { items }, set: { items = $0 }),
        label: { Text("Pick") }
    )
    let modified = picker.photosPicker(
        isPresented: Binding(get: { presented }, set: { presented = $0 }),
        selection: Binding(get: { single }, set: { single = $0 }),
        matching: .panoramas,
        preferredItemEncoding: .automatic,
        photoLibrary: PHPhotoLibrary.shared
    )
    precondition(modified._presentsUsingModifier)
    precondition(modified._maxSelectionCount == 1)
    precondition(!modified._allowsMultipleSelection)
    precondition(modified._usesPhotoLibrary)
    precondition(modified._filter == .panoramas)
}
