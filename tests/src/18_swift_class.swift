// 18_swift_class.swift -- rung (q): Swift classes, generics and dynamic dispatch.
//
// Everything below this rung is C, C++ or Objective-C. This one is the first
// fixture whose runtime is the Swift standard library, and it is deliberately
// narrow: it exercises the three things that reach the Swift runtime's
// PER-THREAD CONTEXT, because that is what machorun could not do.
//
//   1. a class with stored properties and a method   -- class metadata is
//      instantiated lazily on first use, and swift_getInitializedMetadata
//      goes through SwiftTLSContext
//   2. a generic function constrained to a protocol  -- the witness table for
//      each concrete conformance is built on demand, same path
//   3. a class hierarchy with an override            -- vtable dispatch, and
//      the ARC traffic that objc4's fast path routes to swift_retain/release
//
// SwiftTLSContext::get() adopts pthread key 100 with pthread_key_init_np and
// reads it back with pthread_getspecific. machorun's libSystem bound-checked
// that key against 64 and forwarded the accessors to glibc's unrelated key
// namespace, so tls_init_once() aborted with "failed to set destructor" and
// none of the three above could run at all.
//
// NO FOUNDATION, and nothing outside the core stdlib: the libswiftCore we
// cross-build on Linux is core-only (no _Concurrency, no _StringProcessing,
// no SwiftOnoneSupport), so an import of any of those would make the Linux
// build fail rather than the loader. Output is fully deterministic -- no
// addresses, no hashes, no set or dictionary iteration order.

// ---------------------------------------------------------------- (1) a class
final class Counter {
    var name: String
    var count: Int
    let step: Int

    init(name: String, step: Int) {
        self.name = name
        self.count = 0
        self.step = step
    }

    func bump() -> Int {
        count += step
        return count
    }

    func describe() -> String { "\(name)=\(count)" }
}

// ------------------------------------------------- (2) a generic over a protocol
protocol Shape {
    var sides: Int { get }
    func area(_ unit: Int) -> Int
}

struct Square: Shape {
    let edge: Int
    var sides: Int { 4 }
    func area(_ unit: Int) -> Int { edge * edge * unit }
}

struct Triangle: Shape {
    let base: Int
    let height: Int
    var sides: Int { 3 }
    func area(_ unit: Int) -> Int { base * height * unit / 2 }
}

// Generic over the protocol, so a witness table is instantiated per concrete
// type at the call site rather than carried in an existential.
func report<S: Shape>(_ s: S, unit: Int) -> String {
    "sides=\(s.sides) area=\(s.area(unit))"
}

// A generic that is also constrained by a stdlib protocol, which forces the
// runtime to look up a conformance it did not emit itself.
func largest<T: Comparable>(_ xs: [T]) -> T? {
    var best: T? = nil
    for x in xs {
        if let b = best { if x > b { best = x } } else { best = x }
    }
    return best
}

// ------------------------------------------- (3) a hierarchy with an override
class Animal {
    let name: String
    init(name: String) { self.name = name }
    func speak() -> String { "..." }
    func line() -> String { "\(name) says \(speak())" }   // dispatches virtually
}

class Dog: Animal {
    override func speak() -> String { "woof" }
}

class Puppy: Dog {
    override func speak() -> String { "yip" }
}

// ------------------------------------------------------------------- the run
let c = Counter(name: "clicks", step: 3)
_ = c.bump()
_ = c.bump()
print("class: \(c.describe()) step=\(c.step)")

print("generic square:   \(report(Square(edge: 5), unit: 2))")
print("generic triangle: \(report(Triangle(base: 6, height: 4), unit: 3))")
print("generic largest:  \(largest([3, 17, 8, 17, 1]) ?? -1) \(largest(["pear", "apple", "fig"]) ?? "-")")

// Existentials: the same values through a protocol box rather than a witness
// table passed at the call site.
let shapes: [Shape] = [Square(edge: 2), Triangle(base: 10, height: 3)]
print("existential sides: \(shapes.map { $0.sides })")

let animals: [Animal] = [Animal(name: "thing"), Dog(name: "rex"), Puppy(name: "bit")]
for a in animals { print("dispatch: \(a.line())") }

// Downcast: swift_dynamicCast against class metadata built above.
var dogs = 0
for a in animals where a is Dog { dogs += 1 }
print("dynamic casts: dogs=\(dogs) puppy=\(animals[2] is Puppy)")

// ARC in anger: the array is the only owner, so releasing it releases three
// class instances through the path objc4 routes to swift_release.
var live: [Counter] = []
for i in 1...4 { live.append(Counter(name: "c\(i)", step: i)) }
for x in live { _ = x.bump() }
print("arc: \(live.map { $0.describe() })")
live.removeAll()
print("arc: released, remaining=\(live.count)")

// ------------------------------------- (4) classes that live in a DYLIB
// Everything above is declared in this executable, so its class metadata sits
// at the executable's load address -- which machorun places at 0x100000000, by
// accident of the preferred base. That made the rest of this file blind to a
// loader bug that breaks every realistic Swift program: libswiftCore has the
// 47-bit isa mask compiled into swift_getObjectType and
// swift_unknownObjectRetain, and machorun used to load DYLIBS at 0xffff...,
// where masking truncates the class pointer and the runtime faults on an
// address it computed itself. 19_isa_mask asserts the placement; this asserts
// that Swift survives it. Both are wanted: one is WHERE, one is WHETHER.
//
// __SwiftValue and the String/Array storage classes all live in
// libswiftCore.dylib, and `as AnyObject` plus `type(of:)` is the shortest route
// from Swift source to swift_unknownObjectRetain and swift_getObjectType.
@inline(never) func opaque(_ x: AnyObject) -> AnyObject { x }

let boxedString = opaque(String(repeating: "xy", count: 64) as AnyObject)
let boxedArray  = opaque([1, 2, 3, 4] as AnyObject)
print("dylib class: \(type(of: boxedString)) \(type(of: boxedArray))")
print("dylib class: same=\(boxedString === boxedString) cross=\(boxedString === boxedArray)")

print("done")
