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

    let state = SpeechLockedState()
    let finished = DispatchSemaphore(value: 0)
    SFSpeechRecognizer.requestAuthorization { status in
        state.noteCallback(status, onMain: Thread.isMainThread)
        finished.signal()
    }
    state.markReturned()
    precondition(state.snapshot().count == 0, "authorization callback ran inline")
    speechWait(finished, "authorization callback did not run")
    let end = state.snapshot()
    precondition(end.count == 1)
    precondition(end.sawReturned)
    precondition(end.status == .denied)
    precondition(end.onMain)
    precondition(SFSpeechRecognizer.authorizationStatus() == .denied)

    let second = DispatchSemaphore(value: 0)
    var secondStatus: SFSpeechRecognizerAuthorizationStatus?
    SFSpeechRecognizer.requestAuthorization { status in
        secondStatus = status
        second.signal()
    }
    speechWait(second, "second authorization did not run")
    precondition(secondStatus == .denied)

    SpeechHostControl.resetAuthorizationStatusForTests()
    SpeechHostControl.installAuthorizationDecision(.authorized)
    let granted = DispatchSemaphore(value: 0)
    SFSpeechRecognizer.requestAuthorization { status in
        precondition(status == .authorized)
        granted.signal()
    }
    speechWait(granted, "authorized decision did not run")
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
    speechWait(availability.changed, "availability did not change")
    precondition(availability.snapshot() == true)
    precondition(recognizer.isAvailable)
    precondition(recognizer.delegate === availability)
}
