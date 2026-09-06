import Foundation

public enum PhotosUIPortableError: Error, Equatable, Sendable {
    case itemUnavailable(identifier: String, type: String)
}

private final class _PortablePhotosPickerItemBox: @unchecked Sendable {
    let identifier: String
    let supportedContentTypes: [UTType]

    private let lock = NSLock()
    private var transferables: [ObjectIdentifier: Any] = [:]

    init(identifier: String, supportedContentTypes: [UTType]) {
        self.identifier = identifier
        self.supportedContentTypes = supportedContentTypes
    }

    func install<T: Transferable>(_ value: T) {
        lock.withLock { transferables[ObjectIdentifier(T.self)] = value }
    }

    func load<T: Transferable>(_ type: T.Type) -> T? {
        lock.withLock { transferables[ObjectIdentifier(type)] as? T }
    }
}

public struct PhotosPickerItem: Hashable, @unchecked Sendable {
    public struct EncodingDisambiguationPolicy: Equatable, Hashable, Sendable {
        private let rawValue: UInt8

        private init(rawValue: UInt8) {
            self.rawValue = rawValue
        }

        public static let automatic = EncodingDisambiguationPolicy(rawValue: 0)
        public static let current = EncodingDisambiguationPolicy(rawValue: 1)
        public static let compatible = EncodingDisambiguationPolicy(rawValue: 2)
    }

    private let box: _PortablePhotosPickerItemBox

    public init(itemIdentifier: String) {
        box = _PortablePhotosPickerItemBox(
            identifier: itemIdentifier,
            supportedContentTypes: []
        )
    }

    @_spi(OpenUIKitHost)
    public init(itemIdentifier: String, supportedContentTypes: [UTType]) {
        box = _PortablePhotosPickerItemBox(
            identifier: itemIdentifier,
            supportedContentTypes: supportedContentTypes
        )
    }

    public var itemIdentifier: String? { box.identifier }
    public var supportedContentTypes: [UTType] { box.supportedContentTypes }

    /// Linux host: completes inline. Apple's method is `async throws` and
    /// hops to a loading executor (oracle-questions.tsv).
    public func loadTransferable<T: Transferable>(
        type: T.Type
    ) throws -> T? {
        box.load(type)
    }

    @discardableResult
    public func loadTransferable<T: Transferable>(
        type: T.Type,
        completionHandler: @escaping @Sendable (Result<T?, Error>) -> Void
    ) -> Progress {
        let progress = Progress(totalUnitCount: 1)
        completionHandler(.success(box.load(type)))
        progress.completedUnitCount = 1
        return progress
    }

    @_spi(OpenUIKitHost)
    public func _installTransferable<T: Transferable>(_ value: T) {
        box.install(value)
    }

    public static func == (lhs: PhotosPickerItem, rhs: PhotosPickerItem) -> Bool {
        lhs.box.identifier == rhs.box.identifier
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(box.identifier)
    }
}

public struct PhotosPickerSelectionBehavior: Equatable, Hashable, Sendable {
    private let rawValue: UInt8

    private init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public static let `default` = PhotosPickerSelectionBehavior(rawValue: 0)
    public static let ordered = PhotosPickerSelectionBehavior(rawValue: 1)
    public static let continuous = PhotosPickerSelectionBehavior(rawValue: 2)
    public static let continuousAndOrdered = PhotosPickerSelectionBehavior(rawValue: 3)
}

public struct PhotosPickerStyle: Equatable, Hashable, Sendable {
    private let rawValue: UInt8

    private init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public static let presentation = PhotosPickerStyle(rawValue: 0)
    public static let inline = PhotosPickerStyle(rawValue: 1)
    public static let compact = PhotosPickerStyle(rawValue: 2)
}

@MainActor
public enum PhotosUIPortable {
    public enum Event: Equatable, Sendable {
        case present(maxSelectionCount: Int?, filter: PHPickerFilter?)
        case dismiss
    }

    public typealias EventHandler = @MainActor @Sendable (Event) -> Void

    private static var eventHandler: EventHandler?
    private static var selectionHandler: (([PhotosPickerItem]) -> Void)?
    private static var dismissalHandler: (() -> Void)?
    private static var maximumSelectionCount: Int?

    public static var supportsSystemPicker: Bool { eventHandler != nil }

    @_spi(OpenUIKitHost)
    public static func _installEventHandler(_ handler: EventHandler?) {
        eventHandler = handler
    }

    @_spi(OpenUIKitHost)
    public static func _hostDidSelect(_ items: [PhotosPickerItem]) {
        let accepted: [PhotosPickerItem]
        if let maximumSelectionCount, maximumSelectionCount >= 0 {
            accepted = Array(items.prefix(maximumSelectionCount))
        } else {
            accepted = items
        }
        selectionHandler?(accepted)
        finishPresentation()
    }

    @_spi(OpenUIKitHost)
    public static func _hostDidDismiss() {
        finishPresentation()
    }

    @_spi(OpenUIKitHost)
    public static func _reset() {
        eventHandler = nil
        selectionHandler = nil
        dismissalHandler = nil
        maximumSelectionCount = nil
    }

    @_spi(OpenUIKitHost)
    public static func _requestPresentation(
        maxSelectionCount: Int?,
        filter: PHPickerFilter?,
        selection: @escaping ([PhotosPickerItem]) -> Void,
        dismissal: @escaping () -> Void
    ) -> Bool {
        guard let eventHandler else { return false }
        maximumSelectionCount = maxSelectionCount
        selectionHandler = selection
        dismissalHandler = dismissal
        eventHandler(.present(maxSelectionCount: maxSelectionCount, filter: filter))
        return true
    }

    @_spi(OpenUIKitHost)
    public static func _dismissPresentation() {
        guard selectionHandler != nil || dismissalHandler != nil else { return }
        finishPresentation()
    }

    private static func finishPresentation() {
        let dismissal = dismissalHandler
        selectionHandler = nil
        dismissalHandler = nil
        maximumSelectionCount = nil
        dismissal?()
        eventHandler?(.dismiss)
    }
}

public struct PhotosPicker<Label: View>: View {
    private let label: Label
    fileprivate var maxSelectionCount: Int?
    fileprivate var selectionBehavior: PhotosPickerSelectionBehavior
    fileprivate var filter: PHPickerFilter?
    fileprivate var preferredItemEncoding: PhotosPickerItem.EncodingDisambiguationPolicy
    fileprivate var usesPhotoLibrary: Bool
    fileprivate var allowsMultipleSelection: Bool
    fileprivate var appliedStyle: PhotosPickerStyle
    fileprivate var accessoryVisibility: Visibility
    fileprivate var accessoryEdges: Edge.Set
    fileprivate var disabledCapabilities: PHPickerCapabilities
    fileprivate var presentsUsingModifier: Bool

    public var body: Label { label }

    @_spi(OpenUIKitHost)
    public var _maxSelectionCount: Int? { maxSelectionCount }
    @_spi(OpenUIKitHost)
    public var _selectionBehavior: PhotosPickerSelectionBehavior { selectionBehavior }
    @_spi(OpenUIKitHost)
    public var _filter: PHPickerFilter? { filter }
    @_spi(OpenUIKitHost)
    public var _preferredItemEncoding: PhotosPickerItem.EncodingDisambiguationPolicy {
        preferredItemEncoding
    }
    @_spi(OpenUIKitHost)
    public var _usesPhotoLibrary: Bool { usesPhotoLibrary }
    @_spi(OpenUIKitHost)
    public var _allowsMultipleSelection: Bool { allowsMultipleSelection }
    @_spi(OpenUIKitHost)
    public var _appliedStyle: PhotosPickerStyle { appliedStyle }
    @_spi(OpenUIKitHost)
    public var _accessoryVisibility: Visibility { accessoryVisibility }
    @_spi(OpenUIKitHost)
    public var _accessoryEdges: Edge.Set { accessoryEdges }
    @_spi(OpenUIKitHost)
    public var _disabledCapabilities: PHPickerCapabilities { disabledCapabilities }
    @_spi(OpenUIKitHost)
    public var _presentsUsingModifier: Bool { presentsUsingModifier }

    public init(
        selection: Binding<[PhotosPickerItem]>,
        maxSelectionCount: Int? = nil,
        selectionBehavior: PhotosPickerSelectionBehavior = .default,
        matching filter: PHPickerFilter? = nil,
        preferredItemEncoding: PhotosPickerItem.EncodingDisambiguationPolicy = .automatic,
        photoLibrary: PHPhotoLibrary,
        @ViewBuilder label: () -> Label
    ) {
        _ = selection
        _ = photoLibrary
        self.label = label()
        self.maxSelectionCount = maxSelectionCount
        self.selectionBehavior = selectionBehavior
        self.filter = filter
        self.preferredItemEncoding = preferredItemEncoding
        self.usesPhotoLibrary = true
        self.allowsMultipleSelection = true
        self.appliedStyle = .presentation
        self.accessoryVisibility = .automatic
        self.accessoryEdges = .all
        self.disabledCapabilities = []
        self.presentsUsingModifier = false
    }

    public init(
        selection: Binding<[PhotosPickerItem]>,
        maxSelectionCount: Int? = nil,
        selectionBehavior: PhotosPickerSelectionBehavior = .default,
        matching filter: PHPickerFilter? = nil,
        preferredItemEncoding: PhotosPickerItem.EncodingDisambiguationPolicy = .automatic,
        @ViewBuilder label: () -> Label
    ) {
        _ = selection
        self.label = label()
        self.maxSelectionCount = maxSelectionCount
        self.selectionBehavior = selectionBehavior
        self.filter = filter
        self.preferredItemEncoding = preferredItemEncoding
        self.usesPhotoLibrary = false
        self.allowsMultipleSelection = true
        self.appliedStyle = .presentation
        self.accessoryVisibility = .automatic
        self.accessoryEdges = .all
        self.disabledCapabilities = []
        self.presentsUsingModifier = false
    }

    public init(
        selection: Binding<PhotosPickerItem?>,
        matching filter: PHPickerFilter? = nil,
        preferredItemEncoding: PhotosPickerItem.EncodingDisambiguationPolicy = .automatic,
        photoLibrary: PHPhotoLibrary,
        @ViewBuilder label: () -> Label
    ) {
        _ = selection
        _ = photoLibrary
        self.label = label()
        self.maxSelectionCount = 1
        self.selectionBehavior = .default
        self.filter = filter
        self.preferredItemEncoding = preferredItemEncoding
        self.usesPhotoLibrary = true
        self.allowsMultipleSelection = false
        self.appliedStyle = .presentation
        self.accessoryVisibility = .automatic
        self.accessoryEdges = .all
        self.disabledCapabilities = []
        self.presentsUsingModifier = false
    }

    public init(
        selection: Binding<PhotosPickerItem?>,
        matching filter: PHPickerFilter? = nil,
        preferredItemEncoding: PhotosPickerItem.EncodingDisambiguationPolicy = .automatic,
        @ViewBuilder label: () -> Label
    ) {
        _ = selection
        self.label = label()
        self.maxSelectionCount = 1
        self.selectionBehavior = .default
        self.filter = filter
        self.preferredItemEncoding = preferredItemEncoding
        self.usesPhotoLibrary = false
        self.allowsMultipleSelection = false
        self.appliedStyle = .presentation
        self.accessoryVisibility = .automatic
        self.accessoryEdges = .all
        self.disabledCapabilities = []
        self.presentsUsingModifier = false
    }
}

extension PhotosPicker where Label == Text {
    public init(
        _ titleKey: LocalizedStringKey,
        selection: Binding<[PhotosPickerItem]>,
        maxSelectionCount: Int? = nil,
        selectionBehavior: PhotosPickerSelectionBehavior = .default,
        matching filter: PHPickerFilter? = nil,
        preferredItemEncoding: PhotosPickerItem.EncodingDisambiguationPolicy = .automatic,
        photoLibrary: PHPhotoLibrary
    ) {
        self.init(
            selection: selection,
            maxSelectionCount: maxSelectionCount,
            selectionBehavior: selectionBehavior,
            matching: filter,
            preferredItemEncoding: preferredItemEncoding,
            photoLibrary: photoLibrary,
            label: { Text(titleKey) }
        )
    }

    public init<S: StringProtocol>(
        _ title: S,
        selection: Binding<[PhotosPickerItem]>,
        maxSelectionCount: Int? = nil,
        selectionBehavior: PhotosPickerSelectionBehavior = .default,
        matching filter: PHPickerFilter? = nil,
        preferredItemEncoding: PhotosPickerItem.EncodingDisambiguationPolicy = .automatic,
        photoLibrary: PHPhotoLibrary
    ) {
        self.init(
            selection: selection,
            maxSelectionCount: maxSelectionCount,
            selectionBehavior: selectionBehavior,
            matching: filter,
            preferredItemEncoding: preferredItemEncoding,
            photoLibrary: photoLibrary,
            label: { Text(String(title)) }
        )
    }

    public init(
        _ titleKey: LocalizedStringKey,
        selection: Binding<[PhotosPickerItem]>,
        maxSelectionCount: Int? = nil,
        selectionBehavior: PhotosPickerSelectionBehavior = .default,
        matching filter: PHPickerFilter? = nil,
        preferredItemEncoding: PhotosPickerItem.EncodingDisambiguationPolicy = .automatic
    ) {
        self.init(
            selection: selection,
            maxSelectionCount: maxSelectionCount,
            selectionBehavior: selectionBehavior,
            matching: filter,
            preferredItemEncoding: preferredItemEncoding,
            label: { Text(titleKey) }
        )
    }

    public init<S: StringProtocol>(
        _ title: S,
        selection: Binding<[PhotosPickerItem]>,
        maxSelectionCount: Int? = nil,
        selectionBehavior: PhotosPickerSelectionBehavior = .default,
        matching filter: PHPickerFilter? = nil,
        preferredItemEncoding: PhotosPickerItem.EncodingDisambiguationPolicy = .automatic
    ) {
        self.init(
            selection: selection,
            maxSelectionCount: maxSelectionCount,
            selectionBehavior: selectionBehavior,
            matching: filter,
            preferredItemEncoding: preferredItemEncoding,
            label: { Text(String(title)) }
        )
    }

    public init(
        _ titleKey: LocalizedStringKey,
        selection: Binding<PhotosPickerItem?>,
        matching filter: PHPickerFilter? = nil,
        preferredItemEncoding: PhotosPickerItem.EncodingDisambiguationPolicy = .automatic,
        photoLibrary: PHPhotoLibrary
    ) {
        self.init(
            selection: selection,
            matching: filter,
            preferredItemEncoding: preferredItemEncoding,
            photoLibrary: photoLibrary,
            label: { Text(titleKey) }
        )
    }

    public init<S: StringProtocol>(
        _ title: S,
        selection: Binding<PhotosPickerItem?>,
        matching filter: PHPickerFilter? = nil,
        preferredItemEncoding: PhotosPickerItem.EncodingDisambiguationPolicy = .automatic,
        photoLibrary: PHPhotoLibrary
    ) {
        self.init(
            selection: selection,
            matching: filter,
            preferredItemEncoding: preferredItemEncoding,
            photoLibrary: photoLibrary,
            label: { Text(String(title)) }
        )
    }

    public init(
        _ titleKey: LocalizedStringKey,
        selection: Binding<PhotosPickerItem?>,
        matching filter: PHPickerFilter? = nil,
        preferredItemEncoding: PhotosPickerItem.EncodingDisambiguationPolicy = .automatic
    ) {
        self.init(
            selection: selection,
            matching: filter,
            preferredItemEncoding: preferredItemEncoding,
            label: { Text(titleKey) }
        )
    }

    public init<S: StringProtocol>(
        _ title: S,
        selection: Binding<PhotosPickerItem?>,
        matching filter: PHPickerFilter? = nil,
        preferredItemEncoding: PhotosPickerItem.EncodingDisambiguationPolicy = .automatic
    ) {
        self.init(
            selection: selection,
            matching: filter,
            preferredItemEncoding: preferredItemEncoding,
            label: { Text(String(title)) }
        )
    }
}

extension PhotosPicker {
    public func photosPickerStyle(_ style: PhotosPickerStyle) -> Self {
        var copy = self
        copy.appliedStyle = style
        return copy
    }

    public func photosPickerAccessoryVisibility(
        _ visibility: Visibility,
        edges: Edge.Set = .all
    ) -> Self {
        var copy = self
        copy.accessoryVisibility = visibility
        copy.accessoryEdges = edges
        return copy
    }

    public func photosPickerDisabledCapabilities(
        _ disabledCapabilities: PHPickerCapabilities
    ) -> Self {
        var copy = self
        copy.disabledCapabilities = disabledCapabilities
        return copy
    }

    public func photosPicker(
        isPresented: Binding<Bool>,
        selection: Binding<PhotosPickerItem?>,
        matching filter: PHPickerFilter? = nil,
        preferredItemEncoding: PhotosPickerItem.EncodingDisambiguationPolicy = .automatic,
        photoLibrary: PHPhotoLibrary
    ) -> Self {
        _ = isPresented
        _ = selection
        _ = photoLibrary
        var copy = self
        copy.maxSelectionCount = 1
        copy.selectionBehavior = .default
        copy.filter = filter
        copy.preferredItemEncoding = preferredItemEncoding
        copy.usesPhotoLibrary = true
        copy.allowsMultipleSelection = false
        copy.presentsUsingModifier = true
        return copy
    }

    public func photosPicker(
        isPresented: Binding<Bool>,
        selection: Binding<PhotosPickerItem?>,
        matching filter: PHPickerFilter? = nil,
        preferredItemEncoding: PhotosPickerItem.EncodingDisambiguationPolicy = .automatic
    ) -> Self {
        _ = isPresented
        _ = selection
        var copy = self
        copy.maxSelectionCount = 1
        copy.selectionBehavior = .default
        copy.filter = filter
        copy.preferredItemEncoding = preferredItemEncoding
        copy.usesPhotoLibrary = false
        copy.allowsMultipleSelection = false
        copy.presentsUsingModifier = true
        return copy
    }

    public func photosPicker(
        isPresented: Binding<Bool>,
        selection: Binding<[PhotosPickerItem]>,
        maxSelectionCount: Int? = nil,
        selectionBehavior: PhotosPickerSelectionBehavior = .default,
        matching filter: PHPickerFilter? = nil,
        preferredItemEncoding: PhotosPickerItem.EncodingDisambiguationPolicy = .automatic,
        photoLibrary: PHPhotoLibrary
    ) -> Self {
        _ = isPresented
        _ = selection
        _ = photoLibrary
        var copy = self
        copy.maxSelectionCount = maxSelectionCount
        copy.selectionBehavior = selectionBehavior
        copy.filter = filter
        copy.preferredItemEncoding = preferredItemEncoding
        copy.usesPhotoLibrary = true
        copy.allowsMultipleSelection = true
        copy.presentsUsingModifier = true
        return copy
    }

    public func photosPicker(
        isPresented: Binding<Bool>,
        selection: Binding<[PhotosPickerItem]>,
        maxSelectionCount: Int? = nil,
        selectionBehavior: PhotosPickerSelectionBehavior = .default,
        matching filter: PHPickerFilter? = nil,
        preferredItemEncoding: PhotosPickerItem.EncodingDisambiguationPolicy = .automatic
    ) -> Self {
        _ = isPresented
        _ = selection
        var copy = self
        copy.maxSelectionCount = maxSelectionCount
        copy.selectionBehavior = selectionBehavior
        copy.filter = filter
        copy.preferredItemEncoding = preferredItemEncoding
        copy.usesPhotoLibrary = false
        copy.allowsMultipleSelection = true
        copy.presentsUsingModifier = true
        return copy
    }
}

extension View {
    public func photosPicker(
        isPresented: Binding<Bool>,
        selection: Binding<PhotosPickerItem?>,
        matching filter: PHPickerFilter? = nil,
        preferredItemEncoding: PhotosPickerItem.EncodingDisambiguationPolicy = .automatic,
        photoLibrary: PHPhotoLibrary
    ) -> Self {
        _ = isPresented
        _ = selection
        _ = filter
        _ = preferredItemEncoding
        _ = photoLibrary
        return self
    }

    public func photosPicker(
        isPresented: Binding<Bool>,
        selection: Binding<PhotosPickerItem?>,
        matching filter: PHPickerFilter? = nil,
        preferredItemEncoding: PhotosPickerItem.EncodingDisambiguationPolicy = .automatic
    ) -> Self {
        _ = isPresented
        _ = selection
        _ = filter
        _ = preferredItemEncoding
        return self
    }

    public func photosPicker(
        isPresented: Binding<Bool>,
        selection: Binding<[PhotosPickerItem]>,
        maxSelectionCount: Int? = nil,
        selectionBehavior: PhotosPickerSelectionBehavior = .default,
        matching filter: PHPickerFilter? = nil,
        preferredItemEncoding: PhotosPickerItem.EncodingDisambiguationPolicy = .automatic,
        photoLibrary: PHPhotoLibrary
    ) -> Self {
        _ = isPresented
        _ = selection
        _ = maxSelectionCount
        _ = selectionBehavior
        _ = filter
        _ = preferredItemEncoding
        _ = photoLibrary
        return self
    }

    public func photosPicker(
        isPresented: Binding<Bool>,
        selection: Binding<[PhotosPickerItem]>,
        maxSelectionCount: Int? = nil,
        selectionBehavior: PhotosPickerSelectionBehavior = .default,
        matching filter: PHPickerFilter? = nil,
        preferredItemEncoding: PhotosPickerItem.EncodingDisambiguationPolicy = .automatic
    ) -> Self {
        _ = isPresented
        _ = selection
        _ = maxSelectionCount
        _ = selectionBehavior
        _ = filter
        _ = preferredItemEncoding
        return self
    }

    public func photosPickerStyle(_ style: PhotosPickerStyle) -> Self {
        _ = style
        return self
    }

    public func photosPickerAccessoryVisibility(
        _ visibility: Visibility,
        edges: Edge.Set = .all
    ) -> Self {
        _ = visibility
        _ = edges
        return self
    }

    public func photosPickerDisabledCapabilities(
        _ disabledCapabilities: PHPickerCapabilities
    ) -> Self {
        _ = disabledCapabilities
        return self
    }

    public func postToPhotosSharedAlbumSheet(
        isPresented: Binding<Bool>,
        items: [PHPickerResult],
        photoLibrary: PHPhotoLibrary,
        defaultAlbumIdentifier: String? = nil,
        completion: ((Result<Void, any Error>) -> Void)? = nil
    ) -> Self {
        _ = photoLibrary
        _ = defaultAlbumIdentifier
        _ = items
        if isPresented.wrappedValue {
            isPresented.wrappedValue = false
            completion?(.failure(PhotosUIUnavailable.linuxHost(operation: "postToPhotosSharedAlbumSheet")))
        }
        return self
    }

    public func postToPhotosSharedAlbumSheet(
        isPresented: Binding<Bool>,
        items: [PhotosPickerItem],
        photoLibrary: PHPhotoLibrary,
        defaultAlbumIdentifier: String? = nil,
        completion: ((Result<Void, any Error>) -> Void)? = nil
    ) -> Self {
        _ = photoLibrary
        _ = defaultAlbumIdentifier
        _ = items
        if isPresented.wrappedValue {
            isPresented.wrappedValue = false
            completion?(.failure(PhotosUIUnavailable.linuxHost(operation: "postToPhotosSharedAlbumSheet")))
        }
        return self
    }
}
