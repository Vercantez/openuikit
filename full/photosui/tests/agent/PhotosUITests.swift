import Foundation
@_spi(OpenUIKitHost) import PhotosUI

private struct PickedDocument: Transferable, Equatable {
    let bytes: Data
}

private final class CompletionRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: PickedDocument?

    func store(_ document: PickedDocument?) {
        lock.withLock { stored = document }
    }

    var document: PickedDocument? { lock.withLock { stored } }
}

func testPickerMode() {
    precondition(PHPickerMode.default == PHPickerMode.default)
    precondition(PHPickerMode.compact == PHPickerMode.compact)
    precondition(PHPickerMode.default != .compact)
    var hasher = Hasher()
    PHPickerMode.compact.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(PHPickerMode.default.hashValue == PHPickerMode.default.hashValue)
    precondition(Set([PHPickerMode.default, .compact]).count == 2)
}

func testPickerFilterComposition() {
    let any = PHPickerFilter.any(of: [.images, .videos])
    let again = PHPickerFilter.any(of: [.images, .videos])
    let reversed = PHPickerFilter.any(of: [.videos, .images])
    let all = PHPickerFilter.all(of: [.images, .not(.videos)])
    let negated = PHPickerFilter.not(.images)
    precondition(any == again)
    precondition(any != .images)
    precondition(any != reversed)
    precondition(all != any)
    precondition(negated != .images)
    precondition(!(any != again))
    var hasher = Hasher()
    any.hash(into: &hasher)
    all.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(any.hashValue == again.hashValue)
}

func testPickerFilterMatches() {
    let filter = PHPickerFilter.any(of: [.images, .videos])
    precondition(filter._matches([.jpeg]))
    precondition(filter._matches([.movie]))
    precondition(!PHPickerFilter.images._matches([.movie]))
    precondition(
        PHPickerFilter.all(of: [.images, .not(.videos)])._matches([.jpeg])
    )
    precondition(!PHPickerFilter.videos._matches([.jpeg]))
    precondition(PHPickerFilter.not(.videos)._matches([.jpeg]))
}

func testPickerFilterCatalog() {
    let catalog: [PHPickerFilter] = [
        .images, .videos, .livePhotos, .depthEffectPhotos, .screenshots,
        .slomoVideos, .spatialMedia, .cinematicVideos, .timelapseVideos,
        .screenRecordings, .bursts, .panoramas,
        .playbackStyle(.image), .playbackStyle(.video),
    ]
    precondition(Set(catalog).count == catalog.count)
    precondition(PHPickerFilter.playbackStyle(.livePhoto) != .playbackStyle(.videoLooping))
    precondition(PHPickerFilter.playbackStyle(.unsupported) != .images)
    precondition(PHPickerFilter.bursts._matches([.jpeg]))
    precondition(PHPickerFilter.slomoVideos._matches([.movie]))
    precondition(PHPickerFilter.playbackStyle(.image)._matches([.jpeg]))
    precondition(PHPickerFilter.playbackStyle(.video)._matches([.movie]))
    precondition(!PHPickerFilter.playbackStyle(.unsupported)._matches([.jpeg]))
}

func testPickerConfigurationDefaults() {
    let configuration = PHPickerConfiguration()
    precondition(configuration.selectionLimit == 1)
    precondition(configuration.filter == nil)
    precondition(configuration.preselectedAssetIdentifiers.isEmpty)
    precondition(configuration.mode == .default)
    precondition(configuration.preferredAssetRepresentationMode == .automatic)
    precondition(configuration.selection == .default)
    precondition(configuration.disabledCapabilities.isEmpty)
    precondition(configuration.edgesWithoutContentMargins.isEmpty)

    var copy = configuration
    copy.selectionLimit = 4
    copy.filter = .images
    copy.preselectedAssetIdentifiers = ["a"]
    copy.mode = .compact
    copy.preferredAssetRepresentationMode = .current
    copy.selection = .ordered
    copy.disabledCapabilities = .search
    copy.edgesWithoutContentMargins = .top
    precondition(copy.selectionLimit == 4)
    precondition(copy.filter == .images)
    precondition(copy.preselectedAssetIdentifiers == ["a"])
    precondition(copy.mode == .compact)
    precondition(copy.preferredAssetRepresentationMode == .current)
    precondition(copy.selection == .ordered)
    precondition(copy.disabledCapabilities.contains(.search))
    precondition(copy.edgesWithoutContentMargins.contains(.top))
    precondition(copy != configuration)
    precondition(configuration.hashValue == PHPickerConfiguration().hashValue)

    precondition(PHPickerConfiguration.AssetRepresentationMode.automatic != .compatible)
    precondition(PHPickerConfiguration.Selection.continuousAndOrdered != .default)
    var hasher = Hasher()
    configuration.hash(into: &hasher)
    PHPickerConfiguration.AssetRepresentationMode.current.hash(into: &hasher)
    PHPickerConfiguration.Selection.ordered.hash(into: &hasher)
    _ = hasher.finalize()
}

func testPickerConfigurationPhotoLibrary() {
    let configuration = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared)
    precondition(configuration.selectionLimit == 1)
    precondition(configuration.mode == .default)
}

func testPickerConfigurationUpdate() {
    var update = PHPickerConfiguration.Update()
    precondition(update.selectionLimit == nil)
    precondition(update.edgesWithoutContentMargins == nil)
    update.selectionLimit = 8
    update.edgesWithoutContentMargins = .all
    precondition(update.selectionLimit == 8)
    precondition(update.edgesWithoutContentMargins == .all)
    precondition(update != PHPickerConfiguration.Update())
    var hasher = Hasher()
    update.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(PHPickerConfiguration.Update().hashValue == PHPickerConfiguration.Update().hashValue)
}

func testPickerConfigurationObjCEnums() {
    typealias Mode = PHPickerConfigurationAssetRepresentationMode
    typealias Selection = PHPickerConfigurationSelection
    precondition(Mode.automatic.rawValue == 0)
    precondition(Mode.current.rawValue == 1)
    precondition(Mode.compatible.rawValue == 2)
    precondition(Mode(rawValue: 0) == .automatic)
    precondition(Mode(rawValue: 3) == nil)
    precondition(Selection.default.rawValue == 0)
    precondition(Selection.ordered.rawValue == 1)
    precondition(Selection.continuous.rawValue == 2)
    precondition(Selection.continuousAndOrdered.rawValue == 3)
    precondition(Selection(rawValue: 1) == .ordered)
    precondition(Selection(rawValue: 4) == nil)
    precondition(Mode.automatic != .current)
    precondition(Selection.default != .ordered)
    var hasher = Hasher()
    Mode.compatible.hash(into: &hasher)
    Selection.continuous.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(Mode.current.hashValue == Mode.current.hashValue)
    precondition(Selection.ordered.hashValue == Selection.ordered.hashValue)
}

func testPickerCapabilitiesOptionSet() {
    typealias Capabilities = PHPickerCapabilities
    precondition(Capabilities.search.rawValue == 1)
    precondition(Capabilities.stagingArea.rawValue == 2)
    precondition(Capabilities.collectionNavigation.rawValue == 4)
    precondition(Capabilities.selectionActions.rawValue == 8)
    precondition(Capabilities.sensitivityAnalysisIntervention.rawValue == 16)
    precondition(Capabilities().isEmpty)
    precondition(Capabilities(rawValue: 0).isEmpty)

    var capabilities: Capabilities = [.search]
    precondition(capabilities.contains(.search))
    let inserted = capabilities.insert(.search)
    precondition(!inserted.inserted)
    precondition(capabilities.remove(.search) == .search)
    precondition(!capabilities.contains(.search))
    precondition(capabilities.update(with: .stagingArea) == nil)
    precondition(capabilities.contains(.stagingArea))

    let union = Capabilities.search.union(.stagingArea)
    precondition(union.contains(.search) && union.contains(.stagingArea))
    let intersection = union.intersection(.search)
    precondition(intersection == .search)
    let difference = union.symmetricDifference(.search)
    precondition(difference == .stagingArea)
    precondition(union.subtracting(.search) == .stagingArea)
    precondition(Capabilities.search.isSubset(of: union))
    precondition(union.isSuperset(of: .search))
    precondition(!Capabilities.search.isDisjoint(with: union))
    precondition(Capabilities.search.isDisjoint(with: .stagingArea))
    precondition(union.isStrictSuperset(of: .search))
    precondition(Capabilities.search.isStrictSubset(of: union))

    var mutating = Capabilities.search
    mutating.formUnion(.collectionNavigation)
    mutating.formIntersection([.search, .collectionNavigation])
    mutating.formSymmetricDifference(.search)
    mutating.subtract(.selectionActions)
    precondition(mutating.contains(.collectionNavigation))

    let fromSequence = Capabilities([.search, .stagingArea])
    precondition(fromSequence.contains(.search))
    let literals: Capabilities = [.search, .selectionActions]
    precondition(literals.contains(.selectionActions))
    precondition(Capabilities.search != Capabilities())
}

func testLivePhotoBadgeOptions() {
    typealias Options = PHLivePhotoBadgeOptions
    precondition(Options.overContent.rawValue == 1)
    precondition(Options.liveOff.rawValue == 2)
    precondition(Options().isEmpty)
    var options: Options = [.overContent, .liveOff]
    precondition(options.contains(.overContent))
    precondition(options.contains(.liveOff))
    precondition(options.union(.overContent) == options)
    precondition(options.intersection(.overContent) == .overContent)
    precondition(Options.overContent != .liveOff)
    precondition(Options.overContent.isDisjoint(with: .liveOff))
    let fromSequence = Options([.overContent])
    precondition(fromSequence.contains(.overContent))
    let literals: Options = [.liveOff]
    precondition(literals.contains(.liveOff))
    _ = options.insert(.overContent)
    _ = options.remove(.liveOff)
    _ = options.update(with: .liveOff)
    options.formUnion(.overContent)
    options.formIntersection(.liveOff)
    options.formSymmetricDifference(.overContent)
    options.subtract(.overContent)
    precondition(Options.overContent.isSubset(of: [.overContent, .liveOff]))
    precondition(Options([.overContent, .liveOff]).isSuperset(of: .overContent))
    precondition(Options([.overContent, .liveOff]).isStrictSuperset(of: .overContent))
    precondition(Options.overContent.isStrictSubset(of: [.overContent, .liveOff]))
    precondition(Options.overContent.subtracting(.overContent).isEmpty)
}

func testPlaybackStyleRawValues() {
    typealias Style = PHLivePhotoViewPlaybackStyle
    precondition(Style.undefined.rawValue == 0)
    precondition(Style.full.rawValue == 1)
    precondition(Style.hint.rawValue == 2)
    precondition(Style(rawValue: 0) == .undefined)
    precondition(Style(rawValue: 3) == nil)
    precondition(Style.full != .hint)
    var hasher = Hasher()
    Style.full.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(Style.hint.hashValue == Style.hint.hashValue)
}

func testPhotosPickerItemIdentity() {
    let first = PhotosPickerItem(itemIdentifier: "first")
    let again = PhotosPickerItem(itemIdentifier: "first")
    let second = PhotosPickerItem(itemIdentifier: "second")
    precondition(first.itemIdentifier == "first")
    precondition(first.supportedContentTypes.isEmpty)
    precondition(first == again)
    precondition(first != second)
    precondition(!(first != again))
    var hasher = Hasher()
    first.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(first.hashValue == again.hashValue)
    precondition(Set([first, second]).count == 2)
}

func testPhotosPickerItemLoad() {
    let payload = PickedDocument(bytes: Data("picked".utf8))
    let first = PhotosPickerItem(itemIdentifier: "first", supportedContentTypes: [.data])
    first._installTransferable(payload)
    let second = PhotosPickerItem(itemIdentifier: "second")
    precondition(first.supportedContentTypes == [.data])

    let completion = CompletionRecorder()
    let progress = first.loadTransferable(type: PickedDocument.self) { result in
        completion.store(try? result.get())
    }
    precondition(progress.isFinished)
    precondition(completion.document == payload)

    let missingProgress = second.loadTransferable(type: PickedDocument.self) { result in
        completion.store(try? result.get())
    }
    precondition(missingProgress.isFinished)
    precondition(completion.document == nil)
}

func testPhotosPickerItemEncoding() {
    typealias Policy = PhotosPickerItem.EncodingDisambiguationPolicy
    precondition(Policy.automatic != .current)
    precondition(Policy.current != .compatible)
    precondition(Policy.automatic == .automatic)
    var hasher = Hasher()
    Policy.compatible.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(Policy.current.hashValue == Policy.current.hashValue)
}

func testPickerResult() {
    let provider = NSItemProvider()
    let result = PHPickerResult(itemProvider: provider, assetIdentifier: "asset-1")
    precondition(result.assetIdentifier == "asset-1")
    precondition(result.itemProvider === provider)
    let same = PHPickerResult(itemProvider: provider, assetIdentifier: "asset-1")
    precondition(result == same)
    precondition(result.hashValue == same.hashValue)
    let other = PHPickerResult(itemProvider: NSItemProvider(), assetIdentifier: "asset-2")
    precondition(result != other)
}

func testPickerResultItemProviderLoad() {
    let jpeg = Data("jpeg-bytes".utf8)
    let result = PHPickerResult._hostResult(
        assetIdentifier: "asset-jpeg",
        typeIdentifier: UTType.jpeg.identifier,
        payload: jpeg
    )
    precondition(result.assetIdentifier == "asset-jpeg")
    let provider = result.itemProvider
    precondition(provider.registeredTypeIdentifiers.contains(where: { $0 == UTType.jpeg.identifier }))
    precondition(provider.hasItemConformingToTypeIdentifier(UTType.jpeg.identifier))
    precondition(provider.hasItemConformingToTypeIdentifier(UTType.image.identifier))
    precondition(provider.canLoadObject(ofClass: Data.self))
    precondition(!provider.canLoadObject(ofClass: NSString.self))

    let dataBox = CompletionRecorder()
    let dataProgress = provider.loadDataRepresentation(forTypeIdentifier: UTType.jpeg.identifier) { data, error in
        precondition(error == nil)
        dataBox.store(data.map { PickedDocument(bytes: $0) })
    }
    precondition(dataProgress.isFinished)
    precondition(dataBox.document?.bytes == jpeg)

    let fileBox = CompletionRecorder()
    let fileProgress = provider.loadFileRepresentation(forTypeIdentifier: UTType.jpeg.identifier) { url, error in
        precondition(error == nil)
        let bytes = url.flatMap { try? Data(contentsOf: $0) }
        fileBox.store(bytes.map { PickedDocument(bytes: $0) })
    }
    precondition(fileProgress.isFinished)
    precondition(fileBox.document?.bytes == jpeg)

    let objectBox = CompletionRecorder()
    let objectProgress = provider.loadObject(ofClass: Data.self) { object, error in
        precondition(error == nil)
        objectBox.store(object.map { PickedDocument(bytes: $0) })
    }
    precondition(objectProgress.isFinished)
    precondition(objectBox.document?.bytes == jpeg)
}

private final class PickerDelegateProbe: PHPickerViewControllerDelegate, @unchecked Sendable {
    private let lock = NSLock()
    private var stored: (picker: PHPickerViewController, results: [PHPickerResult])?
    private(set) var onMain = false

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        lock.withLock {
            stored = (picker, results)
            onMain = Thread.isMainThread
        }
    }

    var last: (picker: PHPickerViewController, results: [PHPickerResult])? {
        lock.withLock { stored }
    }
}

func testPickerViewController() {
    var configuration = PHPickerConfiguration()
    configuration.selectionLimit = 3
    let picker = PHPickerViewController(configuration: configuration)
    precondition(picker.configuration.selectionLimit == 3)
    precondition(picker.delegate == nil)
    picker.deselectAssets(withIdentifiers: ["a"])
    picker.moveAsset(withIdentifier: "a", afterAssetWithIdentifier: nil)
    picker.scrollToInitialPosition()
    picker.zoomIn()
    picker.zoomOut()
    var update = PHPickerConfiguration.Update()
    update.selectionLimit = 2
    picker.updatePicker(using: update)
    precondition(picker._appliedUpdate?.selectionLimit == 2)
}

func testPickerDelegateEmptySelection() {
    let picker = PHPickerViewController(configuration: PHPickerConfiguration())
    let probe = PickerDelegateProbe()
    picker.delegate = probe
    picker._present()
    let last = probe.last
    precondition(last?.picker === picker)
    precondition(last?.results.isEmpty == true)
    precondition(probe.onMain)
}

func testPickerDelegateEnqueuedResults() {
    let jpeg = Data("picked-jpeg".utf8)
    let queued = PHPickerResult._hostResult(
        assetIdentifier: "queued",
        typeIdentifier: UTType.jpeg.identifier,
        payload: jpeg
    )
    let picker = PHPickerViewController(configuration: PHPickerConfiguration())
    let probe = PickerDelegateProbe()
    picker.delegate = probe
    picker._enqueueResults([queued])
    picker._present()
    let last = probe.last
    precondition(last?.results.count == 1)
    precondition(last?.results.first?.assetIdentifier == "queued")
    precondition(probe.onMain)

    picker._present()
    precondition(probe.last?.results.isEmpty == true)
}

func testPhotosPickerStyleAndBehavior() {
    precondition(PhotosPickerStyle.presentation != .inline)
    precondition(PhotosPickerStyle.compact != .presentation)
    precondition(PhotosPickerSelectionBehavior.default != .ordered)
    precondition(PhotosPickerSelectionBehavior.continuous != .continuousAndOrdered)
    var hasher = Hasher()
    PhotosPickerStyle.inline.hash(into: &hasher)
    PhotosPickerSelectionBehavior.ordered.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(PhotosPickerStyle.presentation.hashValue == PhotosPickerStyle.presentation.hashValue)
    precondition(
        PhotosPickerSelectionBehavior.default.hashValue
            == PhotosPickerSelectionBehavior.default.hashValue
    )
}

func testLimitedLibraryPickerFailClosed() {
    let library = PHPhotoLibrary.shared
    let controller = UIViewController()
    library.presentLimitedLibraryPicker(from: controller)
    var completed: [String]?
    library.presentLimitedLibraryPicker(from: controller) { identifiers in
        completed = identifiers
    }
    precondition(completed == [])
}

func testPhotosPickerConstruct() {
    var items: [PhotosPickerItem] = []
    var single: PhotosPickerItem?
    let labeled = PhotosPicker(
        selection: Binding(get: { items }, set: { items = $0 }),
        maxSelectionCount: 4,
        selectionBehavior: .ordered,
        matching: .images,
        preferredItemEncoding: .automatic,
        photoLibrary: PHPhotoLibrary.shared,
        label: { Text("Pick") }
    )
    _ = labeled.body
    let unlabeled = PhotosPicker("Choose", selection: Binding(get: { items }, set: { items = $0 }))
    _ = unlabeled.body
    let singlePicker = PhotosPicker(
        selection: Binding(get: { single }, set: { single = $0 }),
        matching: .videos,
        preferredItemEncoding: .current,
        label: { Text("One") }
    )
    _ = singlePicker.body
    let titleSingle = PhotosPicker(
        LocalizedStringKey("Photo"),
        selection: Binding(get: { single }, set: { single = $0 }),
        matching: .images,
        preferredItemEncoding: .compatible,
        photoLibrary: PHPhotoLibrary.shared
    )
    _ = titleSingle.body
}

func testViewPhotosPickerModifiers() {
    let view = Text("Photos")
    var presented = false
    var items: [PhotosPickerItem] = []
    var single: PhotosPickerItem?
    _ = view.photosPicker(
        isPresented: Binding(get: { presented }, set: { presented = $0 }),
        selection: Binding(get: { items }, set: { items = $0 }),
        maxSelectionCount: 4,
        matching: .any(of: [.images, .videos])
    )
    _ = view.photosPicker(
        isPresented: Binding(get: { presented }, set: { presented = $0 }),
        selection: Binding(get: { single }, set: { single = $0 }),
        matching: .images,
        preferredItemEncoding: .automatic
    )
    _ = view.photosPickerStyle(.inline)
    _ = view.photosPickerAccessoryVisibility(.visible, edges: .all)
    _ = view.photosPickerDisabledCapabilities(.search)
}

func testSharedAlbumFailClosed() {
    var presented = true
    var sawError = false
    _ = Text("Album").postToPhotosSharedAlbumSheet(
        isPresented: Binding(get: { presented }, set: { presented = $0 }),
        items: [] as [PhotosPickerItem],
        photoLibrary: PHPhotoLibrary.shared,
        defaultAlbumIdentifier: nil,
        completion: { result in
            if case .failure = result { sawError = true }
        }
    )
    precondition(!presented)
    precondition(sawError)
}

func testLivePhotoViewFailClosed() {
    let view = PHLivePhotoView()
    precondition(view.livePhoto == nil)
    precondition(!view.isMuted)
    view.isMuted = true
    view.contentsRect = CGRect(x: 0, y: 0, width: 10, height: 10)
    precondition(view.isMuted)
    precondition(view.contentsRect.width == 10)
    _ = view.playbackGestureRecognizer

    let probe = LivePhotoDelegateProbe()
    view.delegate = probe
    view.startPlayback(with: .hint)
    view.startPlayback(with: .full)
    view.stopPlayback()
    precondition(!probe.willBegin)
    precondition(!probe.didEnd)
    precondition(probe.canBegin(view, style: .hint))
    precondition(probe.extraDuration(view, touch: UITouch(), style: .hint) == 0)

    let badge = PHLivePhotoView.livePhotoBadgeImage(options: .overContent)
    precondition(badge === badge)
}

private final class LivePhotoDelegateProbe: PHLivePhotoViewDelegate {
    var willBegin = false
    var didEnd = false

    func livePhotoView(
        _ livePhotoView: PHLivePhotoView,
        willBeginPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle
    ) {
        _ = livePhotoView
        _ = playbackStyle
        willBegin = true
    }

    func livePhotoView(
        _ livePhotoView: PHLivePhotoView,
        didEndPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle
    ) {
        _ = livePhotoView
        _ = playbackStyle
        didEnd = true
    }

    func canBegin(
        _ view: PHLivePhotoView,
        style: PHLivePhotoViewPlaybackStyle
    ) -> Bool {
        livePhotoView(view, canBeginPlaybackWith: style)
    }

    func extraDuration(
        _ view: PHLivePhotoView,
        touch: UITouch,
        style: PHLivePhotoViewPlaybackStyle
    ) -> TimeInterval {
        livePhotoView(view, extraMinimumTouchDurationFor: touch, with: style)
    }
}

private final class ContentEditingStub: PHContentEditingController {
    var shouldShowCancelConfirmation = false
    var started = false
    var cancelled = false
    var finished = false

    func canHandle(_ adjustmentData: PHAdjustmentData) -> Bool {
        _ = adjustmentData
        return false
    }

    func startContentEditing(
        with contentEditingInput: PHContentEditingInput,
        placeholderImage: UIImage
    ) {
        _ = contentEditingInput
        _ = placeholderImage
        started = true
    }

    func finishContentEditing(completionHandler: @escaping (PHContentEditingOutput?) -> Void) {
        finished = true
        completionHandler(nil)
    }

    func cancelContentEditing() {
        cancelled = true
    }
}

func testContentEditingControllerShape() {
    let editor = ContentEditingStub()
    precondition(!editor.shouldShowCancelConfirmation)
    precondition(!editor.canHandle(PHAdjustmentData()))
    editor.startContentEditing(with: PHContentEditingInput(), placeholderImage: UIImage())
    var output: PHContentEditingOutput? = PHContentEditingOutput()
    editor.finishContentEditing { output = $0 }
    editor.cancelContentEditing()
    precondition(editor.started)
    precondition(editor.finished)
    precondition(editor.cancelled)
    precondition(output == nil)
}

func testPhotosPickerInheritedModifiers() {
    var items: [PhotosPickerItem] = []
    var presented = true
    let picker = PhotosPicker(
        selection: Binding(get: { items }, set: { items = $0 }),
        matching: .images,
        label: { Text("Pick") }
    )
    _ = picker.photosPicker(
        isPresented: Binding(get: { presented }, set: { presented = $0 }),
        selection: Binding(get: { items }, set: { items = $0 }),
        maxSelectionCount: 2,
        matching: .images
    )
    _ = picker.photosPicker(
        isPresented: Binding(get: { presented }, set: { presented = $0 }),
        selection: Binding(get: { items }, set: { items = $0 }),
        maxSelectionCount: 2,
        matching: .images,
        photoLibrary: PHPhotoLibrary.shared
    )
    var single: PhotosPickerItem?
    _ = picker.photosPicker(
        isPresented: Binding(get: { presented }, set: { presented = $0 }),
        selection: Binding(get: { single }, set: { single = $0 }),
        matching: .videos
    )
    _ = picker.photosPicker(
        isPresented: Binding(get: { presented }, set: { presented = $0 }),
        selection: Binding(get: { single }, set: { single = $0 }),
        matching: .videos,
        photoLibrary: PHPhotoLibrary.shared
    )
    _ = picker.photosPickerStyle(.inline)
    _ = picker.photosPickerAccessoryVisibility(.visible, edges: .all)
    _ = picker.photosPickerDisabledCapabilities(.search)
    var sawError = false
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
    presented = true
    _ = picker.postToPhotosSharedAlbumSheet(
        isPresented: Binding(get: { presented }, set: { presented = $0 }),
        items: [] as [PHPickerResult],
        photoLibrary: PHPhotoLibrary.shared
    )
    precondition(!presented)
}

func testDirectionalEdges() {
    precondition(NSDirectionalRectEdge.top.rawValue == 1)
    precondition(NSDirectionalRectEdge.leading.rawValue == 2)
    precondition(NSDirectionalRectEdge.bottom.rawValue == 4)
    precondition(NSDirectionalRectEdge.trailing.rawValue == 8)
    precondition(NSDirectionalRectEdge.all.contains(.top))
}

func testAssetPlaybackStyle() {
    precondition(PHAsset.PlaybackStyle.unsupported.rawValue == 0)
    precondition(PHAsset.PlaybackStyle.image.rawValue == 1)
    precondition(PHAsset.PlaybackStyle.imageAnimated.rawValue == 2)
    precondition(PHAsset.PlaybackStyle.livePhoto.rawValue == 3)
    precondition(PHAsset.PlaybackStyle.video.rawValue == 4)
    precondition(PHAsset.PlaybackStyle.videoLooping.rawValue == 5)
}
