@_exported import CoreTransferable
@_exported import PhotosUI
import Foundation
import Photos
import SwiftUI
import UniformTypeIdentifiers

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
    public struct EncodingDisambiguationPolicy:
        Equatable, Hashable, Sendable
    {
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

    public func loadTransferable<T: Transferable>(
        type: T.Type
    ) async throws -> T? {
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
    public static let continuousAndOrdered =
        PhotosPickerSelectionBehavior(rawValue: 3)
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

@MainActor
private struct _PortableMultiplePhotosPickerModifier: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var selection: [PhotosPickerItem]
    let maxSelectionCount: Int?
    let filter: PHPickerFilter?

    func body(content: Content) -> some View {
        content
            .onAppear { synchronize(isPresented) }
            .onChange(of: isPresented) { _, value in synchronize(value) }
    }

    private func synchronize(_ presented: Bool) {
        guard presented else {
            PhotosUIPortable._dismissPresentation()
            return
        }
        guard PhotosUIPortable._requestPresentation(
            maxSelectionCount: maxSelectionCount,
            filter: filter,
            selection: { selection = $0 },
            dismissal: { isPresented = false }
        ) else {
            isPresented = false
            return
        }
    }
}

@MainActor
private struct _PortableSinglePhotosPickerModifier: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var selection: PhotosPickerItem?
    let filter: PHPickerFilter?

    func body(content: Content) -> some View {
        content
            .onAppear { synchronize(isPresented) }
            .onChange(of: isPresented) { _, value in synchronize(value) }
    }

    private func synchronize(_ presented: Bool) {
        guard presented else {
            PhotosUIPortable._dismissPresentation()
            return
        }
        guard PhotosUIPortable._requestPresentation(
            maxSelectionCount: 1,
            filter: filter,
            selection: { selection = $0.first },
            dismissal: { isPresented = false }
        ) else {
            isPresented = false
            return
        }
    }
}

public extension View {
    func photosPicker(
        isPresented: Binding<Bool>,
        selection: Binding<PhotosPickerItem?>,
        matching filter: PHPickerFilter? = nil,
        preferredItemEncoding: PhotosPickerItem.EncodingDisambiguationPolicy =
            .automatic
    ) -> some View {
        _ = preferredItemEncoding
        return modifier(
            _PortableSinglePhotosPickerModifier(
                isPresented: isPresented,
                selection: selection,
                filter: filter
            )
        )
    }

    func photosPicker(
        isPresented: Binding<Bool>,
        selection: Binding<[PhotosPickerItem]>,
        maxSelectionCount: Int? = nil,
        selectionBehavior: PhotosPickerSelectionBehavior = .default,
        matching filter: PHPickerFilter? = nil,
        preferredItemEncoding: PhotosPickerItem.EncodingDisambiguationPolicy =
            .automatic
    ) -> some View {
        _ = selectionBehavior
        _ = preferredItemEncoding
        return modifier(
            _PortableMultiplePhotosPickerModifier(
                isPresented: isPresented,
                selection: selection,
                maxSelectionCount: maxSelectionCount,
                filter: filter
            )
        )
    }
}
