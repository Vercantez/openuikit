import Foundation
@_spi(OpenUIKitHost) import CarPlay

func testInterfaceControllerRootPushPop() {
    carPlayOnMain {
        let scene = CPTemplateApplicationScene()
        scene.openuikit_connectSimulatedSession(style: .light)
        let controller = scene.interfaceController
        precondition(controller.hostSessionConnected)
        let root = CPListTemplate(title: "Root", sections: [])
        let child = CPListTemplate(title: "Child", sections: [])
        controller.setRootTemplate(root, animated: false)
        precondition(controller.rootTemplate === root)
        precondition(controller.topTemplate === root)
        precondition(controller.templates.count == 1)
        controller.pushTemplate(child, animated: false)
        precondition(controller.templates.count == 2)
        precondition(controller.topTemplate === child)
        controller.popTemplate(animated: false)
        precondition(controller.topTemplate === root)
        controller.pushTemplate(child, animated: false)
        let overflow = (0..<4).map { CPListTemplate(title: "C\($0)", sections: []) }
        for extra in overflow {
            controller.pushTemplate(extra, animated: false)
        }
        precondition(controller.templates.count == 5)
    }
}

func testInterfaceControllerPopToRootAndTarget() {
    carPlayOnMain {
        let scene = CPTemplateApplicationScene()
        scene.openuikit_connectSimulatedSession(style: .light)
        let controller = scene.interfaceController
        let root = CPListTemplate(title: "Root", sections: [])
        let child = CPListTemplate(title: "Child", sections: [])
        let child2 = CPListTemplate(title: "Child2", sections: [])
        controller.setRootTemplate(root, animated: false)
        controller.pushTemplate(child, animated: false)
        controller.pushTemplate(child2, animated: false)
        controller.pop(to: child, animated: false)
        precondition(controller.topTemplate === child)
        controller.popToRootTemplate(animated: false)
        precondition(controller.topTemplate === root)
        precondition(controller.templates.count == 1)
    }
}

func testInterfaceControllerPresentDismiss() {
    carPlayOnMain {
        let scene = CPTemplateApplicationScene()
        scene.openuikit_connectSimulatedSession(style: .light)
        let controller = scene.interfaceController
        controller.setRootTemplate(CPListTemplate(title: "Root", sections: []), animated: false)
        let presentable = CPAlertTemplate(titleVariants: ["Hi"], actions: [
            CPAlertAction(title: "A", style: .default, handler: { _ in }),
            CPAlertAction(title: "B", style: .cancel, handler: { _ in }),
            CPAlertAction(title: "C", style: .destructive, handler: { _ in }),
        ])
        precondition(presentable.actions.count == 2)
        controller.presentTemplate(presentable, animated: false)
        precondition(controller.presentedTemplate === presentable)
        let nonPresentable = CPListTemplate(title: "No", sections: [])
        controller.presentTemplate(nonPresentable, animated: false)
        precondition(controller.presentedTemplate === presentable)
        controller.dismissTemplate(animated: false)
        precondition(controller.presentedTemplate == nil)
        let sheet = CPActionSheetTemplate(title: "Sheet", message: "Msg", actions: [
            CPAlertAction(title: "One", style: .default, handler: { _ in }),
        ])
        controller.presentTemplate(sheet, animated: false)
        precondition(controller.presentedTemplate === sheet)
        controller.dismissTemplate(animated: false)
    }
}

func testInterfaceControllerDelegateAndTraits() {
    carPlayOnMain {
        let sceneDelegate = RecordingSceneDelegate()
        let scene = CPTemplateApplicationScene()
        scene.delegate = sceneDelegate
        scene.openuikit_connectSimulatedSession(style: .dark)
        precondition(sceneDelegate.connected)
        let controller = scene.interfaceController
        precondition(controller.carTraitCollection.userInterfaceStyle == .dark)
        controller.prefersDarkUserInterfaceStyle = true
        let ifaceDelegate = RecordingInterfaceDelegate()
        controller.delegate = ifaceDelegate
        let root = CPListTemplate(title: "Root", sections: [])
        let child = CPListTemplate(title: "Child", sections: [])
        controller.setRootTemplate(root, animated: false)
        controller.pushTemplate(child, animated: false)
        precondition(ifaceDelegate.events.contains("willAppear"))
        precondition(ifaceDelegate.events.contains("didAppear"))
        precondition(ifaceDelegate.events.contains("willDisappear"))
        precondition(ifaceDelegate.events.contains("didDisappear"))
        ifaceDelegate.templateWillAppear(root, animated: false)
        ifaceDelegate.templateDidAppear(root, animated: false)
        ifaceDelegate.templateWillDisappear(root, animated: false)
        ifaceDelegate.templateDidDisappear(root, animated: false)
    }
}
