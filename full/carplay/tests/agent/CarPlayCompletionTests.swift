import Foundation
@_spi(OpenUIKitHost) import CarPlay

func testSetRootTemplateCompletion() {
    carPlayOnMain {
        let scene = CPTemplateApplicationScene()
        scene.openuikit_connectSimulatedSession(style: .light)
        let controller = scene.interfaceController
        let root = CPListTemplate(title: "Root", sections: [])
        var completed = false
        controller.setRootTemplate(root, animated: false) { success, error in
            completed = true
            precondition(success)
            precondition(error == nil)
        }
        precondition(completed)
        precondition(controller.rootTemplate === root)
        scene.openuikit_disconnectSimulatedSession()
        var failed = false
        controller.setRootTemplate(CPListTemplate(title: "Other", sections: []), animated: false) { success, error in
            failed = true
            precondition(!success)
            precondition((error as? CarPlayHostError) == .notConnected)
        }
        precondition(failed)
    }
}

func testPushTemplateCompletion() {
    carPlayOnMain {
        let scene = CPTemplateApplicationScene()
        scene.openuikit_connectSimulatedSession(style: .light)
        let controller = scene.interfaceController
        controller.setRootTemplate(CPListTemplate(title: "Root", sections: []), animated: false)
        let child = CPListTemplate(title: "Child", sections: [])
        var completed = false
        controller.pushTemplate(child, animated: false) { success, error in
            completed = true
            precondition(success)
            precondition(error == nil)
        }
        precondition(completed)
        precondition(controller.topTemplate === child)
        scene.openuikit_disconnectSimulatedSession()
        var failed = false
        controller.pushTemplate(CPListTemplate(title: "X", sections: []), animated: false) { success, error in
            failed = true
            precondition(!success)
            precondition((error as? CarPlayHostError) == .notConnected)
        }
        precondition(failed)
    }
}

func testPopTemplateCompletion() {
    carPlayOnMain {
        let scene = CPTemplateApplicationScene()
        scene.openuikit_connectSimulatedSession(style: .light)
        let controller = scene.interfaceController
        let root = CPListTemplate(title: "Root", sections: [])
        controller.setRootTemplate(root, animated: false)
        controller.pushTemplate(CPListTemplate(title: "Child", sections: []), animated: false)
        var completed = false
        controller.popTemplate(animated: false) { success, error in
            completed = true
            precondition(success)
            precondition(error == nil)
        }
        precondition(completed)
        precondition(controller.topTemplate === root)
        var failed = false
        controller.popTemplate(animated: false) { success, error in
            failed = true
            precondition(!success)
            precondition((error as? CarPlayHostError) == .emptyTemplateStack)
        }
        precondition(failed)
    }
}

func testPopToRootTemplateCompletion() {
    carPlayOnMain {
        let scene = CPTemplateApplicationScene()
        scene.openuikit_connectSimulatedSession(style: .light)
        let controller = scene.interfaceController
        let root = CPListTemplate(title: "Root", sections: [])
        controller.setRootTemplate(root, animated: false)
        controller.pushTemplate(CPListTemplate(title: "Child", sections: []), animated: false)
        controller.pushTemplate(CPListTemplate(title: "Child2", sections: []), animated: false)
        var completed = false
        controller.popToRootTemplate(animated: false) { success, error in
            completed = true
            precondition(success)
            precondition(error == nil)
        }
        precondition(completed)
        precondition(controller.topTemplate === root)
        precondition(controller.templates.count == 1)
    }
}

func testPopToTemplateCompletion() {
    carPlayOnMain {
        let scene = CPTemplateApplicationScene()
        scene.openuikit_connectSimulatedSession(style: .light)
        let controller = scene.interfaceController
        let root = CPListTemplate(title: "Root", sections: [])
        let child = CPListTemplate(title: "Child", sections: [])
        controller.setRootTemplate(root, animated: false)
        controller.pushTemplate(child, animated: false)
        controller.pushTemplate(CPListTemplate(title: "Child2", sections: []), animated: false)
        var completed = false
        controller.pop(to: child, animated: false) { success, error in
            completed = true
            precondition(success)
            precondition(error == nil)
        }
        precondition(completed)
        precondition(controller.topTemplate === child)
        var failed = false
        controller.pop(to: CPListTemplate(title: "Stranger", sections: []), animated: false) { success, error in
            failed = true
            precondition(!success)
            precondition((error as? CarPlayHostError) == .templateNotInHierarchy)
        }
        precondition(failed)
    }
}

func testPresentTemplateCompletion() {
    carPlayOnMain {
        let scene = CPTemplateApplicationScene()
        scene.openuikit_connectSimulatedSession(style: .light)
        let controller = scene.interfaceController
        controller.setRootTemplate(CPListTemplate(title: "Root", sections: []), animated: false)
        let presentable = CPAlertTemplate(titleVariants: ["Hi"], actions: [
            CPAlertAction(title: "A", style: .default, handler: { _ in }),
        ])
        var completed = false
        controller.presentTemplate(presentable, animated: false) { success, error in
            completed = true
            precondition(success)
            precondition(error == nil)
        }
        precondition(completed)
        precondition(controller.presentedTemplate === presentable)
        controller.dismissTemplate(animated: false)
        var failed = false
        controller.presentTemplate(CPListTemplate(title: "No", sections: []), animated: false) { success, error in
            failed = true
            precondition(!success)
            precondition((error as? CarPlayHostError) == .invalidTemplate)
        }
        precondition(failed)
    }
}

func testDismissTemplateCompletion() {
    carPlayOnMain {
        let scene = CPTemplateApplicationScene()
        scene.openuikit_connectSimulatedSession(style: .light)
        let controller = scene.interfaceController
        controller.setRootTemplate(CPListTemplate(title: "Root", sections: []), animated: false)
        let sheet = CPActionSheetTemplate(title: "Sheet", message: "Msg", actions: [
            CPAlertAction(title: "One", style: .default, handler: { _ in }),
        ])
        controller.presentTemplate(sheet, animated: false)
        var completed = false
        controller.dismissTemplate(animated: false) { success, error in
            completed = true
            precondition(success)
            precondition(error == nil)
        }
        precondition(completed)
        precondition(controller.presentedTemplate == nil)
        var failed = false
        controller.dismissTemplate(animated: false) { success, error in
            failed = true
            precondition(!success)
            precondition((error as? CarPlayHostError) == .emptyTemplateStack)
        }
        precondition(failed)
    }
}

func testDismissNavigationAlertCompletion() {
    carPlayOnMain {
        let image = UIImage()
        let action = CPAlertAction(title: "Go", style: .default, handler: { _ in })
        let navAlert = CPNavigationAlert(
            titleVariants: ["Slow"],
            subtitleVariants: ["Traffic"],
            image: image,
            primaryAction: action,
            secondaryAction: nil,
            duration: CPNavigationAlertMinimumDuration
        )
        let map = CPMapTemplate()
        map.present(navigationAlert: navAlert, animated: false)
        var completed = false
        map.dismissNavigationAlert(animated: false) { dismissed in
            completed = true
            precondition(dismissed)
        }
        precondition(completed)
        precondition(map.currentNavigationAlert == nil)
        var completedAgain = false
        map.dismissNavigationAlert(animated: false) { dismissed in
            completedAgain = true
            precondition(!dismissed)
        }
        precondition(completedAgain)
    }
}
