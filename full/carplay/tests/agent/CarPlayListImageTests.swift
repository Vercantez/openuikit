import Foundation
@_spi(OpenUIKitHost) import CarPlay

func testListImageRowItemElements() {
    carPlayOnMain {
        let image = UIImage(size: CPListImageRowItem.maximumImageSize)
        let color = UIColor()
        let card = CPListImageRowItemCardElement(
            image: image,
            showsImageFullHeight: true,
            title: "Card",
            subtitle: "S",
            tintColor: color
        )
        precondition(card.showsImageFullHeight)
        precondition(card.title == "Card")
        precondition(card.subtitle == "S")
        precondition(card.tintColor != nil)
        let condensed = CPListImageRowItemCondensedElement(
            image: image,
            imageShape: .circular,
            title: "C",
            subtitle: "s",
            accessorySymbolName: "star"
        )
        precondition(condensed.imageShape == .circular)
        precondition(condensed.accessorySymbolName == "star")
        let gridEl = CPListImageRowItemGridElement(image: image)
        let imageGrid = CPListImageRowItemImageGridElement(
            image: image,
            imageShape: .roundedRectangle,
            title: "G",
            accessorySymbolName: nil
        )
        precondition(imageGrid.imageShape == .roundedRectangle)
        let rowEl = CPListImageRowItemRowElement(image: image, title: "R", subtitle: "r")
        precondition(rowEl.title == "R")
        precondition(rowEl.subtitle == "r")
        _ = CPListImageRowItemCardElement.maximumFullHeightImageSize
        _ = CPListImageRowItemElement.maximumImageSize
        var rowHandler = false
        let rowItem = CPListImageRowItem(text: "Row", images: [image, image], imageTitles: ["1", "2"])
        rowItem.listImageRowHandler = { _, _, completion in
            rowHandler = true
            completion()
        }
        rowItem.handler = { _, completion in completion() }
        rowItem.isEnabled = true
        rowItem.userInfo = "row"
        rowItem.allowsMultipleLines = true
        rowItem.openuikit_invokeRowHandler(index: 0)
        rowItem.openuikit_invokeHandler()
        precondition(rowHandler)
        rowItem.update([image])
        precondition(rowItem.gridImages.count == 1)
        precondition(rowItem.imageTitles.count == 2)
        precondition(rowItem.text == "Row")
        _ = CPListImageRowItem(text: "c", cardElements: [card], allowsMultipleLines: true)
        _ = CPListImageRowItem(text: "d", condensedElements: [condensed], allowsMultipleLines: false)
        _ = CPListImageRowItem(text: "e", elements: [rowEl], allowsMultipleLines: true)
        _ = CPListImageRowItem(text: "f", gridElements: [gridEl], allowsMultipleLines: false)
        _ = CPListImageRowItem(text: "g", imageGridElements: [imageGrid], allowsMultipleLines: true)
        _ = CPListImageRowItem(text: "h", images: [image])
        _ = CPListImageRowItem.maximumImageSize
        _ = gridEl.isEnabled
        _ = gridEl.image
        _ = CPListImageRowItemElement()
        _ = CPListImageRowItemCardElement()
        _ = CPListImageRowItemCondensedElement()
        _ = CPListImageRowItemGridElement()
        _ = CPListImageRowItemImageGridElement()
        _ = CPListImageRowItemRowElement()
        _ = CPListImageRowItem()
    }
}
