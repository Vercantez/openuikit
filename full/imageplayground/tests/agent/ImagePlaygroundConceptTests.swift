import Foundation
@_spi(OpenUIKitHost) import ImagePlayground

func testConceptText() {
    let concept = ImagePlaygroundConcept.text("a red bicycle")
    precondition(ImagePlaygroundHostControl.conceptKind(concept) == "text")
    precondition(ImagePlaygroundHostControl.conceptText(concept) == "a red bicycle")
    precondition(ImagePlaygroundHostControl.conceptTitle(concept) == nil)
    precondition(ImagePlaygroundHostControl.conceptImageURL(concept) == nil)
    let empty = ImagePlaygroundConcept.text("")
    precondition(ImagePlaygroundHostControl.conceptText(empty) == "")
}

func testConceptExtracted() {
    let titled = ImagePlaygroundConcept.extracted(from: "sunset over water", title: "caption")
    precondition(ImagePlaygroundHostControl.conceptKind(titled) == "extracted")
    precondition(ImagePlaygroundHostControl.conceptText(titled) == "sunset over water")
    precondition(ImagePlaygroundHostControl.conceptTitle(titled) == "caption")
    let untitled = ImagePlaygroundConcept.extracted(from: "plain")
    precondition(ImagePlaygroundHostControl.conceptKind(untitled) == "extracted")
    precondition(ImagePlaygroundHostControl.conceptText(untitled) == "plain")
    precondition(ImagePlaygroundHostControl.conceptTitle(untitled) == nil)
}

func testConceptImageURL() {
    let fileURL = URL(fileURLWithPath: "/tmp/imageplayground-probe.png")
    let fromFile = ImagePlaygroundConcept.image(fileURL)
    precondition(fromFile != nil)
    precondition(ImagePlaygroundHostControl.conceptKind(fromFile!) == "imageURL")
    precondition(ImagePlaygroundHostControl.conceptImageURL(fromFile!) == fileURL)
    let remote = URL(string: "https://example.com/probe.png")!
    precondition(ImagePlaygroundConcept.image(remote) == nil)
    let customScheme = URL(string: "photos://library/item")!
    precondition(ImagePlaygroundConcept.image(customScheme) == nil)
}
