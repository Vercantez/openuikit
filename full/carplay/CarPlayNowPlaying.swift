import Foundation

@MainActor
open class CPNowPlayingButton: CarPlayCodingObject {

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
    public func portableInvoke() {
        handler?(self)
    }
}

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
open class CPNowPlayingMode: CarPlayCodingObject {
    @MainActor
    public class var `default`: CPNowPlayingMode {
        CPNowPlayingMode.defaultMode
    }

    private static let defaultMode = CPNowPlayingMode()

}

@MainActor
open class CPNowPlayingSportsClock: CarPlayCodingObject {

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
open class CPNowPlayingSportsTeamLogo: CarPlayCodingObject {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public let initials: String?
    public let logo: UIImage?

    public init(teamInitials: String) {
        self.initials = teamInitials
        self.logo = nil
        super.init()
    }

    public init(teamLogo: UIImage) {
        self.initials = nil
        self.logo = teamLogo
        super.init()
    }

}

@MainActor
open class CPNowPlayingSportsTeam: CarPlayCodingObject {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public let name: String
    public let logo: CPNowPlayingSportsTeamLogo
    public let teamStandings: String?
    public let eventScore: String
    public let possessionIndicator: UIImage?
    public let isFavorite: Bool

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
        self.possessionIndicator = possessionIndicator
        self.isFavorite = favorite
        super.init()
    }

}

@MainActor
open class CPNowPlayingSportsEventStatus: CarPlayCodingObject {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public let eventStatusText: [String]?
    public let eventStatusImage: UIImage?
    public let eventClock: CPNowPlayingSportsClock?

    public init(
        eventStatusText: [String]?,
        eventStatusImage: UIImage?,
        eventClock: CPNowPlayingSportsClock?
    ) {
        self.eventStatusText = eventStatusText
        self.eventStatusImage = eventStatusImage
        self.eventClock = eventClock
        super.init()
    }

}

@MainActor
open class CPNowPlayingModeSports: CPNowPlayingMode {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public let leftTeam: CPNowPlayingSportsTeam
    public let rightTeam: CPNowPlayingSportsTeam
    public let eventStatus: CPNowPlayingSportsEventStatus?
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
    private var observers: [ObjectIdentifier: any CPNowPlayingTemplateObserver] = [:]

    public func updateNowPlayingButtons(_ nowPlayingButtons: [CPNowPlayingButton]) {
        self.nowPlayingButtons = nowPlayingButtons
    }

    public func add(_ observer: any CPNowPlayingTemplateObserver) {
        observers[ObjectIdentifier(observer as AnyObject)] = observer
    }

    public func remove(_ observer: any CPNowPlayingTemplateObserver) {
        observers.removeValue(forKey: ObjectIdentifier(observer as AnyObject))
    }

    @_spi(OpenUIKitHost)
    public func portableNotifyUpNextTapped() {
        observers.values.forEach { $0.nowPlayingTemplateUpNextButtonTapped(self) }
    }

    @_spi(OpenUIKitHost)
    public func portableNotifyAlbumArtistTapped() {
        observers.values.forEach { $0.nowPlayingTemplateAlbumArtistButtonTapped(self) }
    }

}
