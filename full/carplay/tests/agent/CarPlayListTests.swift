import Foundation
@_spi(OpenUIKitHost) import CarPlay

func testListItemMutationAndHandlers() {
    carPlayOnMain {
        let image = UIImage(size: CPListItem.maximumImageSize)
        var handlerCompleted = false
        let listItem = CPListItem(
            text: "Library",
            detailText: "Podcasts",
            image: image,
            accessoryImage: image,
            accessoryType: .disclosureIndicator
        )
        listItem.handler = { item, completion in
            precondition(item.text == "Albums")
            completion()
            handlerCompleted = true
        }
        listItem.isEnabled = true
        listItem.userInfo = "row-1"
        listItem.setText("Albums")
        listItem.setDetailText("On this device")
        listItem.setImage(image)
        listItem.setAccessoryImage(image)
        listItem.isPlaying = true
        listItem.playbackProgress = 0.5
        listItem.playingIndicatorLocation = .trailing
        listItem.isExplicitContent = true
        listItem.showsExplicitLabel = true
        precondition(listItem.text == "Albums")
        precondition(listItem.detailText == "On this device")
        precondition(listItem.image != nil)
        precondition(listItem.accessoryImage != nil)
        precondition(listItem.showsDisclosureIndicator)
        precondition(listItem.accessoryType == .disclosureIndicator)
        listItem.openuikit_invokeHandler()
        precondition(handlerCompleted)
        let listItem2 = CPListItem(text: "B", detailText: "C")
        let listItem3 = CPListItem(text: "D", detailText: "E", image: image)
        let listItem4 = CPListItem(text: "F", detailText: "G", image: image, showsDisclosureIndicator: true)
        precondition(listItem4.showsDisclosureIndicator)
        _ = listItem2.text
        _ = listItem3.image
        precondition(CPListItem.maximumImageSize.width == 90)
        let selectable: any CPSelectableListItem = listItem
        _ = selectable.handler
        _ = selectable.isEnabled
        let templateItem: any CPListTemplateItem = listItem
        _ = templateItem.userInfo
        _ = templateItem.text
    }
}

func testListSectionLookup() {
    carPlayOnMain {
        let image = UIImage(size: CPListItem.maximumImageSize)
        let listItem = CPListItem(text: "Albums", detailText: "On this device")
        let listItem2 = CPListItem(text: "B", detailText: "C")
        let assistant = CPAssistantCellConfiguration(position: .top, visibility: .always, assistantAction: .playMedia)
        precondition(assistant.position == .top)
        precondition(assistant.visibility == .always)
        precondition(assistant.assistantAction == .playMedia)
        let headerButton = CPButton(image: image)
        let section = CPListSection(
            items: [listItem, listItem2],
            header: "Media",
            headerSubtitle: "Sub",
            headerImage: image,
            headerButton: headerButton,
            sectionIndexTitle: "M"
        )
        precondition(section.header == "Media")
        precondition(section.headerSubtitle == "Sub")
        precondition(section.headerImage != nil)
        precondition(section.headerButton === headerButton)
        precondition(section.sectionIndexTitle == "M")
        precondition(section.items.count == 2)
        precondition(section.item(at: 0).text == "Albums")
        precondition(section.index(of: listItem) == 0)
        let protocolSection = CPListSection(items: [listItem], header: "Also", sectionIndexTitle: "A")
        let plainSection = CPListSection(items: [listItem])
        _ = CPListSection(items: [listItem] as [CPListItem])
        _ = protocolSection.items
        _ = plainSection.items
        _ = CPAssistantCellConfiguration()
    }
}

func testListTemplateLimitsAndIndexPath() {
    carPlayOnMain {
        let listItem = CPListItem(text: "Albums", detailText: "On this device")
        let assistant = CPAssistantCellConfiguration(position: .top, visibility: .always, assistantAction: .playMedia)
        let image = UIImage(size: CPButtonMaximumImageSize)
        let gridButton = CPGridButton(titleVariants: ["A"], image: image, handler: nil)
        let section = CPListSection(items: [listItem], header: "Media", sectionIndexTitle: "M")
        let list = CPListTemplate(
            title: "Home",
            sections: [section],
            assistantCellConfiguration: assistant,
            headerGridButtons: [gridButton]
        )
        let listDelegate = RecordingListDelegate()
        list.delegate = listDelegate
        list.emptyViewTitleVariants = ["Empty"]
        list.emptyViewSubtitleVariants = ["None"]
        list.showsSpinnerWhileEmpty = true
        precondition(list.title == "Home")
        precondition(list.sections.count == 1)
        precondition(list.itemCount == 1)
        precondition(list.sectionCount == 1)
        precondition(list.assistantCellConfiguration === assistant)
        precondition(list.headerGridButtons?.count == 1)
        precondition(list.indexPath(for: listItem)?[1] == 0)
        list.updateSections([section])
        let overflowItems = (0..<20).map { CPListItem(text: "\($0)", detailText: nil) }
        let overflow = CPListTemplate(title: "Overflow", sections: [CPListSection(items: overflowItems)])
        precondition(overflow.itemCount == CPListTemplate.maximumItemCount)
        precondition(CPListTemplate.maximumItemCount == 12)
        precondition(CPListTemplate.maximumSectionCount == 12)
        _ = CPListTemplate.maximumGridButtonImageSize
        _ = CPListTemplate.maximumHeaderGridButtonCount
        _ = CPListTemplate(title: "A", sections: [section], assistantCellConfiguration: assistant)
        _ = CPListTemplate(title: "B", sections: [section])
        _ = listDelegate
    }
}
