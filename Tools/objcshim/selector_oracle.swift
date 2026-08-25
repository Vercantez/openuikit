// The `#selector` mangling ORACLE. Owner: selector/app-compat.
//
// OpenUIKit's portable spelling of a selector is `Selector.named("...")`, and
// the string has to be the *Objective-C* selector name that real `#selector`
// would have produced for the same declaration. This file is where that rule
// comes from: rather than trusting a remembered version of Swift's
// `AbstractFunctionDecl::getObjCSelector`, it asks the real compiler.
//
// Run on macOS:   swiftc -O Tools/objcshim/selector_oracle.swift -o /tmp/oracle && /tmp/oracle
// Expected output: Tools/objcshim/selector_oracle.expected
//
// The rules it establishes (all measured, none assumed) are written up in
// docs/OBJC_RUNTIME.md, "Appendix: the `#selector` mangling oracle".

import Foundation

class Probe: NSObject {
    @objc func zeroArg() {}
    @objc func oneUnlabelled(_ a: Any) {}
    @objc func oneLabelled(a: Any) {}
    @objc func twoUnlabelled(_ a: Any, _ b: Any) {}
    @objc func twoFirstUnlabelled(_ a: Any, with b: Any) {}
    @objc func twoLabelled(a: Any, b: Any) {}
    @objc func threeMixed(_ a: Any, of b: Any, in c: Any) {}
    @objc func labelledFirstOnly(sender: Any, _ b: Any) {}
    @objc func handlePan(gesture: Any) {}
    @objc func withPrepositionAt(_ a: Any) {}
    @objc func insertObject(_ a: Any, at i: Int) {}
    @objc func tableView(_ t: Any, numberOfRowsInSection s: Int) -> Int { 0 }
    @objc(customSelName) func custom() {}
    @objc(customWithArg:) func custom2(_ a: Any) {}
    @objc(doThing:with:) func custom3(_ a: Any, _ b: Any) {}
    @objc var someProperty: Int = 0
    @objc var url: Int = 0
    @objc var isEnabledFlag: Bool = false
    @objc(customProp) var renamed: Int = 0
    @IBAction func ibAction(_ sender: Any) {}
    @objc func doubleCap(URLString a: Any) {}
    @objc func emptyish(_: Any) {}
    @objc class func classMethod(_ a: Any) {}
    @objc func aBc(deF g: Any) {}
    @objc func x(_ a: Any, b: Any, _ c: Any) {}
}

class P2: NSObject {
    @objc func startWith(url: Any) {}          // base name already ends in "With"
    @objc func insert(at i: Int) {}            // label is a preposition
    @objc func move(from a: Int, to b: Int) {}
    @objc func set(value v: Int) {}
    @objc func _underscored(_ a: Any) {}
    @objc func trailingClosureLike(completion: () -> Void) {}
    @objc func number(_ n: Int) {}
    @objc init(thing: Int) { super.init() }
    @objc override init() { super.init() }
    @objc func y(_ a: Any, _ b: Any, _ c: Any) {}
    @objc func multiWordLabel(firstThing a: Any, secondThing b: Any) {}
    @objc var xY: Int = 0
    @objc var _lead: Int = 0
    @objc var ABC: Int = 0
}
extension P2 {
    @objc func inExtension() {}
    @objc func inExtension2(sender s: Any) {}
}

func p(_ label: String, _ s: Selector) {
    print(label.padding(toLength: 56, withPad: " ", startingAt: 0)
          + NSStringFromSelector(s))
}

print("== methods: no argument labels ==")
p("#selector(Probe.zeroArg)", #selector(Probe.zeroArg))
p("#selector(Probe.oneUnlabelled(_:))", #selector(Probe.oneUnlabelled(_:)))
p("#selector(Probe.twoUnlabelled(_:_:))", #selector(Probe.twoUnlabelled(_:_:)))
p("#selector(P2.y(_:_:_:))", #selector(P2.y(_:_:_:)))
p("#selector(Probe.emptyish(_:))", #selector(Probe.emptyish(_:)))
p("#selector(Probe.classMethod(_:))", #selector(Probe.classMethod(_:)))
p("#selector(P2._underscored(_:))", #selector(P2._underscored(_:)))
p("#selector(P2.number(_:))", #selector(P2.number(_:)))
p("#selector(Probe.withPrepositionAt(_:))", #selector(Probe.withPrepositionAt(_:)))
p("#selector(P2.inExtension)", #selector(P2.inExtension))

print("== methods: first label empty, later labels present ==")
p("#selector(Probe.twoFirstUnlabelled(_:with:))", #selector(Probe.twoFirstUnlabelled(_:with:)))
p("#selector(Probe.threeMixed(_:of:in:))", #selector(Probe.threeMixed(_:of:in:)))
p("#selector(Probe.insertObject(_:at:))", #selector(Probe.insertObject(_:at:)))
p("#selector(Probe.tableView(_:numberOfRowsInSection:))", #selector(Probe.tableView(_:numberOfRowsInSection:)))
p("#selector(Probe.x(_:b:_:))", #selector(Probe.x(_:b:_:)))

print("== methods: FIRST label non-empty -> 'With' + SentenceCase ==")
p("#selector(Probe.oneLabelled(a:))", #selector(Probe.oneLabelled(a:)))
p("#selector(Probe.twoLabelled(a:b:))", #selector(Probe.twoLabelled(a:b:)))
p("#selector(Probe.handlePan(gesture:))", #selector(Probe.handlePan(gesture:)))
p("#selector(Probe.labelledFirstOnly(sender:_:))", #selector(Probe.labelledFirstOnly(sender:_:)))
p("#selector(Probe.doubleCap(URLString:))", #selector(Probe.doubleCap(URLString:)))
p("#selector(Probe.aBc(deF:))", #selector(Probe.aBc(deF:)))
p("#selector(P2.startWith(url:))", #selector(P2.startWith(url:)))
p("#selector(P2.insert(at:))", #selector(P2.insert(at:)))
p("#selector(P2.move(from:to:))", #selector(P2.move(from:to:)))
p("#selector(P2.set(value:))", #selector(P2.set(value:)))
p("#selector(P2.trailingClosureLike(completion:))", #selector(P2.trailingClosureLike(completion:)))
p("#selector(P2.multiWordLabel(firstThing:secondThing:))", #selector(P2.multiWordLabel(firstThing:secondThing:)))
p("#selector(P2.inExtension2(sender:))", #selector(P2.inExtension2(sender:)))

print("== initialisers ==")
p("#selector(P2.init(thing:))", #selector(P2.init(thing:)))
p("#selector(P2.init as () -> P2)", #selector(P2.init as () -> P2))

print("== @objc(custom) overrides everything ==")
p("#selector(Probe.custom)", #selector(Probe.custom))
p("#selector(Probe.custom2(_:))", #selector(Probe.custom2(_:)))
p("#selector(Probe.custom3(_:_:))", #selector(Probe.custom3(_:_:)))

print("== @IBAction behaves exactly like @objc ==")
p("#selector(Probe.ibAction(_:))", #selector(Probe.ibAction(_:)))

print("== properties: getter / setter ==")
p("#selector(getter: Probe.someProperty)", #selector(getter: Probe.someProperty))
p("#selector(setter: Probe.someProperty)", #selector(setter: Probe.someProperty))
p("#selector(getter: Probe.url)", #selector(getter: Probe.url))
p("#selector(setter: Probe.url)", #selector(setter: Probe.url))
p("#selector(getter: Probe.isEnabledFlag)", #selector(getter: Probe.isEnabledFlag))
p("#selector(setter: Probe.isEnabledFlag)", #selector(setter: Probe.isEnabledFlag))
p("#selector(getter: Probe.renamed)", #selector(getter: Probe.renamed))
p("#selector(setter: Probe.renamed)", #selector(setter: Probe.renamed))
p("#selector(getter: P2.xY)", #selector(getter: P2.xY))
p("#selector(setter: P2.xY)", #selector(setter: P2.xY))
p("#selector(getter: P2._lead)", #selector(getter: P2._lead))
p("#selector(setter: P2._lead)", #selector(setter: P2._lead))
p("#selector(getter: P2.ABC)", #selector(getter: P2.ABC))
p("#selector(setter: P2.ABC)", #selector(setter: P2.ABC))
