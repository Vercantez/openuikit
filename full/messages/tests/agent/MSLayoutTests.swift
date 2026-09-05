import Foundation
import Messages

func testTemplateLayoutCaptions() {
    let layout = MSMessageTemplateLayout()
    layout.caption = "c"
    layout.subcaption = "sc"
    layout.trailingCaption = "tc"
    layout.trailingSubcaption = "tsc"
    layout.imageTitle = "it"
    layout.imageSubtitle = "is"
    precondition(layout.caption == "c")
    precondition(layout.subcaption == "sc")
    precondition(layout.trailingCaption == "tc")
    precondition(layout.trailingSubcaption == "tsc")
    precondition(layout.imageTitle == "it")
    precondition(layout.imageSubtitle == "is")
}

func testTemplateLayoutMediaURL() {
    let layout = MSMessageTemplateLayout()
    let url = URL(fileURLWithPath: "/tmp/media.mp4")
    layout.mediaFileURL = url
    precondition(layout.mediaFileURL == url)
}

func testTemplateLayoutCopy() {
    let layout = MSMessageTemplateLayout()
    layout.caption = "keep"
    layout.mediaFileURL = URL(fileURLWithPath: "/tmp/a.gif")
    let copy = layout.copy() as! MSMessageTemplateLayout
    precondition(copy !== layout)
    precondition(copy.caption == "keep")
    precondition(copy.mediaFileURL == layout.mediaFileURL)
    layout.caption = "changed"
    precondition(copy.caption == "keep")
}

func testLiveLayoutStoresAlternate() {
    let alternate = MSMessageTemplateLayout()
    alternate.caption = "alt"
    let live = MSMessageLiveLayout(alternateLayout: alternate)
    precondition(live.alternateLayout.caption == "alt")
    alternate.caption = "mutated"
    precondition(live.alternateLayout.caption == "alt")
}

func testLiveLayoutCopy() {
    let alternate = MSMessageTemplateLayout()
    alternate.subcaption = "sub"
    let live = MSMessageLiveLayout(alternateLayout: alternate)
    let copy = live.copy() as! MSMessageLiveLayout
    precondition(copy !== live)
    precondition(copy.alternateLayout.subcaption == "sub")
    precondition(copy.alternateLayout !== live.alternateLayout)
}

func testMessageLayoutBaseCopy() {
    let layout = MSMessageLayout()
    let copy = layout.copy() as? MSMessageLayout
    precondition(copy != nil)
    precondition(copy !== layout)
}
