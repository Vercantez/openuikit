import Foundation

open class CXProviderConfiguration: NSObject, NSCopying, @unchecked Sendable {
    public let localizedName: String?
    public var ringtoneSound: String?
    public var iconTemplateImageData: Data?
    public var maximumCallGroups: Int
    public var maximumCallsPerCallGroup: Int
    public var supportsVideo: Bool
    public var includesCallsInRecents: Bool
    public var supportsAudioTranslation: Bool
    public var supportedHandleTypes: Set<CXHandle.HandleType>

    public override init() {
        self.localizedName = nil
        self.ringtoneSound = nil
        self.iconTemplateImageData = nil
        self.maximumCallGroups = 2
        self.maximumCallsPerCallGroup = 5
        self.supportsVideo = false
        self.includesCallsInRecents = true
        self.supportsAudioTranslation = false
        self.supportedHandleTypes = []
        super.init()
    }

    public convenience init(localizedName: String) {
        self.init(portableLocalizedName: localizedName)
    }

    private init(portableLocalizedName: String?) {
        self.localizedName = portableLocalizedName
        self.ringtoneSound = nil
        self.iconTemplateImageData = nil
        self.maximumCallGroups = 2
        self.maximumCallsPerCallGroup = 5
        self.supportsVideo = false
        self.includesCallsInRecents = true
        self.supportsAudioTranslation = false
        self.supportedHandleTypes = []
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = CXProviderConfiguration(portableLocalizedName: localizedName)
        copy.ringtoneSound = ringtoneSound
        copy.iconTemplateImageData = iconTemplateImageData
        copy.maximumCallGroups = maximumCallGroups
        copy.maximumCallsPerCallGroup = maximumCallsPerCallGroup
        copy.supportsVideo = supportsVideo
        copy.includesCallsInRecents = includesCallsInRecents
        copy.supportsAudioTranslation = supportsAudioTranslation
        copy.supportedHandleTypes = supportedHandleTypes
        return copy
    }
}
