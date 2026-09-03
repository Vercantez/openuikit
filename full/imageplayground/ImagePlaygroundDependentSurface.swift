// Dependency-bearing ImagePlayground APIs. Each block is compiled only when
// the real module is importable. Isolated host has Foundation/Dispatch only.

#if canImport(CoreGraphics)
import CoreGraphics

extension ImagePlaygroundConcept {
    public static func image(_ image: CGImage) -> ImagePlaygroundConcept {
        ImagePlaygroundConcept(storage: .boxed(image))
    }
}

extension ImageCreator {
    public struct CreatedImage {
        public let cgImage: CGImage

        init(cgImage: CGImage) {
            self.cgImage = cgImage
        }
    }

    public func images(
        for concepts: [ImagePlaygroundConcept],
        style: ImagePlaygroundStyle,
        limit: Int
    ) -> some AsyncSequence<CreatedImage, any Swift.Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(throwing: Error.unavailable)
        }
    }
}
#endif

#if canImport(PencilKit)
import PencilKit

extension ImagePlaygroundConcept {
    public static func drawing(_ drawing: PKDrawing) -> ImagePlaygroundConcept {
        ImagePlaygroundConcept(storage: .boxed(drawing))
    }
}
#endif

#if canImport(UIKit)
import UIKit

@MainActor
@objc
open class ImagePlaygroundViewController: UIViewController {
    @objc public weak var delegate: Delegate?
    @objc public var sourceImage: UIImage?
    public var concepts: [ImagePlaygroundConcept] = []
    public var allowedGenerationStyles: [ImagePlaygroundStyle] = ImagePlaygroundStyle.all
    public var selectedGenerationStyle: ImagePlaygroundStyle = .illustration
    public var personalizationPolicy: ImagePlaygroundPersonalizationPolicy = .automatic

    private var storedPreferredContentSize = CGSize(width: 0, height: 0)

    public convenience init() {
        self.init(nibName: nil, bundle: nil)
    }

    @objc(available)
    open class var isAvailable: Bool { false }

    open override var isModalInPresentation: Bool {
        get { super.isModalInPresentation }
        set { super.isModalInPresentation = newValue }
    }

    open override var modalPresentationStyle: UIModalPresentationStyle {
        get { super.modalPresentationStyle }
        set { super.modalPresentationStyle = newValue }
    }

    open override var preferredContentSize: CGSize {
        get { storedPreferredContentSize }
        set { storedPreferredContentSize = newValue }
    }

    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        super.supportedInterfaceOrientations
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    @objc(ImageGenerationViewControllerDelegate)
    public protocol Delegate: NSObjectProtocol {
        @MainActor
        func imagePlaygroundViewController(
            _ imagePlaygroundViewController: ImagePlaygroundViewController,
            didCreateImageAt imageURL: URL
        )

        @MainActor
        @objc optional func imagePlaygroundViewControllerDidCancel(
            _ imagePlaygroundViewController: ImagePlaygroundViewController
        )
    }
}
#endif

#if canImport(SwiftUI)
import SwiftUI

extension EnvironmentValues {
    public var imagePlaygroundPersonalizationPolicy: ImagePlaygroundPersonalizationPolicy {
        .automatic
    }

    public var imagePlaygroundAllowedGenerationStyles: [ImagePlaygroundStyle] {
        ImagePlaygroundStyle.all
    }

    public var imagePlaygroundSelectedGenerationStyle: ImagePlaygroundStyle {
        .illustration
    }

    public var supportsImagePlayground: Bool { false }
}

extension View {
    @MainActor
    @preconcurrency
    public func imagePlaygroundSheet(
        isPresented: Binding<Bool>,
        concepts: [ImagePlaygroundConcept] = [],
        sourceImage: Image? = nil,
        onCompletion: @escaping (URL) -> Void,
        onCancellation: (() -> Void)? = nil
    ) -> some View {
        self
    }

    @MainActor
    @preconcurrency
    public func imagePlaygroundSheet(
        isPresented: Binding<Bool>,
        concepts: [ImagePlaygroundConcept] = [],
        sourceImageURL: URL,
        onCompletion: @escaping (URL) -> Void,
        onCancellation: (() -> Void)? = nil
    ) -> some View {
        self
    }

    @MainActor
    @preconcurrency
    public func imagePlaygroundSheet(
        isPresented: Binding<Bool>,
        concept: String,
        sourceImage: Image? = nil,
        onCompletion: @escaping (URL) -> Void,
        onCancellation: (() -> Void)? = nil
    ) -> some View {
        self
    }

    @MainActor
    @preconcurrency
    public func imagePlaygroundSheet(
        isPresented: Binding<Bool>,
        concept: String,
        sourceImageURL: URL,
        onCompletion: @escaping (URL) -> Void,
        onCancellation: (() -> Void)? = nil
    ) -> some View {
        self
    }

    nonisolated public func imagePlaygroundGenerationStyle(
        _ style: ImagePlaygroundStyle,
        in allowedStyles: [ImagePlaygroundStyle] = ImagePlaygroundStyle.all
    ) -> some View {
        self
    }

    nonisolated public func imagePlaygroundPersonalizationPolicy(
        _ policy: ImagePlaygroundPersonalizationPolicy = .automatic
    ) -> some View {
        self
    }
}
#endif
