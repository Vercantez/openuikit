import Foundation
import MediaPlayer

    /// Future EC2 identity probe. Isolated host gate does not compile this file.
    /// A cold guest build should import real Foundation, CoreGraphics, and
    /// OpenUIKit, pass IndexPath/Date/URL/UIImage values through MediaPlayer
    /// APIs, and load libMediaPlayer.dylib.

@_spi(OpenUIKitHost) import MediaPlayer

enum MediaPlayerDependencyIdentity {
    static func prove() {
        let item = MPMediaItem()
        let _: Date = item.dateAdded
        let _: URL? = item.assetURL
        let path = IndexPath(index: 0)
        let source: any MPPlayableContentDataSource = IdentityDataSource()
        _ = source.numberOfChildItems(at: path)
        let error: any Error = MPError(.notSupported)
        precondition(MPError.notSupported ~= error)
    }
}

private final class IdentityDataSource: NSObject, MPPlayableContentDataSource {
    func numberOfChildItems(at indexPath: IndexPath) -> Int {
        _ = indexPath
        return 0
    }

    func contentItem(at indexPath: IndexPath) -> MPContentItem? {
        _ = indexPath
        return nil
    }
}

print("MEDIAPLAYER_DEPENDENCY_IDENTITY_OK")
