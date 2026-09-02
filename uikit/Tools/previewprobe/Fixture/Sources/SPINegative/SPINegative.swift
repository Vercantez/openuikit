import UIKit

@MainActor
func cannotReachPreviewStorage() {
    let preview = DeveloperToolsSupport.Preview(body: { UIView() })
    _ = preview._openUIKitBody()
}
