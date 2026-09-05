import Foundation

public class MDLObjectContainer: NSObject, MDLObjectContainerComponent {
    private var storage: [MDLObject] = []

    public var count: UInt { UInt(storage.count) }
    public var objects: [MDLObject] { storage }

    public func add(_ object: MDLObject) {
        if !storage.contains(where: { $0 === object }) {
            storage.append(object)
        }
    }

    public func remove(_ object: MDLObject) {
        storage.removeAll { $0 === object }
    }

    public subscript(index: UInt) -> MDLObject {
        storage[Int(index)]
    }

}

open class MDLObject: NSObject, MDLNamed {
    public var name: String = ""
    public var hidden: Bool = false
    public weak var parent: MDLObject?
    public var instance: MDLObject?
    public var children: any MDLObjectContainerComponent = MDLObjectContainer()
    private var storedComponents: [any MDLComponent] = []
    private var transformComponent: (any MDLTransformComponent)?

    public var components: [any MDLComponent] { storedComponents }

    public func addComponent(_ component: any MDLComponent) {
        if storedComponents.contains(where: { $0 === component }) { return }
        storedComponents.append(component)
        if let transform = component as? any MDLTransformComponent {
            transformComponent = transform
        }
    }

    public var transform: (any MDLTransformComponent)? {
        get { transformComponent }
        set {
            if let old = transformComponent {
                storedComponents.removeAll { $0 === old }
            }
            transformComponent = newValue
            if let value = newValue, !storedComponents.contains(where: { $0 === value }) {
                storedComponents.append(value)
            }
        }
    }

    public var path: String {
        var parts: [String] = []
        var current: MDLObject? = self
        while let node = current {
            let piece = node.name.isEmpty ? node.defaultPathName() : node.name
            parts.append(piece)
            current = node.parent
        }
        return "/" + parts.reversed().joined(separator: "/")
    }

    func defaultPathName() -> String {
        String(describing: type(of: self))
    }

    public func addChild(_ child: MDLObject) {
        if let previous = child.parent, previous !== self {
            if let container = previous.children as? MDLObjectContainer {
                container.remove(child)
            } else {
                previous.children.remove(child)
            }
        }
        child.parent = self
        children.add(child)
    }

    public func atPath(_ path: String) -> MDLObject {
        let trimmed = path.hasPrefix("/") ? String(path.dropFirst()) : path
        if trimmed.isEmpty { return self }
        var current: MDLObject = self
        for part in trimmed.split(separator: "/").map(String.init) {
            guard let next = current.children.objects.first(where: { object in
                let name = object.name.isEmpty ? object.defaultPathName() : object.name
                return name == part
            }) else {
                return current
            }
            current = next
        }
        return current
    }

    public func boundingBox(atTime time: TimeInterval) -> MDLAxisAlignedBoundingBox {
        var box = localBoundingBox(atTime: time)
        for child in children.objects where !child.hidden {
            box = MDLAxisAlignedBoundingBox.union(box, child.boundingBox(atTime: time))
        }
        return box
    }

    func localBoundingBox(atTime time: TimeInterval) -> MDLAxisAlignedBoundingBox {
        MDLAxisAlignedBoundingBox()
    }

    public func enumerateChildObjects(
        of objectClass: AnyClass,
        root: MDLObject,
        using block: @escaping (MDLObject, UnsafeMutablePointer<ObjCBool>) -> Void,
        stopPointer: UnsafeMutablePointer<ObjCBool>
    ) {
        func walk(_ node: MDLObject) {
            if stopPointer.pointee.boolValue { return }
            if node.isKind(of: objectClass) {
                block(node, stopPointer)
            }
            for child in node.children.objects {
                if stopPointer.pointee.boolValue { return }
                walk(child)
            }
        }
        walk(root)
    }
}
