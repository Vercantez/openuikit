import Foundation
@_spi(OpenUIKitHost) import SharedWithYou

func testAttributionViewClass() {
    let view = SWAttributionView(frame: .zero)
    let asView: UIView = view
    swRequire(asView === view, "uiview")
}

func testAttributionViewHighlightProperty() {
    let view = SWAttributionView(frame: .zero)
    let highlight = swSampleHighlight("attr")
    view.highlight = highlight
    swRequire(view.highlight?.url == highlight.url, "highlight")
}

func testAttributionViewDisplayContextProperty() {
    let view = SWAttributionView(frame: .zero)
    swRequire(view.displayContext == .summary, "default summary")
    view.displayContext = .detail
    swRequire(view.displayContext == .detail, "detail")
}

func testAttributionViewHorizontalAlignmentProperty() {
    let view = SWAttributionView(frame: .zero)
    swRequire(view.horizontalAlignment == .default, "default")
    view.horizontalAlignment = .trailing
    swRequire(view.horizontalAlignment == .trailing, "trailing")
}

func testAttributionViewBackgroundStyleProperty() {
    let view = SWAttributionView(frame: .zero)
    swRequire(view.backgroundStyle == .default, "default")
    view.backgroundStyle = .material
    swRequire(view.backgroundStyle == .material, "material")
}

func testAttributionViewPreferredMaxLayoutWidthProperty() {
    let view = SWAttributionView(frame: .zero)
    swRequire(view.preferredMaxLayoutWidth == 0, "zero")
    view.preferredMaxLayoutWidth = 320
    swRequire(view.preferredMaxLayoutWidth == 320, "width")
}

func testAttributionViewMenuTitleForHideActionProperty() {
    let view = SWAttributionView(frame: .zero)
    swRequire(view.menuTitleForHideAction == nil, "nil default")
    view.menuTitleForHideAction = "Hide"
    swRequire(view.menuTitleForHideAction == "Hide", "title")
}

func testAttributionViewSupplementalMenuProperty() {
    let view = SWAttributionView(frame: .zero)
    swRequire(view.supplementalMenu == nil, "nil default")
    let menu = UIMenu(title: "More", children: [])
    view.supplementalMenu = menu
    swRequire(view.supplementalMenu === menu, "stored")
}

func testAttributionViewHighlightMenuEmpty() {
    let view = SWAttributionView(frame: .zero)
    view.menuTitleForHideAction = "Hide this"
    swRequire(view.highlightMenu.title == "Hide this", "menu title")
    swRequire(view.highlightMenu.children.isEmpty, "no Messages actions")
}
