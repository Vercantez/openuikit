import Foundation
import AVKit

#if false
import Foundation
#endif

/// Identity probe for the later clean EC2 integration build. Isolated host
/// compilation of this file is not required by the sealed gate.
func avkitDependencyIdentityProbe() {
    let domain: String = AVKitErrorDomain
    precondition(domain == "AVKitErrorDomain")

    let url = URL(fileURLWithPath: "/tmp/avkit-identity.m4v")
    let player = AVPlayer(url: url)
    let itemURL: URL? = player.currentItem?.url
    precondition(itemURL == url)

    let video = VideoPlayer(player: player)
    precondition(video.player === player)

    let nsError = AVKitError(.unknown) as NSError
    precondition(nsError.domain == AVKitErrorDomain)
    precondition(nsError.code == AVKitError.Code.unknown.rawValue)

    let analysis: AVVideoFrameAnalysisType = [.text, .subject]
    precondition(analysis.contains(.text))
}

avkitDependencyIdentityProbe()
