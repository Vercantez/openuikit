import Foundation
import QuickLook

func quickLookDependencyIdentityProbe() {
  let url = URL(fileURLWithPath: "/tmp/quicklook-identity.png")
  let item = ARQuickLookPreviewItem(fileAt: url)
  precondition(item.previewItemURL == url)

  let reply = QLPreviewReply(fileURL: url)
  reply.title = url.lastPathComponent
  precondition(reply.title == "quicklook-identity.png")

  let configuration = QLPreviewSceneActivationConfiguration(
    itemsAt: [url],
    options: nil
  )
  _ = configuration
  _ = QLPreviewItemEditingMode.disabled
  _ = QLPreviewProvider()
  _ = URL(fileURLWithPath: "/tmp/quicklook-identity.png")
}

#if QUICKLOOK_IDENTITY_MAIN
quickLookDependencyIdentityProbe()
print("QUICKLOOK_DEPENDENCY_IDENTITY_OK")
#endif
