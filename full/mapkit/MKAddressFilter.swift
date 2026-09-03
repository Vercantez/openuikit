import Foundation

public final class MKAddressFilter: NSObject, NSCopying {
    private enum Mode {
        case includingAll
        case excludingAll
        case including(MKAddressFilter.Options)
        case excluding(MKAddressFilter.Options)
    }

    public struct Options: OptionSet, Hashable, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let country = Options(rawValue: 1 << 0)
        public static let administrativeArea = Options(rawValue: 1 << 1)
        public static let subAdministrativeArea = Options(rawValue: 1 << 2)
        public static let locality = Options(rawValue: 1 << 3)
        public static let subLocality = Options(rawValue: 1 << 4)
        public static let postalCode = Options(rawValue: 1 << 5)
    }

    private let mode: Mode

    public static var includingAll: MKAddressFilter {
        MKAddressFilter(mode: .includingAll)
    }

    public static var excludingAll: MKAddressFilter {
        MKAddressFilter(mode: .excludingAll)
    }

    public init(including options: Options) {
        mode = .including(options)
        super.init()
    }

    public init(includingOptions options: Options) {
        mode = .including(options)
        super.init()
    }

    public init(excluding options: Options) {
        mode = .excluding(options)
        super.init()
    }

    public init(excludingOptions options: Options) {
        mode = .excluding(options)
        super.init()
    }

    private init(mode: Mode) {
        self.mode = mode
        super.init()
    }

    public func includes(_ options: Options) -> Bool {
        switch mode {
        case .includingAll:
            return true
        case .excludingAll:
            return false
        case .including(let included):
            return included.contains(options)
        case .excluding(let excluded):
            return excluded.intersection(options).isEmpty
        }
    }

    public func excludes(_ options: Options) -> Bool {
        !includes(options)
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return MKAddressFilter(mode: mode)
    }
}
