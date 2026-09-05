import Foundation

// Isolated host compile has Foundation only. Types owned by AVFoundation,
// AVFAudio, UIKit, and CoreMedia are module-local lookalikes so AVKit's
// public surface can compile. They are not substitutes for listed
// dependencies (this seed lists Foundation only). Real modules are imported
// by tests/agent/AVKitDependencyIdentity.swift for later EC2 integration.

#if !canImport(AVFoundation)

open class AVPlayer: NSObject {
    public var rate: Float = 0
    /// Isolated-host stand-in for AVFoundation.AVPlayer.defaultRate.
    /// Apple iPhone 16 / iOS 26.1 default is 1.0 (OpenUIKit-Chrome-fw-avkit).
    public var defaultRate: Float = 1
    public var currentItem: AVPlayerItem?

    public override init() {
        super.init()
    }

    public convenience init(url: URL) {
        self.init()
        self.currentItem = AVPlayerItem(url: url)
    }

    public convenience init(playerItem item: AVPlayerItem?) {
        self.init()
        self.currentItem = item
    }
}

open class AVPlayerItem: NSObject {
    public var url: URL?
    @MainActor public var externalMetadata: [AVMetadataItem] = []
    @MainActor public var interstitialTimeRanges: [AVInterstitialTimeRange] = []

    public override init() {
        super.init()
    }

    public init(url: URL) {
        self.url = url
        super.init()
    }
}

open class AVPlayerLayer: NSObject {
    public var player: AVPlayer?
    public var videoGravity: AVLayerVideoGravity = .resizeAspect

    public override init() {
        super.init()
    }
}

open class AVMetadataItem: NSObject {
    public override init() {
        super.init()
    }
}

public struct AVMediaCharacteristic: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public struct AVLayerVideoGravity: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let resizeAspect = AVLayerVideoGravity(rawValue: "AVLayerVideoGravityResizeAspect")
    public static let resizeAspectFill = AVLayerVideoGravity(rawValue: "AVLayerVideoGravityResizeAspectFill")
    public static let resize = AVLayerVideoGravity(rawValue: "AVLayerVideoGravityResize")
}

open class AVSampleBufferDisplayLayer: NSObject {
    public override init() {
        super.init()
    }
}

#endif

#if !canImport(AVFAudio)

open class AVAudioSession: NSObject {
    public static let sharedInstance = AVAudioSession()

    public override init() {
        super.init()
    }
}

#endif

#if !canImport(AVRouting)

open class AVCustomRoutingController: NSObject {
    public override init() {
        super.init()
    }
}

#endif

#if !canImport(CoreMedia)

public struct CMTime: Hashable, Sendable {
    public var value: Int64
    public var timescale: Int32

    public init(value: Int64, timescale: Int32) {
        self.value = value
        self.timescale = timescale
    }

    public static let zero = CMTime(value: 0, timescale: 1)
}

public struct CMTimeRange: Hashable, Sendable {
    public var start: CMTime
    public var duration: CMTime

    public init(start: CMTime, duration: CMTime) {
        self.start = start
        self.duration = duration
    }

    public static let zero = CMTimeRange(start: .zero, duration: .zero)
}

public struct CMVideoDimensions: Hashable, Sendable {
    public var width: Int32
    public var height: Int32

    public init(width: Int32, height: Int32) {
        self.width = width
        self.height = height
    }
}

#endif

#if !canImport(UIKit)

public enum NSTextAlignment: Int, Sendable {
    case left = 0
    case center = 1
    case right = 2
}

public struct UIColor: Hashable, Sendable {
    public var hostName: String

    public init(hostName: String) {
        self.hostName = hostName
    }

    public static let black = UIColor(hostName: "black")
    public static let white = UIColor(hostName: "white")
    public static let clear = UIColor(hostName: "clear")
}

public struct UIFont: Hashable, Sendable {
    public var pointSize: CGFloat

    public init(pointSize: CGFloat) {
        self.pointSize = pointSize
    }

    public static func systemFont(ofSize size: CGFloat) -> UIFont {
        UIFont(pointSize: size)
    }
}

open class UIView: NSObject {
    open var frame: CGRect
    open var bounds: CGRect
    open var backgroundColor: UIColor?
    open var clipsToBounds = false
    open var accessibilityLabel: String?
    open var accessibilityIdentifier: String?

    public override init() {
        self.frame = .zero
        self.bounds = .zero
        super.init()
    }

    public init(frame: CGRect) {
        self.frame = frame
        self.bounds = CGRect(origin: .zero, size: frame.size)
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        self.frame = .zero
        self.bounds = .zero
        super.init()
    }

    open func addSubview(_ view: UIView) {
        _ = view
    }

    open func layoutSubviews() {}
}

open class UILabel: UIView {
    open var text: String?
    open var textAlignment: NSTextAlignment = .center
    open var numberOfLines: Int = 1
    open var textColor: UIColor?
    open var font: UIFont?
}

open class UIViewController: NSObject {
    open var view = UIView(frame: .zero)

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        super.init()
    }
}

open class UIImage: NSObject {
    public override init() {
        super.init()
    }
}

open class UIAction: NSObject {
    public override init() {
        super.init()
    }
}

open class UITraitCollection: NSObject {
    public override init() {
        super.init()
    }
}

public protocol UIViewControllerTransitionCoordinator: AnyObject {}

#if !canImport(SwiftUI)

public struct UIViewRepresentableContext<Representable> {
    public init() {}
}

public protocol UIViewRepresentable: View {
    associatedtype UIViewType: UIView
    typealias Context = UIViewRepresentableContext<Self>
    func makeUIView(context: Context) -> UIViewType
    func updateUIView(_ uiView: UIViewType, context: Context)
}

extension UIViewRepresentable {
    public var body: EmptyView {
        _ = makeUIView(context: Context())
        return EmptyView()
    }
}

#endif

#endif
