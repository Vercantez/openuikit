import Foundation
@_spi(OpenUIKitHost) import MediaPlayer

final class MPNowPlayingSessionSink: NSObject, MPNowPlayingSessionDelegate {
    var active = 0
    var canBecome = 0

    func nowPlayingSessionDidChangeActive(_ nowPlayingSession: MPNowPlayingSession) {
        _ = nowPlayingSession
        active += 1
    }

    func nowPlayingSessionDidChangeCanBecomeActive(_ nowPlayingSession: MPNowPlayingSession) {
        _ = nowPlayingSession
        canBecome += 1
    }
}

func testNowPlayingSessionFailClosed() {
    let session = MPNowPlayingSession()
    precondition(!session.canBecomeActive)
    precondition(!session.isActive)
    _ = session.nowPlayingInfoCenter
    _ = session.remoteCommandCenter
    session.automaticallyPublishesNowPlayingInfo = true
    let sink = MPNowPlayingSessionSink()
    session.delegate = sink
    let asDel: any MPNowPlayingSessionDelegate = sink
    asDel.nowPlayingSessionDidChangeActive(session)
    asDel.nowPlayingSessionDidChangeCanBecomeActive(session)
    precondition(sink.active == 1 && sink.canBecome == 1)
    let sem = DispatchSemaphore(value: 0)
    var became = true
    var returned = false
    session.becomeActiveIfPossible { ok in
        precondition(returned)
        became = ok
        sem.signal()
    }
    returned = true
    precondition(sem.wait(timeout: .now() + .seconds(5)) == .success)
    precondition(became == false)
    precondition(!session.isActive)
}
