import Foundation
import MediaSetup

func testSetupSessionIsNSObjectSubclass() {
    let account = MSServiceAccount(serviceName: "Music", accountName: "pat")
    let session = MSSetupSession(serviceAccount: account)
    precondition(session is NSObject)
    let same = session
    precondition(session == same)
    let other = MSSetupSession(serviceAccount: account)
    precondition(session !== other)
    precondition(session != other)
}

func testSetupSessionInitRetainsAccount() {
    let account = MSServiceAccount(serviceName: "Podcasts", accountName: "kit")
    account.clientID = "abc"
    let session = MSSetupSession(serviceAccount: account)
    precondition(session.account === account)
    precondition(session.account.clientID == "abc")
    precondition(session.presentationContext == nil)
}

func testSetupSessionAccountIdentity() {
    let account = MSServiceAccount(serviceName: "Radio", accountName: "ada")
    let session = MSSetupSession(serviceAccount: account)
    let read: MSServiceAccount = session.account
    precondition(read === account)
    read.authorizationScope = "scope-a"
    precondition(session.account.authorizationScope == "scope-a")
}

func testSetupSessionPresentationContextWeak() {
    let account = MSServiceAccount(serviceName: "s", accountName: "a")
    let session = MSSetupSession(serviceAccount: account)
    precondition(session.presentationContext == nil)
    do {
        let context = MediaSetupTestPresentationContext()
        session.presentationContext = context
        precondition(session.presentationContext === context)
        session.presentationContext = nil
        precondition(session.presentationContext == nil)
        session.presentationContext = context
        precondition(session.presentationContext === context)
    }
    precondition(session.presentationContext == nil)
}

func testSetupSessionStartFailsClosed() {
    let account = MSServiceAccount(serviceName: "Music", accountName: "pat")
    let session = MSSetupSession(serviceAccount: account)
    do {
        try session.start()
        preconditionFailure("Linux must not invent a Media Setup success")
    } catch let error as NSError {
        precondition(error.domain == "MediaSetup.linux.unavailable")
        precondition(error.code == 1)
        let description = error.userInfo[NSLocalizedDescriptionKey] as? String
        precondition(description?.contains("MSSetupSession.start") == true)
    } catch {
        preconditionFailure("unexpected error type \(error)")
    }

    let context = MediaSetupTestPresentationContext(anchor: NSObject())
    session.presentationContext = context
    do {
        try session.start()
        preconditionFailure("a presentation context must not invent Darwin success")
    } catch let error as NSError {
        precondition(error.domain == "MediaSetup.linux.unavailable")
        precondition(error.code == 1)
    } catch {
        preconditionFailure("unexpected error type \(error)")
    }
}
