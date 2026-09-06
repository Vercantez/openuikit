import Foundation
import ModelIO

func testObjectContainer() {
    let container = MDLObjectContainer()
    let child = MDLObject()
    child.name = "kid"
    container.add(child)
    mdlCheck(container.count == 1, "count")
    mdlCheck(container.objects.first === child, "objects")
    mdlCheck(container[0] === child, "subscript")
    container.remove(child)
    mdlCheck(container.count == 0, "removed")
}

func testObjectContainerComponent() {
    let component: any MDLObjectContainerComponent = MDLObjectContainer()
    let object = MDLObject()
    component.add(object)
    mdlCheck(component.count == 1, "count")
    mdlCheck(component.objects.count == 1, "objects")
    _ = component[0]
    component.remove(object)
    mdlCheck(component.count == 0, "remove")
}

func testObjectBasics() {
    let object = MDLObject()
    object.name = "root"
    object.hidden = true
    object.instance = nil
    mdlCheck(object.name == "root", "name")
    mdlCheck(object.hidden, "hidden")
    mdlCheck(object.instance == nil, "instance")
}

func testObjectHierarchy() {
    let parent = MDLObject()
    parent.name = "parent"
    let child = MDLObject()
    child.name = "child"
    parent.addChild(child)
    mdlCheck(child.parent === parent, "parent")
    mdlCheck(parent.children.count == 1, "children")
    mdlCheck(parent.path.contains("parent"), "path")
    let found = parent.atPath("/parent/child")
    mdlCheck(found === child || found.name == "child", "atPath")
    let box = parent.boundingBox(atTime: 0)
    _ = box
}

func testObjectComponents() {
    let object = MDLObject()
    let transform = MDLTransform()
    transform.translation = SIMD3(1, 2, 3)
    object.transform = transform
    mdlCheck(object.components.contains(where: { $0 === transform }), "components")
    mdlCheck(object.transform != nil, "transform")
}

func testEnumerateChildren() {
    let root = MDLObject()
    root.name = "root"
    let child = MDLMesh(bufferAllocator: nil)
    child.name = "mesh"
    root.addChild(child)
    var seen = 0
    var stop = ObjCBool(false)
    root.enumerateChildObjects(of: MDLMesh.self, root: root, using: { _, _ in
        seen += 1
    }, stopPointer: &stop)
    mdlCheck(seen >= 1, "enumerate mesh")
}
