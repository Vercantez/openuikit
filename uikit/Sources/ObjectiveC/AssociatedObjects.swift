// Linux ObjectiveC associated-object store for SnapKit 5.7.0.
//
// MEASURED SnapKit LayoutConstraintItem.swift:82 and ConstraintDSL.swift:42
// (pin e74fe2a, Focus a2832521): objc_getAssociatedObject /
// objc_setAssociatedObject with .OBJC_ASSOCIATION_RETAIN_NONATOMIC and
// .OBJC_ASSOCIATION_COPY_NONATOMIC. Darwin UIKit @_exported-imports the SDK
// ObjectiveC module (Sources/UIKitShim/UIKit.swift). Native ELF has no SDK
// ObjectiveC; this product is Linux-only so SnapKit's `import UIKit` sees
// the same names. Target name is OpenUIKitObjectiveC: a target named
// ObjectiveC made `canImport(ObjectiveC)` true in OpenUIKit and compiled
// `@objc` with interop disabled (MEASURED swift:6.2-noble openrender).
// Weak keys: a deallocated host drops its entry
// (prove_focus_onboarding_swiftui.sh GeneratedAssociationStore).

import Foundation

public enum objc_AssociationPolicy: UInt {
    case OBJC_ASSOCIATION_ASSIGN = 0
    case OBJC_ASSOCIATION_RETAIN_NONATOMIC = 1
    case OBJC_ASSOCIATION_COPY_NONATOMIC = 3
    case OBJC_ASSOCIATION_RETAIN = 01401
    case OBJC_ASSOCIATION_COPY = 01403
}

private final class AssociationEntry {
    weak var object: AnyObject?
    var values: [UInt: Any] = [:]
    init(object: AnyObject) { self.object = object }
}

private final class AssociationStore: @unchecked Sendable {
    static let shared = AssociationStore()
    let lock = NSLock()
    var entries: [ObjectIdentifier: AssociationEntry] = [:]
}

public func objc_getAssociatedObject(_ object: Any, _ key: UnsafeRawPointer) -> Any? {
    let object = object as AnyObject
    let identity = ObjectIdentifier(object)
    let key = UInt(bitPattern: key)
    let store = AssociationStore.shared
    store.lock.lock()
    defer { store.lock.unlock() }
    guard let entry = store.entries[identity], entry.object === object else {
        store.entries.removeValue(forKey: identity)
        return nil
    }
    return entry.values[key]
}

public func objc_setAssociatedObject(
    _ object: Any,
    _ key: UnsafeRawPointer,
    _ value: Any?,
    _ policy: objc_AssociationPolicy
) {
    _ = policy
    let object = object as AnyObject
    let identity = ObjectIdentifier(object)
    let key = UInt(bitPattern: key)
    let store = AssociationStore.shared
    store.lock.lock()
    defer { store.lock.unlock() }
    if value == nil {
        if let entry = store.entries[identity], entry.object === object {
            entry.values.removeValue(forKey: key)
            if entry.values.isEmpty {
                store.entries.removeValue(forKey: identity)
            }
        }
        return
    }
    let entry: AssociationEntry
    if let existing = store.entries[identity], existing.object === object {
        entry = existing
    } else {
        entry = AssociationEntry(object: object)
        store.entries[identity] = entry
    }
    entry.values[key] = value
}

public func objc_removeAssociatedObjects(_ object: Any) {
    let object = object as AnyObject
    let identity = ObjectIdentifier(object)
    let store = AssociationStore.shared
    store.lock.lock()
    defer { store.lock.unlock() }
    store.entries.removeValue(forKey: identity)
}
