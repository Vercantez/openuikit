@_spi(OpenUIKitHost) import Speech
import Foundation

func testSupportedLocales() {
    let locales = SFSpeechRecognizer.supportedLocales()
    precondition(locales.isEmpty == false)
    precondition(locales.contains(Locale(identifier: "en-US")))
    precondition(locales.contains(Locale(identifier: "ja-JP")))
    precondition(locales.contains(Locale(identifier: "zh-CN")))
}

func testSpeechRecognizerInit() {
    SpeechHostControl.resetScriptedRecognizers()
    let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    precondition(recognizer != nil)
    let unwrapped = recognizer!
    let asObject: NSObject = unwrapped
    precondition(asObject === unwrapped)
    precondition(unwrapped.locale.identifier == "en-US")
    precondition(unwrapped.supportsOnDeviceRecognition == false)
    unwrapped.defaultTaskHint = .dictation
    precondition(unwrapped.defaultTaskHint == .dictation)
    unwrapped.supportsOnDeviceRecognition = true
    precondition(unwrapped.supportsOnDeviceRecognition)
    unwrapped.queue.isSuspended = false
    precondition(unwrapped.queue.isSuspended == false)
    let defaultRecognizer = SFSpeechRecognizer()
    precondition(defaultRecognizer.locale.identifier.isEmpty == false)
    precondition(SFSpeechRecognizer(locale: Locale(identifier: "zz-ZZ")) == nil)
    precondition(SFSpeechRecognizer(locale: Locale(identifier: "fr_FR")) != nil)
}

func testSpeechRecognizerAuthorization() {
    SpeechHostControl.resetAuthorizationStatusForTests()
    precondition(SFSpeechRecognizer.authorizationStatus() == .notDetermined)

    var first: SFSpeechRecognizerAuthorizationStatus?
    SFSpeechRecognizer.requestAuthorization { status in
        first = status
    }
    precondition(first == .denied)
    precondition(SFSpeechRecognizer.authorizationStatus() == .denied)

    var second: SFSpeechRecognizerAuthorizationStatus?
    SFSpeechRecognizer.requestAuthorization { status in
        second = status
    }
    precondition(second == .denied)

    SpeechHostControl.resetAuthorizationStatusForTests()
    SpeechHostControl.installAuthorizationDecision(.authorized)
    var granted: SFSpeechRecognizerAuthorizationStatus?
    SFSpeechRecognizer.requestAuthorization { status in
        granted = status
    }
    precondition(granted == .authorized)
    precondition(SFSpeechRecognizer.authorizationStatus() == .authorized)
}

func testSpeechRecognizerAvailability() {
    SpeechHostControl.resetScriptedRecognizers()
    let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    precondition(recognizer.isAvailable == false)
    let availability = SpeechAvailabilityDelegate()
    recognizer.delegate = availability
    speechRegisterEnglishScript(
        results: [SpeechScriptedResult(formattedString: "hello", isFinal: true)]
    )
    precondition(availability.snapshot() == true)
    precondition(recognizer.isAvailable)
    precondition(recognizer.delegate === availability)
}
