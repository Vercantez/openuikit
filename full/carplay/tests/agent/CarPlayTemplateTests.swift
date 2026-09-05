import Foundation
@_spi(OpenUIKitHost) import CarPlay

func testGridTemplateButtonCap() {
    carPlayOnMain {
        let image = UIImage(size: CPButtonMaximumImageSize)
        var gridFired = false
        let gridButton = CPGridButton(titleVariants: ["A"], image: image) { _ in gridFired = true }
        gridButton.isEnabled = true
        gridButton.updateTitleVariants(["B"])
        gridButton.updateImage(image)
        gridButton.openuikit_invokeHandler()
        precondition(gridFired)
        precondition(gridButton.titleVariants == ["B"])
        let msgCfg = CPMessageGridItemConfiguration(conversationIdentifier: "c1", unread: true)
        precondition(msgCfg.conversationIdentifier == "c1")
        precondition(msgCfg.isUnread)
        msgCfg.isUnread = false
        let gridButton2 = CPGridButton(titleVariants: ["C"], image: image, messageConfiguration: msgCfg, handler: nil)
        precondition(gridButton2.messageConfiguration?.conversationIdentifier == "c1")
        let tooMany = (0..<10).map { CPGridButton(titleVariants: ["\($0)"], image: image, handler: nil) }
        let grid = CPGridTemplate(title: "Grid", gridButtons: tooMany)
        precondition(grid.gridButtons.count == 8)
        grid.updateGridButtons(Array(tooMany.prefix(3)))
        grid.updateTitle("Grid2")
        precondition(grid.title == "Grid2")
        _ = CPGridTemplate.maximumGridButtonImageSize
        _ = CPGridButton()
        _ = CPMessageGridItemConfiguration(conversationIdentifier: "x", unread: false)
    }
}

func testTabBarTemplateSelection() {
    carPlayOnMain {
        let tabA = CPListTemplate(title: "TabA", sections: [])
        tabA.tabTitle = "A"
        let tabB = CPListTemplate(title: "TabB", sections: [])
        let tabC = CPListTemplate(title: "TabC", sections: [])
        let tabD = CPListTemplate(title: "TabD", sections: [])
        let tabE = CPListTemplate(title: "TabE", sections: [])
        let tabF = CPListTemplate(title: "TabF", sections: [])
        let tabDelegate = RecordingTabDelegate()
        let tabs = CPTabBarTemplate(templates: [tabA, tabB, tabC, tabD, tabE, tabF])
        tabs.delegate = tabDelegate
        precondition(tabs.templates.count == 5)
        precondition(CPTabBarTemplate.maximumTabCount == 5)
        tabs.select(tabB)
        precondition(tabs.selectedTemplate === tabB)
        tabs.selectTemplate(at: 0)
        tabs.updateTemplates([tabA, tabB])
        precondition(tabs.templates.count == 2)
        tabDelegate.tabBarTemplate(tabs, didSelect: tabA)
        precondition(tabDelegate.selected === tabA)
    }
}

func testAlertActionAndTemplates() {
    carPlayOnMain {
        let color = UIColor()
        var alertFired = false
        let alertAction = CPAlertAction(title: "Go", style: .default) { action in
            alertFired = true
            precondition(action.title == "Go")
        }
        alertAction.color = color
        alertAction.openuikit_invokeHandler()
        precondition(alertFired)
        precondition(alertAction.style == .default)
        let colored = CPAlertAction(title: "Tint", color: color, handler: { _ in })
        precondition(colored.title == "Tint")
        precondition(colored.color != nil)
        _ = colored.handler
        let presentable = CPAlertTemplate(titleVariants: ["Hi"], actions: [alertAction, colored])
        precondition(presentable.titleVariants == ["Hi"])
        precondition(CPAlertTemplate.maximumActionCount == 2)
        let sheet = CPActionSheetTemplate(title: "Sheet", message: "Msg", actions: [alertAction])
        precondition(sheet.title == "Sheet")
        precondition(sheet.message == "Msg")
        precondition(sheet.actions.count == 1)
        _ = CPAlertAction()
        _ = CPAlertTemplate(titleVariants: [], actions: [])
        _ = CPActionSheetTemplate(title: nil, message: nil, actions: [])
    }
}

func testVoiceControlTemplateStates() {
    carPlayOnMain {
        let image = UIImage()
        let voiceState = CPVoiceControlState(
            identifier: "listen",
            titleVariants: ["Listening"],
            image: image,
            repeats: true
        )
        precondition(voiceState.identifier == "listen")
        precondition(voiceState.titleVariants == ["Listening"])
        precondition(voiceState.repeats)
        precondition(voiceState.image != nil)
        let voice = CPVoiceControlTemplate(voiceControlStates: [voiceState])
        voice.activateVoiceControlState(withIdentifier: "listen")
        precondition(voice.activeStateIdentifier == "listen")
        precondition(voice.voiceControlStates.count == 1)
        _ = CPVoiceControlState()
    }
}

func testInformationTemplateItems() {
    carPlayOnMain {
        let infoItem = CPInformationItem(title: "T", detail: "D")
        precondition(infoItem.title == "T")
        precondition(infoItem.detail == "D")
        let rating = CPInformationRatingItem(rating: 4, maximumRating: 5, title: "Rate", detail: "Good")
        precondition(rating.title == "Rate")
        precondition(rating.rating != nil)
        precondition(rating.maximumRating != nil)
        var textFired = false
        let textButton = CPTextButton(title: "OK", textStyle: .confirm) { _ in textFired = true }
        textButton.openuikit_invokeHandler()
        precondition(textFired)
        let info = CPInformationTemplate(
            title: "Info",
            layout: .twoColumn,
            items: [infoItem, rating],
            actions: [textButton]
        )
        precondition(info.title == "Info")
        precondition(info.layout == .twoColumn)
        precondition(info.items.count == 2)
        precondition(info.actions.count == 1)
        _ = CPInformationItem()
        _ = CPInformationRatingItem()
    }
}

func testSearchTemplateDelegateHooks() {
    carPlayOnMain {
        let search = CPSearchTemplate()
        let searchDelegate = RecordingSearchDelegate()
        search.delegate = searchDelegate
        searchDelegate.searchTemplateSearchButtonPressed(search)
        _ = search.delegate
    }
}

func testContactTemplateAndButtons() {
    carPlayOnMain {
        let image = UIImage()
        let contact = CPContact(name: "Ada", image: image)
        contact.subtitle = "Engineer"
        contact.informativeText = "Info"
        precondition(contact.name == "Ada")
        let call = CPContactCallButton { _ in }
        let directions = CPContactDirectionsButton { _ in }
        let messageBtn = CPContactMessageButton(phoneOrEmail: "ada@example.com")
        precondition(messageBtn.phoneOrEmail == "ada@example.com")
        contact.actions = [call, directions, messageBtn]
        call.openuikit_invokeHandler()
        directions.openuikit_invokeHandler()
        let contactTemplate = CPContactTemplate(contact: contact)
        contactTemplate.userInfo = "contact"
        contactTemplate.tabTitle = "People"
        contactTemplate.tabImage = image
        contactTemplate.showsTabBadge = true
        contactTemplate.tabSystemItem = .contacts
        precondition(contactTemplate.contact.name == "Ada")
        _ = CPContact()
        _ = CPContactCallButton()
        _ = CPContactDirectionsButton()
        _ = CPContactMessageButton()
        _ = CPContactTemplate()
        var buttonFired = false
        let button = CPButton(image: image) { _ in buttonFired = true }
        button.title = "Btn"
        button.isEnabled = true
        button.openuikit_invokeHandler()
        precondition(buttonFired)
        _ = button.image
        _ = CPButton()
    }
}

func testBarButtonAndTextButton() {
    carPlayOnMain {
        let image = UIImage()
        var barFired = false
        let bar = CPBarButton(title: "Back") { _ in barFired = true }
        bar.buttonStyle = .rounded
        bar.isEnabled = true
        bar.openuikit_invokeHandler()
        precondition(barFired)
        precondition(bar.title == "Back")
        precondition(bar.buttonStyle == .rounded)
        let barImage = CPBarButton(image: image) { _ in }
        precondition(barImage.buttonType == .image)
        let barType = CPBarButton(type: .text) { _ in }
        precondition(barType.buttonType == .text)
        var textFired = false
        let textButton = CPTextButton(title: "OK", textStyle: .normal) { _ in textFired = true }
        textButton.openuikit_invokeHandler()
        precondition(textFired)
        precondition(textButton.title == "OK")
        precondition(textButton.textStyle == .normal)
        _ = CPBarButton()
        _ = CPTextButton()
        let handler: CPBarButtonHandler = { _ in }
        let alertHandler: CPAlertActionHandler = { _ in }
        _ = handler
        _ = alertHandler
    }
}

func testMessageListItemConfigurations() {
    carPlayOnMain {
        let image = UIImage(size: CPMaximumMessageItemImageSize)
        let leading = CPMessageListItemLeadingConfiguration(leadingItem: .pin, leadingImage: image, unread: true)
        precondition(leading.isUnread)
        precondition(leading.leadingItem == .pin)
        precondition(leading.leadingImage != nil)
        let trailing = CPMessageListItemTrailingConfiguration(trailingItem: .mute, trailingImage: image)
        precondition(trailing.trailingItem == .mute)
        precondition(trailing.trailingImage != nil)
        let messageItem = CPMessageListItem(
            conversationIdentifier: "cid",
            text: "Hello",
            leadingConfiguration: leading,
            trailingConfiguration: trailing,
            detailText: "Today",
            trailingText: "1"
        )
        messageItem.leadingDetailTextImage = image
        messageItem.userInfo = 7
        messageItem.isEnabled = true
        precondition(messageItem.conversationIdentifier == "cid")
        precondition(messageItem.text == "Hello")
        precondition(messageItem.detailText == "Today")
        precondition(messageItem.trailingText == "1")
        let messageItem2 = CPMessageListItem(
            fullName: "Ada",
            phoneOrEmailAddress: "a@b.c",
            leadingConfiguration: leading,
            trailingConfiguration: trailing,
            detailText: nil,
            trailingText: nil
        )
        precondition(messageItem2.text == "Ada")
        let compose = CPMessageComposeBarButton(image: image)
        precondition(compose.buttonType == .image)
        _ = CPMessageComposeBarButton()
        _ = CPMessageListItem()
        _ = CPMaximumMessageItemLeadingDetailTextImageSize
    }
}

func testTemplateBarButtonProviding() {
    carPlayOnMain {
        let image = UIImage()
        let bar = CPBarButton(title: "Back") { _ in }
        let barImage = CPBarButton(image: image) { _ in }
        let template = CPTemplate()
        template.userInfo = "t"
        template.tabTitle = "Tab"
        template.tabImage = image
        template.showsTabBadge = false
        template.tabSystemItem = .favorites
        let list = CPListTemplate(title: "Home", sections: [])
        list.leadingNavigationBarButtons = [bar]
        list.trailingNavigationBarButtons = [barImage]
        list.backButton = bar
        precondition(list.leadingNavigationBarButtons.count == 1)
        precondition(list.trailingNavigationBarButtons.count == 1)
        precondition(list.backButton === bar)
        let providing: any CPBarButtonProviding = list
        _ = providing.backButton
        _ = providing.leadingNavigationBarButtons
        _ = providing.trailingNavigationBarButtons
    }
}
