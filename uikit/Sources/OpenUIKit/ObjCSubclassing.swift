// Objective-C subclasses of OpenUIKit classes (route b, Apple toolchain).
//
// An Objective-C class compiled by clang is a bare `objc_class` (five words);
// a Swift class object carries its Swift vtable after that header. Swift
// dispatches a non-final, non-`dynamic` member by loading a slot at a fixed
// offset from the receiver's isa, so on an instance of a statically emitted
// Objective-C subclass (`@interface SPTextView : UITextView`) that load reads
// past the class object: MEASURED probe1 (simplenote-launch3.md) crashed at
// `UIView.init()` on a null slot, and the objc_impl_spike's chain A crashed
// the same way one class further down.
//
// With OPENUIKIT_OBJC_SUBCLASSING the classes such apps subclass are compiled
// vtable-free: overridable members are `@objc dynamic` (Objective-C message
// dispatch, which works on any class object), everything else is `final`
// (static dispatch). Tests/OpenUIKitTests/ObjCSubclassingTests.swift reads
// each class's Swift type descriptor and fails if a class on the chain
// grows a vtable entry that is not on the documented allowlist below.
//
// The allowlist is members whose signature cannot be Objective-C (a Swift
// protocol with Swift-struct requirements). An Objective-C subclass cannot
// override them, so for such an instance the nearest Swift implementation is
// the correct one; OpenUIKit reaches them only through the `_…Dispatch`
// helpers, which consult `_hasSwiftVTable` first.

#if OPENUIKIT_OBJC_SUBCLASSING
import ObjectiveC

/// Classes already classified, keyed by class-object identity. Main-actor
/// state: every caller is a UIResponder member.
@MainActor private var _swiftVTableShapedCache: [ObjectIdentifier: Bool] = [:]

/// Swift stable-ABI class objects set bit 1 (legacy: bit 0) of the
/// `objc_class` data word (objc4 `FAST_IS_SWIFT_STABLE`/`_LEGACY`; the Swift
/// runtime's `ClassMetadata::isTypeMetadata()` reads the same bits).
@inline(__always)
private func _isSwiftClassObject(_ cls: AnyClass) -> Bool {
    let raw = unsafeBitCast(cls, to: UnsafeRawPointer.self)
    let data = raw.load(fromByteOffset: 4 * MemoryLayout<UInt>.size, as: UInt.self)
    return data & 0x3 != 0
}

/// True when every class from `object`'s class up to and including `base`
/// is a Swift class, i.e. the class object really carries `base`'s vtable.
@MainActor
func _hasSwiftVTable(_ object: AnyObject, through base: AnyClass) -> Bool {
    guard let start: AnyClass = object_getClass(object) else { return false }
    let key = ObjectIdentifier(start)
    if let known = _swiftVTableShapedCache[key] { return known }
    var cls: AnyClass? = start
    var shaped = false
    while let c = cls {
        if !_isSwiftClassObject(c) { break }
        if c === base { shaped = true; break }
        cls = class_getSuperclass(c)
    }
    _swiftVTableShapedCache[key] = shaped
    return shaped
}
#else
@MainActor @inline(__always)
func _hasSwiftVTable(_ object: AnyObject, through base: AnyClass) -> Bool { true }
#endif

/// A metatype through which an `@objc dynamic` CLASS member or initializer
/// can be sent to the object's real class.
///
/// For an instance of an Objective-C subclass, `type(of: self)` / `Self` is
/// an ObjCClassWrapper metadata, not the class object, yet Swift lowers a
/// class-member message on a metatype of a Swift class (`Self.layerClass`)
/// as if the metadata WERE the class object, and objc_msgSend then reads a
/// wrapper as a class (MEASURED scratch probe on macOS 26: `Self.k`,
/// `type(of: self).k` and `(object_getClass(self) as! A.Type).k` all
/// SIGSEGV at 0x310, i.e. wrapper kind 0x305 + 0x10 as a cache pointer).
/// Boxing the metatype as AnyObject goes through
/// swift_getObjCClassFromMetadata, which yields the class object for both
/// kinds; reinterpreting that as `T.Type` is valid for message sends only.
@inline(__always)
func _objcMessageable<T: AnyObject>(_ type: T.Type) -> T.Type {
#if OPENUIKIT_OBJC_SUBCLASSING
    unsafeBitCast(type as AnyObject, to: T.Type.self)
#else
    type
#endif
}

extension UIViewController {
    // The UIContentContainer members take Swift protocols
    // (UIContentContainer, UIViewControllerTransitionCoordinator) or the
    // UIInterfaceOrientationMask option set, so they keep vtable slots; an
    // Objective-C subclass cannot override them and gets UIViewController's
    // own behaviour.
    final func _preferredContentSizeDidChangeDispatch(forChildContentContainer container: UIContentContainer) {
        if _hasSwiftVTable(self, through: UIViewController.self) {
            preferredContentSizeDidChange(forChildContentContainer: container)
        }
    }

    final func _sizeDispatch(forChildContentContainer container: UIContentContainer,
                             withParentContainerSize parentSize: CGSize) -> CGSize {
        if _hasSwiftVTable(self, through: UIViewController.self) {
            return size(forChildContentContainer: container, withParentContainerSize: parentSize)
        }
        return parentSize
    }

    final func _viewWillTransitionDispatch(to size: CGSize,
                                           with coordinator: UIViewControllerTransitionCoordinator) {
        if _hasSwiftVTable(self, through: UIViewController.self) {
            viewWillTransition(to: size, with: coordinator)
        } else {
            _viewWillTransitionBase(to: size, with: coordinator)
        }
    }

    final func _willTransitionDispatch(to newCollection: UITraitCollection,
                                       with coordinator: UIViewControllerTransitionCoordinator) {
        if _hasSwiftVTable(self, through: UIViewController.self) {
            willTransition(to: newCollection, with: coordinator)
        } else {
            _willTransitionBase(to: newCollection, with: coordinator)
        }
    }

    final var _transitionCoordinatorDispatch: UIViewControllerTransitionCoordinator? {
        if _hasSwiftVTable(self, through: UIViewController.self) {
            return transitionCoordinator
        }
        return _transitionCoordinator ?? parent?._transitionCoordinatorDispatch
    }

    final var _supportedInterfaceOrientationsDispatch: UIInterfaceOrientationMask {
        if _hasSwiftVTable(self, through: UIViewController.self) {
            return supportedInterfaceOrientations
        }
        return _baseSupportedInterfaceOrientations
    }
}

extension UIResponder {
    /// `buildMenu(with:)` keeps a vtable slot (see its declaration). For an
    /// Objective-C subclass instance the slot is absent and no override can
    /// exist, so UIResponder's own (empty) default is what UIKit would run.
    final func _buildMenuDispatch(with builder: UIMenuBuilder) {
        if _hasSwiftVTable(self, through: UIResponder.self) {
            buildMenu(with: builder)
        }
    }
}
