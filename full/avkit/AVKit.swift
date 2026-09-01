@_exported import AVFoundation
@_exported import SwiftUI
import Foundation
import UIKit

/// A real OpenUIKit surface for AVPlayer state. A host media backend can bind
/// the same player events to decoded video; without one, the surface labels
/// the selected media instead of pretending that frames were rendered.
@MainActor
private final class _PortableAVPlayerView: UIView {
    private let statusLabel = UILabel(frame: .zero)
    var player: AVPlayer? {
        didSet { updateStatus() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        clipsToBounds = true
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 2
        statusLabel.textColor = .white
        statusLabel.font = .systemFont(ofSize: 13)
        statusLabel.accessibilityIdentifier = "AVKit.VideoPlayer.status"
        addSubview(statusLabel)
        updateStatus()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .black
        clipsToBounds = true
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 2
        statusLabel.textColor = .white
        statusLabel.font = .systemFont(ofSize: 13)
        statusLabel.accessibilityIdentifier = "AVKit.VideoPlayer.status"
        addSubview(statusLabel)
        updateStatus()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        statusLabel.frame = bounds
    }

    private func updateStatus() {
        guard let player else {
            statusLabel.text = "No Video"
            accessibilityLabel = "No Video"
            return
        }
        let title = player.currentItem?.url?.lastPathComponent ?? "Video"
        let state = player.rate == 0 ? "Paused" : "Playing"
        statusLabel.text = "\(title)\n\(state)"
        accessibilityLabel = "\(title), \(state)"
    }
}

@MainActor
private struct _PortableAVPlayerRepresentable: UIViewRepresentable {
    let player: AVPlayer?

    func makeUIView(context: Context) -> _PortableAVPlayerView {
        _ = context
        let view = _PortableAVPlayerView(frame: .zero)
        view.player = player
        return view
    }

    func updateUIView(
        _ uiView: _PortableAVPlayerView,
        context: Context
    ) {
        _ = context
        uiView.player = player
    }
}

/// SwiftUI's AVKit video surface.
///
/// Overlay composition and AVPlayer state are implemented directly. Actual
/// frame decoding is deliberately delegated to the attested AVFoundation host
/// boundary and the visible fallback stays truthful when no backend exists.
@MainActor
public struct VideoPlayer<VideoOverlay>: View where VideoOverlay: View {
    public let player: AVPlayer?
    private let videoOverlay: VideoOverlay

    public init(player: AVPlayer?) where VideoOverlay == EmptyView {
        self.player = player
        videoOverlay = EmptyView()
    }

    public init(
        player: AVPlayer?,
        @ViewBuilder videoOverlay: () -> VideoOverlay
    ) {
        self.player = player
        self.videoOverlay = videoOverlay()
    }

    public var body: some View {
        ZStack {
            _PortableAVPlayerRepresentable(player: player)
            videoOverlay
        }
    }
}
