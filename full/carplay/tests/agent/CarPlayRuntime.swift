import CarPlay
import Foundation

await MainActor.run {
    // Enum raw values from pinned dotnet/macios Native enums (not invented).
    precondition(CPAlertAction.Style.default.rawValue == 0)
    precondition(CPAlertAction.Style.cancel.rawValue == 1)
    precondition(CPAlertAction.Style.destructive.rawValue == 2)
    precondition(CPBarButtonStyle.none.rawValue == 0)
    precondition(CPBarButtonStyle.rounded.rawValue == 1)
    precondition(CPLaneStatus.notGood.rawValue == 0)
    precondition(CPLaneStatus.good.rawValue == 1)
    precondition(CPLaneStatus.preferred.rawValue == 2)
    precondition(CPJunctionType.intersection.rawValue == 0)
    precondition(CPJunctionType.roundabout.rawValue == 1)
    precondition(CPTrafficSide.right.rawValue == 0)
    precondition(CPTrafficSide.left.rawValue == 1)
    precondition(CPManeuverType.noTurn.rawValue == 0)
    precondition(CPManeuverType.leftTurn.rawValue == 1)
    precondition(CPManeuverType.uTurn.rawValue == 4)
    precondition(CPManeuverType.changeHighwayRight.rawValue == 53)
    precondition(CPNavigationSession.PauseReason.arrived.rawValue == 1)
    precondition(CPContentStyle.light.rawValue == 1 << 0)
    precondition(CPContentStyle.dark.rawValue == 1 << 1)
    precondition(CPLimitableUserInterface.lists.contains(.lists))
    precondition(CPLimitableUserInterface.keyboard.contains(.keyboard))
    precondition(CPMapTemplate.PanDirection.left.contains(.left))
    precondition(CPMapTemplate.PanDirection.right.contains(.right))
    precondition(CPMapTemplate.PanDirection.up.contains(.up))
    precondition(CPMapTemplate.PanDirection.down.contains(.down))

    let junction = NSStringFromCPJunctionType(.intersection)
    let lane = NSStringFromCPLaneStatus(.preferred)
    let maneuver = NSStringFromCPManeuverType(.uTurn)
    let traffic = NSStringFromCPTrafficSide(.left)
    precondition(junction != lane)
    precondition(Set([junction, lane, maneuver, traffic]).count == 4)

    var fired = false
    let action = CPAlertAction(title: "Go", style: .default) { alert in
        fired = true
        precondition(alert.title == "Go")
        precondition(alert.style == .default)
    }
    precondition(action.title == "Go")
    action.handler(action)
    precondition(fired)

    let item = CPListItem(text: "Library", detailText: "Podcasts")
    item.isEnabled = true
    item.userInfo = "row-1"
    item.setText("Albums")
    item.setDetailText("On this device")
    precondition(item.text == "Albums")
    precondition(item.detailText == "On this device")
    precondition(item.isEnabled)
    precondition((item.userInfo as? String) == "row-1")

    let section = CPListSection(items: [item], header: "Media", sectionIndexTitle: "M")
    precondition(section.items.count == 1)
    precondition(section.header == "Media")
    precondition(section.sectionIndexTitle == "M")
    let fetched = section.item(at: 0)
    precondition(fetched.text == "Albums")

    let protocolItems: [any CPListTemplateItem] = [item]
    let protocolSection = CPListSection(
        items: protocolItems,
        header: "Also",
        sectionIndexTitle: "A"
    )
    precondition(protocolSection.header == "Also")
    precondition(protocolSection.sectionIndexTitle == "A")
    precondition(protocolSection.items.count == 1)

    let list = CPListTemplate(title: "Home", sections: [section])
    precondition(list.title == "Home")
    list.updateSections([section, protocolSection])
    precondition(list.sections.count == 2)
    precondition(list.sectionCount == 2)
    precondition(list.itemCount == 2)

    let root = CPListTemplate(title: "Root", sections: [])
    let child = CPListTemplate(title: "Child", sections: [])
    let controller = CPInterfaceController()
    controller.setRootTemplate(root, animated: false)
    precondition(controller.templates.count == 1)
    precondition(controller.rootTemplate === root)
    precondition(controller.topTemplate === root)
    controller.pushTemplate(child, animated: false)
    precondition(controller.templates.count == 2)
    precondition(controller.topTemplate === child)
    controller.popTemplate(animated: false)
    precondition(controller.templates.count == 1)
    precondition(controller.topTemplate === root)
    controller.pushTemplate(child, animated: false)
    controller.popToRootTemplate(animated: false)
    precondition(controller.templates.count == 1)
    precondition(controller.topTemplate === root)
    controller.presentTemplate(list, animated: false)
    precondition(controller.presentedTemplate === list)
    controller.dismissTemplate(animated: false)
    precondition(controller.presentedTemplate == nil)

    let nowA = CPNowPlayingTemplate.shared
    let nowB = CPNowPlayingTemplate.shared
    precondition(nowA === nowB)

    let config = CPSessionConfiguration()
    precondition(config.limitedUserInterfaces.isEmpty)

    print("CARPLAY_AGENT_RUNTIME_OK")
}
