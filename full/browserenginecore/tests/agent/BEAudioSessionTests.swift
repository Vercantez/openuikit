@_spi(OpenUIKitHost) import BrowserEngineCore
import Foundation

func testBEAudioSessionIsNSObjectSubclass() {
    let session = AVAudioSession()
    let wrapper = BEAudioSession(audioSession: session)
    let asObject: NSObject = wrapper
    precondition(asObject === wrapper)
    let same = wrapper
    precondition(wrapper == same)
    let other = BEAudioSession(audioSession: session)
    precondition(wrapper !== other)
    precondition(wrapper != other)
}

func testBEAudioSessionInitRetainsSession() {
    let session = AVAudioSession()
    let wrapper = BEAudioSession(audioSession: session)
    let retained = BrowserEngineCoreHostControl.wrappedAudioSession(of: wrapper)
    precondition(retained === session)
    precondition(wrapper.preferredOutput == nil)
    precondition(wrapper.availableOutputs.isEmpty)
}

func testBEAudioSessionSetPreferredOutputFailsClosed() {
    let session = AVAudioSession()
    let wrapper = BEAudioSession(audioSession: session)
    let port = AVAudioSessionPortDescription()
    do {
        try wrapper.setPreferredOutput(port)
        preconditionFailure("Linux must not invent AVAudioSession routing")
    } catch let error as NSError {
        precondition(error.domain == "BrowserEngineCore.linux.unavailable")
        precondition(error.code == 1)
        let description = error.userInfo[NSLocalizedDescriptionKey] as? String
        precondition(description?.contains("BEAudioSession.setPreferredOutput") == true)
    } catch {
        preconditionFailure("unexpected error type \(error)")
    }
    precondition(wrapper.preferredOutput == nil)
}

func testBEAudioSessionAvailableOutputsEmpty() {
    let wrapper = BEAudioSession(audioSession: AVAudioSession())
    let outputs: [AVAudioSessionPortDescription] = wrapper.availableOutputs
    precondition(outputs.isEmpty)
    precondition(outputs.count == 0)
    let again = wrapper.availableOutputs
    precondition(again.isEmpty)
    precondition(again == outputs)
}

func testBEAudioSessionPreferredOutputStartsNil() {
    let wrapper = BEAudioSession(audioSession: AVAudioSession())
    let preferred: AVAudioSessionPortDescription? = wrapper.preferredOutput
    precondition(preferred == nil)
}

func testObjCBEAudioSessionOpenClassIdentity() {
    let wrapper = BEAudioSession(audioSession: AVAudioSession())
    precondition(type(of: wrapper) == BEAudioSession.self)
    let asObject: NSObject = wrapper
    precondition(asObject is BEAudioSession)
    precondition((wrapper as NSObject).isEqual(wrapper))
}

func testObjCBEAudioSessionInitDistinctInstances() {
    let session = AVAudioSession()
    let first = BEAudioSession(audioSession: session)
    let second = BEAudioSession(audioSession: session)
    precondition(first !== second)
    precondition(
        BrowserEngineCoreHostControl.wrappedAudioSession(of: first) === session
    )
    precondition(
        BrowserEngineCoreHostControl.wrappedAudioSession(of: second) === session
    )
    precondition(
        BrowserEngineCoreHostControl.wrappedAudioSession(of: first)
            === BrowserEngineCoreHostControl.wrappedAudioSession(of: second)
    )
}

func testObjCSetPreferredOutputNilStillFailsClosed() {
    let wrapper = BEAudioSession(audioSession: AVAudioSession())
    do {
        try wrapper.setPreferredOutput(nil)
        preconditionFailure("nil must not invent Darwin clear-preference success")
    } catch let error as NSError {
        precondition(error.domain == BrowserEngineCoreHostControl.linuxUnavailableDomain)
        precondition(error.code == BrowserEngineCoreHostControl.linuxUnavailableCode)
    } catch {
        preconditionFailure("unexpected error type \(error)")
    }
    precondition(wrapper.preferredOutput == nil)
}

func testObjCAvailableOutputsIsEmptyArrayNotNil() {
    let wrapper = BEAudioSession(audioSession: AVAudioSession())
    let outputs = wrapper.availableOutputs
    precondition(outputs.isEmpty)
    let boxed: [AVAudioSessionPortDescription]? = Optional(outputs)
    precondition(boxed != nil)
    precondition(boxed?.isEmpty == true)
}

func testObjCPreferredOutputRemainsNilAcrossInstances() {
    let session = AVAudioSession()
    let first = BEAudioSession(audioSession: session)
    let second = BEAudioSession(audioSession: session)
    precondition(first.preferredOutput == nil)
    precondition(second.preferredOutput == nil)
    do {
        try first.setPreferredOutput(AVAudioSessionPortDescription())
        preconditionFailure("must stay fail-closed")
    } catch {
        precondition(first.preferredOutput == nil)
        precondition(second.preferredOutput == nil)
    }
}
