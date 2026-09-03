// Generated Intents global constants.

public let INAnswerCallIntentIdentifier: String = "INAnswerCallIntentIdentifier"
public let INCancelWorkoutIntentIdentifier: String = "INCancelWorkoutIntentIdentifier"
public let INEndWorkoutIntentIdentifier: String = "INEndWorkoutIntentIdentifier"
public let INGetRideStatusIntentIdentifier: String = "INGetRideStatusIntentIdentifier"
public let INHangUpCallIntentIdentifier: String = "INHangUpCallIntentIdentifier"
public let INIntentErrorDomain: String = "INIntentErrorDomain"
public let INListRideOptionsIntentIdentifier: String = "INListRideOptionsIntentIdentifier"
public let INPauseWorkoutIntentIdentifier: String = "INPauseWorkoutIntentIdentifier"
public let INRequestPaymentIntentIdentifier: String = "INRequestPaymentIntentIdentifier"
public let INRequestRideIntentIdentifier: String = "INRequestRideIntentIdentifier"
public let INResumeWorkoutIntentIdentifier: String = "INResumeWorkoutIntentIdentifier"
public let INSaveProfileInCarIntentIdentifier: String = "INSaveProfileInCarIntentIdentifier"
public let INSearchCallHistoryIntentIdentifier: String = "INSearchCallHistoryIntentIdentifier"
public let INSearchForMessagesIntentIdentifier: String = "INSearchForMessagesIntentIdentifier"
public let INSearchForPhotosIntentIdentifier: String = "INSearchForPhotosIntentIdentifier"
public let INSendMessageIntentIdentifier: String = "INSendMessageIntentIdentifier"
public let INSendPaymentIntentIdentifier: String = "INSendPaymentIntentIdentifier"
public let INSetAudioSourceInCarIntentIdentifier: String = "INSetAudioSourceInCarIntentIdentifier"
public let INSetClimateSettingsInCarIntentIdentifier: String = "INSetClimateSettingsInCarIntentIdentifier"
public let INSetDefrosterSettingsInCarIntentIdentifier: String = "INSetDefrosterSettingsInCarIntentIdentifier"
public let INSetMessageAttributeIntentIdentifier: String = "INSetMessageAttributeIntentIdentifier"
public let INSetProfileInCarIntentIdentifier: String = "INSetProfileInCarIntentIdentifier"
public let INSetRadioStationIntentIdentifier: String = "INSetRadioStationIntentIdentifier"
public let INSetSeatSettingsInCarIntentIdentifier: String = "INSetSeatSettingsInCarIntentIdentifier"
public let INStartAudioCallIntentIdentifier: String = "INStartAudioCallIntentIdentifier"
public let INStartCallIntentIdentifier: String = "INStartCallIntentIdentifier"
public let INStartPhotoPlaybackIntentIdentifier: String = "INStartPhotoPlaybackIntentIdentifier"
public let INStartVideoCallIntentIdentifier: String = "INStartVideoCallIntentIdentifier"
public let INStartWorkoutIntentIdentifier: String = "INStartWorkoutIntentIdentifier"

extension NSString {
    public class func deferredLocalizedIntentsString(with format: String, _ args: any CVarArg...) -> NSString {
        NSString(string: String(format: format, arguments: args))
    }

    public class func deferredLocalizedIntentsString(with format: String, table: String, _ args: any CVarArg...) -> NSString {
        _ = table
        return NSString(string: String(format: format, arguments: args))
    }

    public class func deferredLocalizedIntentsString(with format: String, table: String, arguments: CVaListPointer) -> NSString {
        _ = table
        _ = arguments
        return NSString(string: format)
    }
}
