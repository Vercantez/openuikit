import UIKit
// firefox-ios' last two blocking rows: UIMenuBuilder (AppDelegate.buildMenu
// override + MenuBuilderHelper's insert/replace/remove sequence) and
// UICommandAlternate (one .shift alternate on the Cmd-T key command).
//
// Every `mark` rewrites the JSON, so a crash keeps everything before it.
// Timeline is relative to the process start (`t`); the host-side key sender
// logs epoch seconds (`epoch`) so presses and fires can be lined up.
var rows: [String: Any] = [:]
var events: [[String: Any]] = []
var seq = 0
var phase = "preMain"
let t0 = Date()
let edgeMode = CommandLine.arguments.contains("--edge")
func save() {
 let data = try! JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted, .sortedKeys])
 try! data.write(to: URL(fileURLWithPath: NSHomeDirectory() + "/Documents/firefoxlastrows.json"))
}
func mark(_ what: String, _ extra: [String: Any] = [:]) {
 seq += 1
 var e: [String: Any] = ["seq": seq, "phase": phase, "what": what,
                         "t": Date().timeIntervalSince(t0), "epoch": Date().timeIntervalSince1970]
 for (k, v) in extra { e[k] = v }
 events.append(e); rows["events"] = events; save()
}
func touch(_ name: String) { FileManager.default.createFile(atPath: NSHomeDirectory() + "/Documents/" + name, contents: Data()) }

func altRow(_ a: UICommandAlternate) -> [String: Any] {
 ["title": a.title, "action": NSStringFromSelector(a.action), "modifierFlags": a.modifierFlags.rawValue]
}
func elementRow(_ e: UIMenuElement, depth: Int = 0) -> [String: Any] {
 var r: [String: Any] = ["class": NSStringFromClass(type(of: e)), "title": e.title, "depth": depth]
 if let m = e as? UIMenu {
  r["identifier"] = m.identifier.rawValue; r["options"] = m.options.rawValue
  r["children"] = m.children.map { elementRow($0, depth: depth + 1) }
 }
 if let c = e as? UICommand {
  r["action"] = NSStringFromSelector(c.action)
  r["propertyList"] = c.propertyList.map { String(describing: $0) } ?? "nil"
  r["discoverabilityTitle"] = c.discoverabilityTitle ?? "nil"
  r["attributes"] = c.attributes.rawValue; r["state"] = c.state.rawValue
  r["alternates"] = c.alternates.map(altRow)
 }
 if let k = e as? UIKeyCommand {
  r["input"] = k.input ?? "nil"; r["modifierFlags"] = k.modifierFlags.rawValue
  r["wantsPriority"] = k.wantsPriorityOverSystemBehavior
 }
 if let a = e as? UIAction { r["identifier"] = a.identifier.rawValue; r["attributes"] = a.attributes.rawValue; r["state"] = a.state.rawValue }
 if e is UIDeferredMenuElement { r["deferred"] = true }
 return r
}
func senderRow(_ s: Any?) -> [String: Any] {
 guard let s else { return ["class": "nil"] }
 var r: [String: Any] = ["class": NSStringFromClass(type(of: s as AnyObject))]
 if let k = s as? UIKeyCommand { r["input"] = k.input ?? "nil"; r["modifierFlags"] = k.modifierFlags.rawValue; r["title"] = k.title; r["action"] = k.action.map { NSStringFromSelector($0) } ?? "nil"; r["alternates"] = k.alternates.count }
 else if let c = s as? UICommand { r["title"] = c.title; r["action"] = NSStringFromSelector(c.action) }
 else if let a = s as? UICommandAlternate { r["title"] = a.title; r["modifierFlags"] = a.modifierFlags.rawValue }
 return r
}

let ids: [(String, UIMenu.Identifier)] = [
 ("root", .root), ("application", .application), ("file", .file), ("edit", .edit), ("view", .view),
 ("window", .window), ("help", .help), ("about", .about), ("preferences", .preferences),
 ("services", .services), ("hide", .hide), ("quit", .quit), ("newItem", .newItem), ("newScene", .newScene),
 ("open", .open), ("openRecent", .openRecent), ("close", .close), ("print", .print), ("document", .document),
 ("undoRedo", .undoRedo), ("standardEdit", .standardEdit), ("find", .find), ("findPanel", .findPanel),
 ("replace", .replace), ("share", .share), ("textStyle", .textStyle), ("spelling", .spelling),
 ("spellingPanel", .spellingPanel), ("spellingOptions", .spellingOptions), ("substitutions", .substitutions),
 ("substitutionsPanel", .substitutionsPanel), ("substitutionOptions", .substitutionOptions),
 ("transformations", .transformations), ("speech", .speech), ("lookup", .lookup), ("learn", .learn),
 ("format", .format), ("autoFill", .autoFill), ("font", .font), ("textSize", .textSize),
 ("textColor", .textColor), ("textStylePasteboard", .textStylePasteboard), ("text", .text),
 ("writingDirection", .writingDirection), ("alignment", .alignment), ("toolbar", .toolbar),
 ("sidebar", .sidebar), ("fullscreen", .fullscreen), ("minimizeAndZoom", .minimizeAndZoom),
 ("bringAllToFront", .bringAllToFront),
]
func presence(_ b: UIMenuBuilder) -> [String: Any] {
 var out: [String: Any] = [:]
 for (n, id) in ids { out[n] = b.menu(for: id).map { ["title": $0.title, "children": $0.children.count, "options": $0.options.rawValue] } ?? "nil" }
 return out
}
func topLevel(_ b: UIMenuBuilder) -> [String] {
 (b.menu(for: .root)?.children ?? []).map { ($0 as? UIMenu)?.identifier.rawValue ?? ("<" + NSStringFromClass(type(of: $0)) + ">") }
}
func childIds(_ b: UIMenuBuilder, _ id: UIMenu.Identifier) -> Any {
 guard let m = b.menu(for: id) else { return "nil" }
 return m.children.map { ($0 as? UIMenu)?.identifier.rawValue ?? ("<" + NSStringFromClass(type(of: $0)) + ":" + $0.title + ">") }
}

/// GraphicsServices' hardware-keyboard flag — the condition the launch-time
/// main-menu build turned out to depend on (see README).
func hardwareKeyboardAttached() -> Any {
 guard let h = dlopen("/System/Library/PrivateFrameworks/GraphicsServices.framework/GraphicsServices", RTLD_NOW),
       let sym = dlsym(h, "GSEventIsHardwareKeyboardAttached") else { return "unavailable" }
 typealias F = @convention(c) () -> Bool
 return unsafeBitCast(sym, to: F.self)()
}
var mainBuildCount = 0
var contextBuildCount = 0
var vcCallsSuper = true
var keyPhase = "none"
var keyCommandsQueries = 0
var currentPress = "none"
weak var probeWindow: UIWindow?

/// Hardware-key injection through UIKit's own physical-keyboard event class.
/// The Simulator's host route (System Events keystrokes) delivered nothing
/// on this Mac — Simulator.app had no device window and its hardware
/// keyboard is disconnected — so the press is built the way UIKit's own
/// keyboard path builds it and handed to the PUBLIC `sendEvent(_:)` (and,
/// for comparison, the private key handlers). Every event's readback is
/// recorded so the transcript shows what was actually dispatched.
enum KeyInjector {
 static let cls: AnyClass? = NSClassFromString("UIPhysicalKeyboardEvent")
 /// HID keyboard usages (USB HID usage table 0x07) for the letters used.
 static let hidUsage: [String: Int] = ["j": 0x0D, "t": 0x17, "p": 0x13, "w": 0x1A, ",": 0x36]
 static func make(_ input: String, _ flags: UIKeyModifierFlags, inputFlags: Int, keyCode: Bool = true) -> UIEvent? {
  let sel = NSSelectorFromString("_eventWithInput:inputFlags:")
  guard let cls, let m = class_getClassMethod(cls, sel) else { return nil }
  typealias F = @convention(c) (AnyClass, Selector, NSString, Int) -> UIEvent?
  guard let ev = unsafeBitCast(method_getImplementation(m), to: F.self)(cls, sel, input as NSString, inputFlags) else { return nil }
  let ssel = NSSelectorFromString("_setModifierFlags:")
  if let sm = class_getInstanceMethod(cls, ssel) {
   typealias S = @convention(c) (AnyObject, Selector, Int) -> Void
   unsafeBitCast(method_getImplementation(sm), to: S.self)(ev, ssel, flags.rawValue)
  }
  let ksel = NSSelectorFromString("set_keyCode:")
  if keyCode, let code = hidUsage[input], let km = class_getInstanceMethod(cls, ksel) {
   typealias K = @convention(c) (AnyObject, Selector, Int) -> Void
   unsafeBitCast(method_getImplementation(km), to: K.self)(ev, ksel, code)
  }
  return ev
 }
 static func describe(_ ev: UIEvent) -> [String: Any] {
  var r: [String: Any] = ["class": NSStringFromClass(type(of: ev)), "type": ev.type.rawValue]
  for name in ["_isKeyDown", "_modifierFlags", "modifierFlags", "_isPhysicalKeyEvent", "_unmodifiedInput", "_modifiedInput", "_inputFlags", "_keyCode", "_isARepeat"] {
   if ev.responds(to: NSSelectorFromString(name)) { r[name] = ev.value(forKey: name).map { "\($0)" } ?? "nil" }
  }
  return r
 }
 /// IOKit's keyboard HID event, attached the way the real keyboard path
 /// attaches it (`_setHIDEvent:keyboard:`), so `_keyCode` is a real usage.
 static func attachHID(_ ev: UIEvent, input: String, down: Bool) -> Bool {
  guard let usage = hidUsage[input], let h = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW),
        let sym = dlsym(h, "IOHIDEventCreateKeyboardEvent") else { return false }
  typealias Create = @convention(c) (CFAllocator?, UInt64, UInt32, UInt32, Bool, UInt32) -> Unmanaged<CFTypeRef>?
  guard let hid = unsafeBitCast(sym, to: Create.self)(nil, mach_absolute_time(), 7, UInt32(usage), down, 0) else { return false }
  let sel = NSSelectorFromString("_setHIDEvent:keyboard:")
  guard let cls, let m = class_getInstanceMethod(cls, sel) else { return false }
  typealias S = @convention(c) (AnyObject, Selector, CFTypeRef?, AnyObject?) -> Void
  unsafeBitCast(method_getImplementation(m), to: S.self)(ev, sel, hid.takeUnretainedValue(), nil)
  return true
 }
 static func dispatch(_ ev: UIEvent, route: String) -> [String: Any] {
  var r: [String: Any] = [:]
  switch route {
  case "sendEvent": UIApplication.shared.sendEvent(ev)
  case "shortcutInvocation":
   // UIKit's own resolution step (UIResponder) followed by its perform step (UIApplication).
   let start: UIResponder = (probeWindow?.rootViewController) ?? UIApplication.shared
   let isel = NSSelectorFromString("_keyboardShortcutInvocationForKeyboardEvent:")
   guard let im = class_getInstanceMethod(UIResponder.self, isel) else { r["unavailable"] = "invocation"; return r }
   typealias I = @convention(c) (AnyObject, Selector, AnyObject) -> AnyObject?
   let inv = unsafeBitCast(method_getImplementation(im), to: I.self)(start, isel, ev)
   r["invocation"] = inv.map { "\($0)" } ?? "nil"
   r["invocationClass"] = inv.map { NSStringFromClass(type(of: $0)) } ?? "nil"
   if let inv {
    let psel = NSSelectorFromString("_performKeyboardShortcutInvocation:allowsRepeat:")
    if let pm = class_getInstanceMethod(UIApplication.self, psel) {
     typealias P = @convention(c) (AnyObject, Selector, AnyObject, Bool) -> Bool
     r["performed"] = unsafeBitCast(method_getImplementation(pm), to: P.self)(UIApplication.shared, psel, inv, false)
    }
   }
  case "handleShortcut":
   let hsel = NSSelectorFromString("_handleKeyboardShortcutForKeyboardEvent:allowsRepeat:")
   guard let hm = class_getInstanceMethod(UIApplication.self, hsel) else { r["unavailable"] = "handleShortcut"; return r }
   typealias H = @convention(c) (AnyObject, Selector, AnyObject, Bool) -> Bool
   r["handled"] = unsafeBitCast(method_getImplementation(hm), to: H.self)(UIApplication.shared, hsel, ev, false)
  default: _ = UIApplication.shared.perform(NSSelectorFromString(route), with: ev)
  }
  return r
 }
 static func press(_ label: String, _ input: String, _ flags: UIKeyModifierFlags, route: String, hid: Bool) {
  currentPress = "\(keyPhase)/\(route)/\(label)/hid=\(hid)"
  let before = keyCommandsQueries
  guard let down = make(input, flags, inputFlags: 0, keyCode: false) else { mark("press.unavailable", ["label": label]); return }
  var hidOK = false
  if hid { hidOK = attachHID(down, input: input, down: true) }
  mark("press.begin", ["label": label, "route": route, "hid": hidOK, "event": describe(down), "flags": flags.rawValue, "input": input])
  let result = dispatch(down, route: route)
  mark("press.end", ["label": label, "route": route, "hid": hidOK, "keyCommandsQueries": keyCommandsQueries - before, "result": result])
  currentPress = "none"
 }
}

let hist = UIMenu.Identifier("com.mozilla.firefox.menus.history")
let bmk = UIMenu.Identifier("com.mozilla.firefox.menus.bookmarks")
let tools = UIMenu.Identifier("com.mozilla.firefox.menus.tools")

/// The firefox MenuBuilderHelper sequence, verbatim shape, our selectors.
func firefoxSequence(_ builder: UIMenuBuilder, into key: String) {
 var steps: [[String: Any]] = []
 func step(_ name: String, _ body: () -> Void) {
  body()
  steps.append(["step": name, "root": topLevel(builder), "application": childIds(builder, .application),
                "file": childIds(builder, .file), "view": childIds(builder, .view), "window": childIds(builder, .window),
                "find": builder.menu(for: .find).map { $0.identifier.rawValue } ?? "nil",
                "font": builder.menu(for: .font).map { $0.identifier.rawValue } ?? "nil",
                "edit": childIds(builder, .edit)])
  rows[key] = steps; save()
 }
 let newPrivateTab = UICommandAlternate(title: "New Private Tab", action: #selector(RootVC.newPrivateTabKeyCommand), modifierFlags: [.shift])
 let appMenu = UIMenu(options: .displayInline, children: [
  UIKeyCommand(title: "Settings", action: #selector(RootVC.openSettingsKeyCommand), input: ",", modifierFlags: [.command, .alternate], discoverabilityTitle: "Settings")])
 let fileMenu = UIMenu(options: .displayInline, children: [
  UIKeyCommand(title: "New Tab", action: #selector(RootVC.newTabKeyCommand), input: "t", modifierFlags: .command, alternates: [newPrivateTab], discoverabilityTitle: "New Tab"),
  UIKeyCommand(title: "New Private Tab", action: #selector(RootVC.newPrivateTabKeyCommand), input: "p", modifierFlags: [.command, .shift], discoverabilityTitle: "New Private Tab"),
  UIKeyCommand(title: "Close Tab", action: #selector(RootVC.closeTabKeyCommand), input: "w", modifierFlags: .command, discoverabilityTitle: "Close Tab")])
 fileMenu.children.forEach { ($0 as? UIKeyCommand)?.wantsPriorityOverSystemBehavior = true }
 let findMenu = UIMenu(options: .displayInline, children: [
  UIKeyCommand(title: "Find", action: #selector(RootVC.findInPageKeyCommand), input: "f", modifierFlags: .command, discoverabilityTitle: "Find")])
 let viewMenu = UIMenu(options: .displayInline, children: [
  UIKeyCommand(title: "Reload", action: #selector(RootVC.reloadTabKeyCommand), input: "r", modifierFlags: .command, discoverabilityTitle: "Reload"),
  UIKeyCommand(title: "Reload Without Cache", action: #selector(RootVC.reloadTabIgnoringCacheKeyCommand), input: UIKeyCommand.f5, modifierFlags: [.control], discoverabilityTitle: "Reload Without Cache")])
 let historyMenu = UIMenu(title: "History", identifier: hist, options: .displayInline, children: [
  UIKeyCommand(title: "Back", action: #selector(RootVC.goBackKeyCommand), input: "[", modifierFlags: .command, discoverabilityTitle: "Back")])
 let bookmarksMenu = UIMenu(title: "Bookmarks", identifier: bmk, options: .displayInline, children: [
  UIKeyCommand(title: "Add Bookmark", action: #selector(RootVC.addBookmarkKeyCommand), input: "d", modifierFlags: .command, discoverabilityTitle: "Add Bookmark")])
 let toolsMenu = UIMenu(title: "Tools", identifier: tools, options: .displayInline, children: [
  UIKeyCommand(title: "Downloads", action: #selector(RootVC.showDownloadsKeyCommand), input: "j", modifierFlags: .command, discoverabilityTitle: "Downloads")])
 let windowMenu = UIMenu(title: "Window", options: .displayInline, children: [
  UIKeyCommand(title: "Next Tab", action: #selector(RootVC.nextTabKeyCommand), input: "\t", modifierFlags: [.control], discoverabilityTitle: "Next Tab"),
  UIKeyCommand(action: #selector(RootVC.selectFirstTab), input: "1", modifierFlags: .command, discoverabilityTitle: "First Tab")])
 let probeAction = UIAction(title: "Probe Action", identifier: UIAction.Identifier("com.openuikit.probe.action")) { _ in }
 rows["model.autoIdentifier"] = [appMenu.identifier.rawValue, fileMenu.identifier.rawValue, windowMenu.identifier.rawValue, UIMenu(title: "Titled").identifier.rawValue, UIMenu().identifier.rawValue]
 step("0.before") {}
 step("1.insertChild(app,atStartOf:.application)") { builder.insertChild(appMenu, atStartOfMenu: .application) }
 step("2.insertChild(file,atStartOf:.file)") { builder.insertChild(fileMenu, atStartOfMenu: .file) }
 step("3.replace(.find,with:findMenu)") { builder.replace(menu: .find, with: findMenu) }
 step("4.remove(.font)") { builder.remove(menu: .font) }
 step("5.insertChild(view,atStartOf:.view)") { builder.insertChild(viewMenu, atStartOfMenu: .view) }
 step("6.insertSibling(history,after:.view)") { builder.insertSibling(historyMenu, afterMenu: .view) }
 step("7.insertSibling(bookmarks,after:history)") { builder.insertSibling(bookmarksMenu, afterMenu: hist) }
 step("8.insertSibling(tools,after:bookmarks)") { builder.insertSibling(toolsMenu, afterMenu: bmk) }
 step("9.insertChild(window,atStartOf:.window)") { builder.insertChild(windowMenu, atStartOfMenu: .window) }
 step("10.insertChild(probeAction menu,atEndOf:.help)") { builder.insertChild(UIMenu(title: "Probe", identifier: UIMenu.Identifier("com.openuikit.probe.menu"), options: .displayInline, children: [probeAction]), atEndOfMenu: .help) }
 var lk: [String: Any] = [:]
 lk["menu(find).identifier"] = builder.menu(for: .find).map { $0.identifier.rawValue } ?? "nil"
 lk["menu(find) === findMenu"] = builder.menu(for: .find) === findMenu
 lk["menu(findMenu.identifier)"] = builder.menu(for: findMenu.identifier).map { $0.title } ?? "nil"
 lk["menu(font)"] = builder.menu(for: .font).map { $0.identifier.rawValue } ?? "nil"
 lk["menu(history) === historyMenu"] = builder.menu(for: hist) === historyMenu
 lk["menu(fileMenu.autoId) === fileMenu"] = builder.menu(for: fileMenu.identifier) === fileMenu
 if let c = builder.command(for: #selector(RootVC.newTabKeyCommand)) { lk["command(newTab)"] = ["title": c.title, "class": NSStringFromClass(type(of: c))] } else { lk["command(newTab)"] = "nil" }
 if let c = builder.command(for: #selector(RootVC.newPrivateTabKeyCommand)) { lk["command(newPrivateTab)"] = ["title": c.title, "input": (c as? UIKeyCommand)?.input ?? "nil"] } else { lk["command(newPrivateTab)"] = "nil" }
 lk["command(reloadTab,propertyList:nil)"] = builder.command(for: #selector(RootVC.reloadTabKeyCommand), propertyList: nil).map { $0.title } ?? "nil"
 lk["command(unknownSel)"] = builder.command(for: #selector(RootVC.neverInAMenu)).map { $0.title } ?? "nil"
 if let c = builder.command(for: Selector(("cut:"))) { lk["command(cut:)"] = ["title": c.title, "class": NSStringFromClass(type(of: c))] } else { lk["command(cut:)"] = "nil" }
 lk["action(probe)"] = builder.action(for: UIAction.Identifier("com.openuikit.probe.action")).map { $0.title } ?? "nil"
 lk["action(unknown)"] = builder.action(for: UIAction.Identifier("com.openuikit.nope")).map { $0.title } ?? "nil"
 if let r = builder.menu(for: .root) { lk["menu(root)"] = ["identifier": r.identifier.rawValue, "title": r.title, "class": NSStringFromClass(type(of: r))] } else { lk["menu(root)"] = "nil" }
 rows[key + ".lookups"] = lk
 rows[key + ".after.root"] = builder.menu(for: .root).map { elementRow($0) } ?? "nil"
 rows[key + ".after.presence"] = presence(builder)
 save()
}

/// Edge cases, each saved before it runs so a trap leaves the last reached step.
func edgeSequence(_ builder: UIMenuBuilder) {
 var steps: [[String: Any]] = []
 func step(_ name: String, _ body: () -> Void) {
  rows["edge.reached"] = name; save()
  body()
  steps.append(["step": name, "root": topLevel(builder), "file": childIds(builder, .file)])
  rows["edge.steps"] = steps; save()
 }
 let missing = UIMenu.Identifier("com.openuikit.missing")
 step("0.before") {}
 step("1.remove(missing)") { builder.remove(menu: missing) }
 step("2.remove(missing again)") { builder.remove(menu: missing) }
 step("3.replace(.find, twice: second replace by original id)") {
  builder.replace(menu: .find, with: UIMenu(title: "F1", options: .displayInline))
  builder.replace(menu: .find, with: UIMenu(title: "F2", options: .displayInline))
 }
 step("4.remove(.file) then menu(for:.file)") { builder.remove(menu: .file); rows["edge.fileAfterRemove"] = builder.menu(for: .file).map { $0.title } ?? "nil"; save() }
 step("5.insertChild(dup identifier)") {
  builder.insertChild(UIMenu(title: "D1", identifier: UIMenu.Identifier("com.openuikit.dup"), options: .displayInline), atStartOfMenu: .edit)
  builder.insertChild(UIMenu(title: "D2", identifier: UIMenu.Identifier("com.openuikit.dup"), options: .displayInline), atEndOfMenu: .edit)
 }
 step("6.insertSibling(after: missing)") { builder.insertSibling(UIMenu(title: "S", options: .displayInline), afterMenu: missing) }
 step("7.insertChild(atStartOf: missing)") { builder.insertChild(UIMenu(title: "C", options: .displayInline), atStartOfMenu: missing) }
 step("8.replace(missing)") { builder.replace(menu: missing, with: UIMenu(title: "R", options: .displayInline)) }
 step("9.insertChild(same menu object twice)") {
  let m = UIMenu(title: "Twice", options: .displayInline)
  builder.insertChild(m, atStartOfMenu: .view); builder.insertChild(m, atEndOfMenu: .window)
 }
 rows["edge.done"] = true; save()
}

func logBuild(_ who: String, _ builder: UIMenuBuilder, callsSuper: Bool) {
 let sys = builder.system === UIMenuSystem.main ? "main" : (builder.system === UIMenuSystem.context ? "context" : NSStringFromClass(type(of: builder.system)))
 mark("buildMenu", ["who": who, "system": sys, "callsSuper": callsSuper, "builderClass": NSStringFromClass(type(of: builder as AnyObject)),
                    "textFieldIsFirstResponder": (probeWindow?.rootViewController as? RootVC)?.tf.isFirstResponder ?? false,
                    "keyWindow": probeWindow?.isKeyWindow ?? false])
}
func logValidate(_ who: String, _ c: UICommand) {
 mark("validate", ["who": who, "command": elementRow(c)])
}

final class MyApp: UIApplication {
 override func buildMenu(with builder: UIMenuBuilder) { logBuild("UIApplication", builder, callsSuper: true); super.buildMenu(with: builder) }
 override func validate(_ command: UICommand) { logValidate("UIApplication", command); super.validate(command) }
}
final class Win: UIWindow {
 override func buildMenu(with builder: UIMenuBuilder) { logBuild("UIWindow", builder, callsSuper: true); super.buildMenu(with: builder) }
 override func validate(_ command: UICommand) { logValidate("UIWindow", command); super.validate(command) }
}
final class RootView: UIView {
 override func buildMenu(with builder: UIMenuBuilder) { logBuild("RootView", builder, callsSuper: true); super.buildMenu(with: builder) }
 override func validate(_ command: UICommand) { logValidate("RootView", command); super.validate(command) }
}
final class TF: UITextField {
 override func buildMenu(with builder: UIMenuBuilder) { logBuild("UITextField", builder, callsSuper: true); super.buildMenu(with: builder) }
 override func validate(_ command: UICommand) { logValidate("UITextField", command); super.validate(command) }
}
final class EditDelegate: NSObject, UIEditMenuInteractionDelegate {
 func editMenuInteraction(_ interaction: UIEditMenuInteraction, menuFor configuration: UIEditMenuConfiguration, suggestedActions: [UIMenuElement]) -> UIMenu? {
  mark("editMenu.menuFor", ["suggested": suggestedActions.map { elementRow($0) }])
  return UIMenu(children: [UIAction(title: "Probe Edit") { _ in }] + suggestedActions)
 }
}
final class RootVC: UIViewController {
 let tf = TF(frame: CGRect(x: 20, y: 200, width: 300, height: 40))
 let editDelegate = EditDelegate()
 var edit: UIEditMenuInteraction?
 override func loadView() { view = RootView(); view.backgroundColor = .white }
 override func viewDidLoad() {
  super.viewDidLoad()
  tf.borderStyle = .roundedRect; tf.text = "hello"; view.addSubview(tf)
  let i = UIEditMenuInteraction(delegate: editDelegate); view.addInteraction(i); edit = i
 }
 override func buildMenu(with builder: UIMenuBuilder) {
  logBuild("RootVC", builder, callsSuper: vcCallsSuper)
  if vcCallsSuper { super.buildMenu(with: builder) }
 }
 override func validate(_ command: UICommand) { logValidate("RootVC", command); super.validate(command) }

 override var keyCommands: [UIKeyCommand]? {
  let base = UIKeyCommand(title: "Base", action: #selector(fireBase(_:)), input: "j", modifierFlags: .command,
                          alternates: [UICommandAlternate(title: "Alt Shift", action: #selector(fireAltShift(_:)), modifierFlags: .shift),
                                       UICommandAlternate(title: "Alt Option", action: #selector(fireAltOption(_:)), modifierFlags: .alternate)])
  let direct = UIKeyCommand(title: "Direct", action: #selector(fireDirect(_:)), input: "j", modifierFlags: [.command, .shift])
  keyCommandsQueries += 1
  switch keyPhase {
  case "A": return [base]
  case "B": return [base, direct]
  case "C": return [direct, base]
  default: return nil
  }
 }
 @objc func fireBase(_ s: Any?) { mark("fired", ["action": "fireBase", "keyPhase": keyPhase, "press": currentPress, "sender": senderRow(s)]) }
 @objc func fireAltShift(_ s: Any?) { mark("fired", ["action": "fireAltShift", "keyPhase": keyPhase, "press": currentPress, "sender": senderRow(s)]) }
 @objc func fireAltOption(_ s: Any?) { mark("fired", ["action": "fireAltOption", "keyPhase": keyPhase, "press": currentPress, "sender": senderRow(s)]) }
 @objc func fireDirect(_ s: Any?) { mark("fired", ["action": "fireDirect", "keyPhase": keyPhase, "press": currentPress, "sender": senderRow(s)]) }

 @objc func openSettingsKeyCommand(_ s: Any?) { mark("fired", ["action": "openSettings", "press": currentPress, "sender": senderRow(s)]) }
 @objc func newTabKeyCommand(_ s: Any?) { mark("fired", ["action": "newTab", "press": currentPress, "sender": senderRow(s)]) }
 @objc func newPrivateTabKeyCommand(_ s: Any?) { mark("fired", ["action": "newPrivateTab", "press": currentPress, "sender": senderRow(s)]) }
 @objc func closeTabKeyCommand(_ s: Any?) { mark("fired", ["action": "closeTab", "press": currentPress, "sender": senderRow(s)]) }
 @objc func findInPageKeyCommand(_ s: Any?) {}
 @objc func reloadTabKeyCommand(_ s: Any?) {}
 @objc func reloadTabIgnoringCacheKeyCommand(_ s: Any?) {}
 @objc func goBackKeyCommand(_ s: Any?) {}
 @objc func addBookmarkKeyCommand(_ s: Any?) {}
 @objc func showDownloadsKeyCommand(_ s: Any?) { mark("fired", ["action": "showDownloads", "press": currentPress, "sender": senderRow(s)]) }
 @objc func nextTabKeyCommand(_ s: Any?) {}
 @objc func selectFirstTab(_ s: Any?) {}
 @objc func neverInAMenu(_ s: Any?) {}
}

final class App: UIResponder, UIApplicationDelegate {
 var window: UIWindow?
 let root = RootVC()

 override func buildMenu(with builder: UIMenuBuilder) {
  logBuild("AppDelegate", builder, callsSuper: true)
  super.buildMenu(with: builder)
  guard builder.system === UIMenuSystem.main else {
   if builder.system === UIMenuSystem.context {
    contextBuildCount += 1
    rows["builder.context.\(contextBuildCount).presence"] = presence(builder)
    rows["builder.context.\(contextBuildCount).root"] = builder.menu(for: .root).map { elementRow($0) } ?? "nil"
    save()
   }
   return
  }
  mainBuildCount += 1
  if mainBuildCount == 1 {
   rows["builder.main.defaults.presence"] = presence(builder)
   rows["builder.main.defaults.root"] = builder.menu(for: .root).map { elementRow($0) } ?? "nil"
   rows["builder.main.defaults.topLevel"] = topLevel(builder)
   save()
  }
  if edgeMode { edgeSequence(builder); return }
  firefoxSequence(builder, into: "builder.main.\(mainBuildCount).steps")
 }
 override func validate(_ command: UICommand) { logValidate("AppDelegate", command); super.validate(command) }

 func application(_ application: UIApplication, willFinishLaunchingWithOptions o: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
  phase = "willFinishLaunching"; mark("willFinishLaunching"); return true
 }
 func applicationDidBecomeActive(_ application: UIApplication) { mark("applicationDidBecomeActive") }
 func applicationWillEnterForeground(_ application: UIApplication) { mark("applicationWillEnterForeground") }

 func application(_ application: UIApplication, didFinishLaunchingWithOptions o: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
  phase = "didFinishLaunching"; mark("didFinishLaunching.enter")
  rows["device"] = ["model": UIDevice.current.model, "idiom": UIDevice.current.userInterfaceIdiom.rawValue, "hardwareKeyboardAttached": hardwareKeyboardAttached(),
                    "system": UIDevice.current.systemVersion, "screen": [Double(UIScreen.main.bounds.width), Double(UIScreen.main.bounds.height)],
                    "appClass": NSStringFromClass(type(of: application)), "edgeMode": edgeMode]
  rows["identifier.raw"] = Dictionary(uniqueKeysWithValues: ids.map { ($0.0, $0.1.rawValue) })
  rows["menuSystem"] = ["mainClass": NSStringFromClass(type(of: UIMenuSystem.main)), "contextClass": NSStringFromClass(type(of: UIMenuSystem.context)),
                        "mainIsSingleton": UIMenuSystem.main === UIMenuSystem.main, "mainIsContext": UIMenuSystem.main === UIMenuSystem.context]
  // UICommandAlternate + alternates data model.
  let a1 = UICommandAlternate(title: "One", action: #selector(RootVC.fireAltShift(_:)), modifierFlags: .shift)
  let a1b = UICommandAlternate(title: "Other title, same flags", action: #selector(RootVC.fireBase(_:)), modifierFlags: .shift)
  let a2 = UICommandAlternate(title: "Two", action: #selector(RootVC.fireAltOption(_:)), modifierFlags: [.alternate, .shift])
  let kc = UIKeyCommand(title: "KC", action: #selector(RootVC.fireBase(_:)), input: "j", modifierFlags: .command, alternates: [a1, a2])
  let cmd = UICommand(title: "Cmd", action: #selector(RootVC.fireBase(_:)), alternates: [a2])
  rows["model.alternate"] = [
   "a1": altRow(a1), "a2": altRow(a2), "superclass": NSStringFromClass(class_getSuperclass(UICommandAlternate.self)!),
   "a1 == a1b (same flags)": a1 == a1b, "a1 isEqual a1b": a1.isEqual(a1b), "a1 == a2": a1 == a2,
   "hash equal a1/a1b": a1.hash == a1b.hash, "copy === self": (a1.copy() as AnyObject) === a1,
   "description": a1.description,
   "kc.alternates.count": kc.alternates.count, "kc.alternates[0] === a1": kc.alternates[0] === a1,
   "kc.alternates[1] === a2": kc.alternates[1] === a2,
   "kc.noAlternates.count": UIKeyCommand(title: "x", action: #selector(RootVC.fireBase(_:)), input: "x").alternates.count,
   "cmd.alternates.count": cmd.alternates.count, "cmd.alternates[0] === a2": cmd.alternates[0] === a2,
   "kc.description": kc.description, "kc.class": NSStringFromClass(type(of: kc)), "kc.superclass": NSStringFromClass(class_getSuperclass(UIKeyCommand.self)!),
   "keyCommandsQueriedAtLaunch": false,
  ]
  save()

  let w = Win(frame: UIScreen.main.bounds)
  w.rootViewController = root; window = w; probeWindow = w
  mark("beforeMakeKeyAndVisible")
  w.makeKeyAndVisible()
  mark("afterMakeKeyAndVisible")
  let q = DispatchQueue.main
  func at(_ s: Double, _ name: String, _ body: @escaping () -> Void) {
   q.asyncAfter(deadline: .now() + s) { phase = name; mark("tick." + name); body(); mark("tick." + name + ".done") }
  }
  at(0.0, "asyncAfter0") {}
  at(0.5, "t+0.5") { rows["hardwareKeyboardAttached.t+0.5"] = hardwareKeyboardAttached() }
  if edgeMode {
   // No key event, no main build (measured): one Cmd-J brings the builder in.
   at(1.0, "edgeKey") { keyPhase = "A"; KeyInjector.press("cmd", "j", .command, route: "handleKeyUIEvent:", hid: true); keyPhase = "none" }
   at(2.0, "edgeExit") { exit(0) }
   return true
  }
  at(1.0, "setNeedsRebuild.1") { UIMenuSystem.main.setNeedsRebuild() }
  at(1.5, "setNeedsRebuild.2.vcNoSuper") { vcCallsSuper = false; UIMenuSystem.main.setNeedsRebuild() }
  at(2.0, "textField.becomeFirstResponder") { vcCallsSuper = true; _ = self.root.tf.becomeFirstResponder() }
  at(2.5, "setNeedsRevalidate") { UIMenuSystem.main.setNeedsRevalidate() }
  at(3.0, "textField.resignFirstResponder") { _ = self.root.tf.resignFirstResponder() }
  at(3.5, "context.setNeedsRebuild") { UIMenuSystem.context.setNeedsRebuild() }
  at(4.0, "presentEditMenu") {
   self.root.edit?.presentEditMenu(with: UIEditMenuConfiguration(identifier: nil, sourcePoint: CGPoint(x: 150, y: 400)))
  }
  at(5.0, "dismissEditMenu") { self.root.edit?.dismissMenu() }
  at(5.5, "keys") {
   rows["hardwareKeyboardAttached.keys"] = hardwareKeyboardAttached()
   let routes: [(String, Bool)] = [("handleKeyUIEvent:", true), ("shortcutInvocation", false), ("shortcutInvocation", true), ("handleShortcut", true)]
   let matrixA: [(String, UIKeyModifierFlags)] = [("cmd", .command), ("cmd+shift", [.command, .shift]), ("cmd+alt", [.command, .alternate]),
                                                  ("cmd+ctrl", [.command, .control]), ("cmd+shift+alt", [.command, .shift, .alternate]), ("plain", [])]
   let matrixBC: [(String, UIKeyModifierFlags)] = [("cmd+shift", [.command, .shift]), ("cmd", .command)]
   rows["keyInjector.available"] = KeyInjector.cls != nil
   var rb: [String: Any] = [:]
   for (n, f) in [("down0", 0), ("up1", 1)] { rb[n] = KeyInjector.make("j", .command, inputFlags: f).map { KeyInjector.describe($0) as Any } ?? "nil" }
   if let ev = KeyInjector.make("j", .command, inputFlags: 0) { rb["hidAttached"] = KeyInjector.attachHID(ev, input: "j", down: true); rb["withHID"] = KeyInjector.describe(ev) }
   rows["keyInjector.eventReadback"] = rb
   save()
   for (ph, matrix) in [("A", matrixA), ("B", matrixBC), ("C", matrixBC)] {
    keyPhase = ph
    for (route, hid) in routes { for (label, flags) in matrix { KeyInjector.press(label, "j", flags, route: route, hid: hid) } }
   }
   // Main-menu-only shortcuts (no responder vends them): firefox's New Tab
   // (Cmd-T, .shift alternate -> New Private Tab), Cmd-Shift-P, Close Tab
   // (Cmd-W, also UIKit's own File > Close), Settings (Cmd-Alt-,), and
   // Cmd-J which is BOTH a responder key command (phase A) and Tools > Downloads.
   keyPhase = "menuOnly"
   for (label, input, flags) in [("cmd-t", "t", UIKeyModifierFlags.command), ("cmd-shift-t", "t", [.command, .shift]), ("cmd-alt-t", "t", [.command, .alternate]),
                                 ("cmd-shift-p", "p", [.command, .shift]), ("cmd-w", "w", .command), ("cmd-alt-comma", ",", [.command, .alternate]), ("cmd-j", "j", .command)] {
    KeyInjector.press(label, input, flags, route: "handleKeyUIEvent:", hid: true)
   }
   keyPhase = "A"
   KeyInjector.press("cmd-j.responderAndMenu", "j", .command, route: "handleKeyUIEvent:", hid: true)
   keyPhase = "none"
  }
  at(6.5, "presentEditMenu.vcNoSuper") {
   vcCallsSuper = false
   self.root.edit?.presentEditMenu(with: UIEditMenuConfiguration(identifier: nil, sourcePoint: CGPoint(x: 150, y: 400)))
  }
  at(7.5, "dismissEditMenu.2") { vcCallsSuper = true; self.root.edit?.dismissMenu() }
  at(8.0, "exit") { exit(0) }
  mark("didFinishLaunching.return")
  return true
 }
}
phase = "main"; mark("UIApplicationMain.call")
UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, NSStringFromClass(MyApp.self), NSStringFromClass(App.self))
