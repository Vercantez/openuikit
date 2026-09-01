import Foundation

#if canImport(UIKit)
import UIKit
#endif

@MainActor
open class CPNowPlayingButton: NSObject {
    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public var isEnabled: Bool
    public var isSelected: Bool
    public let handler: ((CPNowPlayingButton) -> Void)?

    public init(handler: ((CPNowPlayingButton) -> Void)? = nil) {
        self.isEnabled = true
        self.isSelected = false
        self.handler = handler
        super.init()
    }

    @_spi(OpenUIKitHost)
    public func invokeHandler() {
        handler?(self)
    }
}

#if canImport(UIKit)
@MainActor
open class CPNowPlayingImageButton: CPNowPlayingButton {
    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public let image: UIImage?

    public init(image: UIImage, handler: ((CPNowPlayingButton) -> Void)? = nil) {
        self.image = image
        super.init(handler: handler)
    }
}
#endif

@MainActor
open class CPNowPlayingAddToLibraryButton: CPNowPlayingButton {
    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public override init(handler: ((CPNowPlayingButton) -> Void)? = nil) {
        super.init(handler: handler)
    }
}

@MainActor
open class CPNowPlayingMoreButton: CPNowPlayingButton {
    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public override init(handler: ((CPNowPlayingButton) -> Void)? = nil) {
        super.init(handler: handler)
    }
}

@MainActor
open class CPNowPlayingPlaybackRateButton: CPNowPlayingButton {
    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public override init(handler: ((CPNowPlayingButton) -> Void)? = nil) {
        super.init(handler: handler)
    }
}

@MainActor
open class CPNowPlayingRepeatButton: CPNowPlayingButton {
    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public override init(handler: ((CPNowPlayingButton) -> Void)? = nil) {
        super.init(handler: handler)
    }
}

@MainActor
open class CPNowPlayingShuffleButton: CPNowPlayingButton {
    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public override init(handler: ((CPNowPlayingButton) -> Void)? = nil) {
        super.init(handler: handler)
    }
}

@MainActor
open class CPNowPlayingMode: NSObject {
    public override init() {
        super.init()
    }

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    @MainActor
    public class var `default`: CPNowPlayingMode {
        CPNowPlayingMode.defaultMode
    }

    private static let defaultMode = CPNowPlayingMode()
}

@MainActor
open class CPNowPlayingSportsClock: NSObject {
    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public let countsUp: Bool
    public let isPaused: Bool
    public let timeValue: TimeInterval

    public init(elapsedTime: TimeInterval, paused: Bool) {
        self.countsUp = true
        self.isPaused = paused
        self.timeValue = elapsedTime
        super.init()
    }

    public init(timeRemaining: TimeInterval, paused: Bool) {
        self.countsUp = false
        self.isPaused = paused
        self.timeValue = timeRemaining
        super.init()
    }
}

@MainActor
open class CPNowPlayingSportsTeamLogo: NSObject {
    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public let initials: String?

    #if canImport(UIKit)
    public let logo: UIImage?
    #endif

    public init(teamInitials: String) {
        self.initials = teamInitials
        #if canImport(UIKit)
        self.logo = nil
        #endif
        super.init()
    }

    #if canImport(UIKit)
    public init(teamLogo: UIImage) {
        self.initials = nil
        self.logo = teamLogo
        super.init()
    }
    #endif
}

@MainActor
open class CPNowPlayingSportsTeam: NSObject {
    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public let name: String
    public let logo: CPNowPlayingSportsTeamLogo
    public let teamStandings: String?
    public let eventScore: String
    public let isFavorite: Bool

    #if canImport(UIKit)
    public let possessionIndicator: UIImage?

    public init(
        name: String,
        logo: CPNowPlayingSportsTeamLogo,
        teamStandings: String?,
        eventScore: String,
        possessionIndicator: UIImage?,
        favorite: Bool
    ) {
        self.name = name
        self.logo = logo
        self.teamStandings = teamStandings
        self.eventScore = eventScore
        self.isFavorite = favorite
        self.possessionIndicator = possessionIndicator
        super.init()
    }
    #else
    @_spi(OpenUIKitHost)
    public init(
        name: String,
        logo: CPNowPlayingSportsTeamLogo,
        teamStandings: String?,
        eventScore: String,
        favorite: Bool
    ) {
        self.name = name
        self.logo = logo
        self.teamStandings = teamStandings
        self.eventScore = eventScore
        self.isFavorite = favorite
        super.init()
    }
    #endif
}

@MainActor
open class CPNowPlayingSportsEventStatus: NSObject {
    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public let eventStatusText: [String]?
    public let eventClock: CPNowPlayingSportsClock?

    #if canImport(UIKit)
    public let eventStatusImage: UIImage?

    public init(
        eventStatusText: [String]?,
        eventStatusImage: UIImage?,
        eventClock: CPNowPlayingSportsClock?
    ) {
        self.eventStatusText = eventStatusText
        self.eventClock = eventClock
        self.eventStatusImage = eventStatusImage
        super.init()
    }
    #else
    @_spi(OpenUIKitHost)
    public init(
        eventStatusText: [String]?,
        eventClock: CPNowPlayingSportsClock?
    ) {
        self.eventStatusText = eventStatusText
        self.eventClock = eventClock
        super.init()
    }
    #endif
}

@MainActor
open class CPNowPlayingModeSports: CPNowPlayingMode {
    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public let leftTeam: CPNowPlayingSportsTeam
    public let rightTeam: CPNowPlayingSportsTeam
    public let eventStatus: CPNowPlayingSportsEventStatus?

    #if canImport(UIKit)
    public let backgroundArtwork: UIImage?

    public init(
        leftTeam: CPNowPlayingSportsTeam,
        rightTeam: CPNowPlayingSportsTeam,
        eventStatus: CPNowPlayingSportsEventStatus?,
        backgroundArtwork: UIImage?
    ) {
        self.leftTeam = leftTeam
        self.rightTeam = rightTeam
        self.eventStatus = eventStatus
        self.backgroundArtwork = backgroundArtwork
        super.init()
    }
    #else
    @_spi(OpenUIKitHost)
    public init(
        leftTeam: CPNowPlayingSportsTeam,
        rightTeam: CPNowPlayingSportsTeam,
        eventStatus: CPNowPlayingSportsEventStatus?
    ) {
        self.leftTeam = leftTeam
        self.rightTeam = rightTeam
        self.eventStatus = eventStatus
        super.init()
    }
    #endif
}

@MainActor
open class CPNowPlayingTemplate: CPTemplate {
    @MainActor
    public class var shared: CPNowPlayingTemplate {
        CPNowPlayingTemplate.sharedInstance
    }

    private static let sharedInstance = CPNowPlayingTemplate()

    public private(set) var nowPlayingButtons: [CPNowPlayingButton] = []
    public var nowPlayingMode: CPNowPlayingMode?
    public var isAlbumArtistButtonEnabled = false
    public var isUpNextButtonEnabled = false
    public var upNextTitle = ""
    private var observers: [ObjectIdentifier: WeakNowPlayingObserver] = [:]

    public func updateNowPlayingButtons(_ nowPlayingButtons: [CPNowPlayingButton]) {
        self.nowPlayingButtons = nowPlayingButtons
    }

    public func add(_ observer: any CPNowPlayingTemplateObserver) {
        let object = observer as AnyObject
        observers[ObjectIdentifier(object)] = WeakNowPlayingObserver(value: object)
    }

    public func remove(_ observer: any CPNowPlayingTemplateObserver) {
        observers.removeValue(forKey: ObjectIdentifier(observer as AnyObject))
    }

    @_spi(OpenUIKitHost)
    public func notifyUpNextTapped() {
        forEachObserver { $0.nowPlayingTemplateUpNextButtonTapped(self) }
    }

    @_spi(OpenUIKitHost)
    public func notifyAlbumArtistTapped() {
        forEachObserver { $0.nowPlayingTemplateAlbumArtistButtonTapped(self) }
    }

    private func forEachObserver(_ body: (any CPNowPlayingTemplateObserver) -> Void) {
        for (identifier, box) in observers {
            if let observer = box.value as? any CPNowPlayingTemplateObserver {
                body(observer)
            } else {
                observers.removeValue(forKey: identifier)
            }
        }
    }
}

@MainActor
private final class WeakNowPlayingObserver {
    weak var value: AnyObject?

    init(value: AnyObject) {
        self.value = value
    }
}
