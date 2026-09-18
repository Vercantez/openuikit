import Foundation
@_spi(OpenUIKitHost) import SharedWithYou

// Identity View-overlay batches: each `setDetailViewListContent` overload is
// invoked with `EmptyView` plus a slug-local probe content view. Linux never
// presents a popover; these calls pin the store-without-presenting behavior.

struct DetailProbeContent: View {
    var body: EmptyView { EmptyView() }
}

func testViewOverlayBatch01DetailContent() {
    let view = SWCollaborationView(itemProvider: NSItemProvider())
    swRequire(
        SharedWithYouHostControl.detailListContentKind(view) == nil,
        "unset"
    )
    view.setDetailViewListContent(EmptyView())
    swRequire(
        SharedWithYouHostControl.detailListContentKind(view) == "EmptyView",
        "empty"
    )
    view.setDetailViewListContent(DetailProbeContent())
    swRequire(
        SharedWithYouHostControl.detailListContentKind(view) == "DetailProbeContent",
        "probe"
    )
}

func testViewOverlayBatch02DetailContentBuilder() {
    let view = SWCollaborationView(itemProvider: NSItemProvider())
    view.setDetailViewListContent {
        EmptyView()
    }
    swRequire(
        SharedWithYouHostControl.detailListContentKind(view) == "EmptyView",
        "builder empty"
    )
    view.setDetailViewListContent {
        DetailProbeContent()
    }
    swRequire(
        SharedWithYouHostControl.detailListContentKind(view) == "DetailProbeContent",
        "builder probe"
    )
}
