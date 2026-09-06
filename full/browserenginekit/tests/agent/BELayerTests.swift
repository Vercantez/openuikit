import Foundation
import BrowserEngineKit

func testLayerHierarchyInitThrows() {
    do {
        _ = try LayerHierarchy()
        preconditionFailure("layer hierarchy must fail closed")
    } catch let error as BrowserEngineKitHostError {
        precondition(error == .layerHierarchyUnavailable)
        precondition(error.errorCode == 3)
    } catch {
        preconditionFailure("unexpected")
    }
}

func testLayerHierarchyHostMakeHandleAndInvalidate() {
    let hierarchy = LayerHierarchy.host_makeInert()
    precondition(!hierarchy.isInvalidated)
    let handle = hierarchy.handle
    _ = handle
    let layer = CALayer()
    hierarchy.layer = layer
    precondition(hierarchy.layer === layer)
    hierarchy.invalidate()
    precondition(hierarchy.isInvalidated)
    precondition(hierarchy.layer == nil)
}

func testLayerHierarchyHandleInitThrows() {
    do {
        _ = try LayerHierarchyHandle(port: 0, data: Data())
        preconditionFailure("port handle must fail")
    } catch let error as BrowserEngineKitHostError {
        precondition(error == .layerHierarchyUnavailable)
    } catch {
        preconditionFailure("unexpected")
    }
    do {
        _ = try LayerHierarchyHandle(xpcRepresentation: nil)
        preconditionFailure("xpc handle must fail")
    } catch let error as BrowserEngineKitHostError {
        precondition(error == .layerHierarchyUnavailable)
    } catch {
        preconditionFailure("unexpected")
    }
}

func testLayerHierarchyHandleEncodeDoesNotInvokeBlock() {
    let handle = LayerHierarchyHandle.host_makeInert()
    var invoked = false
    handle.encode { _, _ in invoked = true }
    precondition(!invoked)
    let xpc = handle.createXPCRepresentation()
    precondition(xpc is BEHostXPCObject)
    precondition(LayerHierarchyHandle.supportsSecureCoding)
    let decoded = LayerHierarchyHandle(coder: NSKeyedArchiver(requiringSecureCoding: false))
    precondition(decoded != nil)
}

func testLayerHierarchyHostingViewHandle() {
    let view = LayerHierarchyHostingView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
    precondition(view.handle == nil)
    let handle = LayerHierarchyHandle.host_makeInert()
    view.handle = handle
    precondition(view.handle === handle)
}

func testLayerHierarchyCoordinatorInitThrows() {
    do {
        _ = try LayerHierarchyHostingTransactionCoordinator()
        preconditionFailure("coordinator must fail")
    } catch let error as BrowserEngineKitHostError {
        precondition(error == .layerHierarchyUnavailable)
    } catch {
        preconditionFailure("unexpected")
    }
    do {
        _ = try LayerHierarchyHostingTransactionCoordinator(port: 1, data: Data([1]))
        preconditionFailure("port coordinator must fail")
    } catch let error as BrowserEngineKitHostError {
        precondition(error == .layerHierarchyUnavailable)
    } catch {
        preconditionFailure("unexpected")
    }
    do {
        _ = try LayerHierarchyHostingTransactionCoordinator(xpcRepresentation: BEHostXPCObject())
        preconditionFailure("xpc coordinator must fail")
    } catch let error as BrowserEngineKitHostError {
        precondition(error == .layerHierarchyUnavailable)
    } catch {
        preconditionFailure("unexpected")
    }
}

func testLayerHierarchyCoordinatorAddAndCommit() {
    let coordinator = LayerHierarchyHostingTransactionCoordinator.host_makeInert()
    let hierarchy = LayerHierarchy.host_makeInert()
    let view = LayerHierarchyHostingView()
    coordinator.add(hierarchy)
    coordinator.add(view)
    precondition(coordinator.addedHierarchies.count == 1)
    precondition(coordinator.addedViews.count == 1)
    precondition(!coordinator.isCommitted)
    coordinator.commit()
    precondition(coordinator.isCommitted)
    var invoked = false
    coordinator.encode { _, _ in invoked = true }
    precondition(!invoked)
    precondition(coordinator.createXPCRepresentation() is BEHostXPCObject)
    let decoded = LayerHierarchyHostingTransactionCoordinator(coder: NSKeyedArchiver(requiringSecureCoding: false))
    precondition(decoded != nil)
}
