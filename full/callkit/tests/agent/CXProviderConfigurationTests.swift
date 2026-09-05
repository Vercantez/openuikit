import CallKit
import Foundation

func testCXProviderConfigurationInitAndDefaults() {
    let unnamed = CXProviderConfiguration()
    precondition(unnamed.localizedName == nil)
    precondition(unnamed.maximumCallGroups == 2)
    precondition(unnamed.maximumCallsPerCallGroup == 5)
    precondition(!unnamed.supportsVideo)
    precondition(unnamed.includesCallsInRecents)
    precondition(!unnamed.supportsAudioTranslation)
    precondition(unnamed.supportedHandleTypes.isEmpty)
    precondition(unnamed.ringtoneSound == nil)
    precondition(unnamed.iconTemplateImageData == nil)
    precondition(type(of: unnamed) == CXProviderConfiguration.self)
}

func testCXProviderConfigurationLocalizedNameAndCopy() {
    let configuration = CXProviderConfiguration(localizedName: "OpenUIKit")
    configuration.supportsVideo = true
    configuration.supportedHandleTypes = [.phoneNumber, .generic]
    configuration.ringtoneSound = "tone.caf"
    configuration.includesCallsInRecents = false
    configuration.supportsAudioTranslation = true
    configuration.iconTemplateImageData = Data([0x01, 0x02])
    configuration.maximumCallGroups = 3
    configuration.maximumCallsPerCallGroup = 4
    let copy = configuration.copy() as! CXProviderConfiguration
    precondition(copy.localizedName == "OpenUIKit")
    precondition(copy.supportsVideo)
    precondition(copy.supportedHandleTypes.contains(.phoneNumber))
    precondition(copy.supportedHandleTypes.contains(.generic))
    precondition(copy.ringtoneSound == "tone.caf")
    precondition(!copy.includesCallsInRecents)
    precondition(copy.supportsAudioTranslation)
    precondition(copy.iconTemplateImageData == Data([0x01, 0x02]))
    precondition(copy.maximumCallGroups == 3)
    precondition(copy.maximumCallsPerCallGroup == 4)
}

func testCXProviderConfigurationSupportedHandleTypesMutation() {
    let configuration = CXProviderConfiguration()
    var types = configuration.supportedHandleTypes
    types.insert(.emailAddress)
    configuration.supportedHandleTypes = types
    precondition(configuration.supportedHandleTypes.contains(.emailAddress))
    types = configuration.supportedHandleTypes
    types.remove(.emailAddress)
    configuration.supportedHandleTypes = types
    precondition(!configuration.supportedHandleTypes.contains(.emailAddress))
}
