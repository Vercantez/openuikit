// LaunchByName.swift -- launching an app the way a real iOS binary does:
// by the NAME of the delegate class, not by an instance of it.
//
// WHAT REAL UIKIT DOES. `@main` on a UIApplicationDelegate synthesises
//
//     UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv,
//                       nil, NSStringFromClass(AppDelegate.self))
//
// so the delegate crosses the boundary as a STRING. UIKit then does
// NSClassFromString on it, `[[cls alloc] init]`, and installs the result.
// Nothing but the string is passed; the app never hands UIKit an object.
//
// OpenUIKit's entry point takes the object instead
// (`UIApplicationMain(delegate: MyAppDelegate())`), which is the whole gap
// this file measures and then closes.
//
// TWO RUNTIMES COULD ANSWER "what class is named X", AND ONLY ONE DOES.
// The obvious answer is objc4 -- we have it, it is what UIKit uses, and the
// binary really does carry an __objc_classlist. But OpenUIKit's classes are
// NOT NSObject subclasses and carry no @objc (Sources/OpenUIKit/UISelector.swift
// states this as a design rule), so what ObjC knows about them is decided by
// the Swift compiler's Darwin class emission, not by our intent. That is a
// measurement, and `objcRuntimeSurvey()` below takes it rather than assuming.
//
// The Swift runtime's own answer -- `_typeByName` over the __swift5_types
// records -- is the one this file builds on, because it is the one that does
// not depend on a class being ObjC-shaped.
//
// INSTANTIATION IS A SEPARATE PROBLEM FROM DISCOVERY, and it is where the
// missing NSObject actually bites. `[[cls alloc] init]` works in real UIKit
// because UIApplicationDelegate refines NSObjectProtocol, so every conforming
// class necessarily HAS an `init`. A Swift metatype gives you no way to call
// an initialiser that no protocol requires. The portable equivalent of what
// NSObject supplies for free is to REQUIRE it, which is what
// `InstantiableAppDelegate` does here -- see its comment for the two-line
// change to ~/uikit that would let real app source use it unmodified.
//
// Do NOT read `alloc` without `init` as a way around that: SwiftObject's
// +alloc reaches swift_allocObject with the right size, and then the Swift
// initialiser body never runs, so every stored property holds whatever the
// allocator left there. It would "work" on a delegate whose properties are
// all Optional and be silently wrong on any other -- exactly the false-green
// shape this project keeps finding.

import CHostClock
import OpenUIKit

// MARK: - The ObjC runtime, asked directly

@_silgen_name("objc_getClass")
private func objc_getClass(_ name: UnsafePointer<CChar>) -> UnsafeMutableRawPointer?
@_silgen_name("objc_getClassList")
private func objc_getClassList(_ buffer: UnsafeMutablePointer<UnsafeMutableRawPointer?>?,
                               _ count: Int32) -> Int32
@_silgen_name("class_getName")
private func class_getName(_ cls: UnsafeMutableRawPointer) -> UnsafePointer<CChar>

/// The ObjC mangled name of a Swift class -- what `NSStringFromClass` returns
/// on Darwin and therefore what a real `@main` hands to `UIApplicationMain`.
/// `_TtC` + module + class, each length-prefixed.
func objcMangledName(module: String, cls: String) -> String {
    "_TtC\(module.utf8.count)\(module)\(cls.utf8.count)\(cls)"
}

/// Does objc4 know about the Swift classes in this image? Reported rather
/// than assumed, because the answer decides whether the faithful UIKit
/// mechanism is available to us at all.
@MainActor
func objcRuntimeSurvey() -> (registered: Int, foundUIView: Bool, foundDelegate: Bool) {
    let total = Int(objc_getClassList(nil, 0))
    let uiview = objcMangledName(module: "OpenUIKit", cls: "UIView")
    let del = objcMangledName(module: "render_full", cls: "ProbeAppDelegate")
    let a = uiview.withCString { objc_getClass($0) } != nil
    let b = del.withCString { objc_getClass($0) } != nil
    print("  objc4      : registered classes=\(total)"
        + "  objc_getClass(\"\(uiview)\")=\(a ? "FOUND" : "nil")"
        + "  objc_getClass(\"\(del)\")=\(b ? "FOUND" : "nil")")
    return (total, a, b)
}

// MARK: - The Swift runtime, asked directly

/// `NSStringFromClass`'s portable counterpart: the mangled name of a type,
/// which is the string an app would pass to `UIApplicationMain`.
func mangledName(of type: Any.Type) -> String? { _mangledTypeName(type) }

/// `NSClassFromString`'s portable counterpart -- the raw one, which is what
/// the self-test measures per name form.
func typeByName(_ name: String) -> Any.Type? { _typeByName(name) }

/// `_TtC9MyModule11AppDelegate` -> `9MyModule11AppDelegateC`.
///
/// MEASURED, NOT ASSUMED: `_typeByName` accepts the Swift mangling and the
/// qualified source name and REJECTS the `_TtC` form -- and the `_TtC` form is
/// precisely what `NSStringFromClass` produces and therefore what a real
/// `@main` hands to `UIApplicationMain`. Without this the faithful spelling is
/// the one spelling that does not work. Both forms carry the same
/// length-prefixed components, so the conversion is a re-spelling and not a
/// guess. Anything more elaborate than module + class (nested or generic
/// types) returns nil rather than a wrong answer; an app delegate is neither.
func swiftMangling(fromObjCClassName name: String) -> String? {
    guard name.hasPrefix("_TtC") else { return nil }
    var rest = Substring(name.dropFirst(4))
    var parts: [String] = []
    while !rest.isEmpty {
        let digits = rest.prefix(while: { $0.isASCII && $0.isNumber })
        guard let n = Int(digits), n > 0 else { return nil }
        rest = rest.dropFirst(digits.count)
        guard rest.count >= n else { return nil }
        parts.append(String(rest.prefix(n)))
        rest = rest.dropFirst(n)
    }
    guard parts.count == 2 else { return nil }
    return "\(parts[0].utf8.count)\(parts[0])\(parts[1].utf8.count)\(parts[1])C"
}

/// What `UIApplicationMain` actually calls: the Swift runtime's answer, and
/// failing that the same question asked in the spelling it understands.
func resolveClass(named name: String) -> Any.Type? {
    if let t = _typeByName(name) { return t }
    if let swiftForm = swiftMangling(fromObjCClassName: name) { return _typeByName(swiftForm) }
    return nil
}

// MARK: - What NSObject supplies for free

/// `UIApplicationDelegate` NOW CARRIES `init()` ITSELF (~/uikit branch
/// appcompat/delegate-init), so this alias is all that remains of the local
/// stand-in. Real UIKit gets the same requirement from NSObjectProtocol.
///
/// THE OTHER DESIGN WAS MEASURED AND REJECTED. Making `UIResponder.init()`
/// `required` would let a delegate INHERIT the requirement and cost app source
/// nothing -- but `required` propagates to every UIResponder subclass that
/// declares its own designated initialiser, which in OpenUIKit is 14 sites in
/// 14 files. Worse than the count: six are UIView subclasses that would have to
/// GAIN a parameterless `init()`, and real UIKit's UIView has none (its
/// designated initialisers are `init(frame:)` and `init(coder:)`). A change
/// justified as matching UIKit would have made the library less like UIKit.
/// The protocol requirement alone costs ZERO library edits.
///
/// WHAT IT COSTS AN APP, measured not assumed -- see the two probe delegates in
/// LaunchTest.swift: a `final` delegate satisfies `init()` with no extra
/// syntax; a NON-final one needs its initialiser spelled `required`. One line,
/// in the app, only for non-final delegates.
typealias InstantiableAppDelegate = UIApplicationDelegate

// MARK: - UIApplicationMain, by name

enum LaunchFailure: Error, CustomStringConvertible {
    case noDelegateName
    case unknownClass(String)
    case notADelegate(String)
    case unsupportedPrincipalClass(String)

    var description: String {
        switch self {
        case .noDelegateName:
            return "no delegate class name (UIKit would read Info.plist here; we have no bundle yet)"
        case .unknownClass(let n):
            return "no class named \"\(n)\" in this image"
        case .notADelegate(let n):
            return "class \"\(n)\" exists but does not conform to an instantiable UIApplicationDelegate"
        case .unsupportedPrincipalClass(let n):
            return "principal class \"\(n)\" is not UIApplication; OpenUIKit's UIApplication.shared is a singleton `let`"
        }
    }
}

/// UIKit's four-argument entry point. Takes the delegate as a STRING, which is
/// the only thing a real `@main` ever passes.
///
/// Returns the launched application, or the reason it could not launch. It does
/// NOT spin the loop itself -- `UIKitRunLoop` is a separate, host-supplied
/// thing, and keeping them apart is what lets CFRunLoop drive the loop later
/// (see RunLoop.swift) without also owning process launch.
@MainActor
func UIApplicationMain(principalClassName: String?,
                       delegateClassName: String?) -> Result<UIApplication, LaunchFailure> {
    if let p = principalClassName, p != "UIApplication",
       p != objcMangledName(module: "OpenUIKit", cls: "UIApplication"),
       p != "OpenUIKit.UIApplication" {
        return .failure(.unsupportedPrincipalClass(p))
    }
    guard let name = delegateClassName else { return .failure(.noDelegateName) }
    guard let type = resolveClass(named: name) else { return .failure(.unknownClass(name)) }
    guard let delegateType = type as? InstantiableAppDelegate.Type else {
        return .failure(.notADelegate(name))
    }
    let app = UIApplication.shared
    _ = app._hostLaunch(delegate: delegateType.init())
    return .success(app)
}
