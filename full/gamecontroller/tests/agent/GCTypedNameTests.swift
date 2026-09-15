import Foundation
import Dispatch
import GameController

func testPhysicalInputTypedNames() {
    func typedRoundTrip<T: GCPhysicalInputElementTypedName>(_ value: T, raw: T.RawValue) -> T.RawValue {
        precondition(value.rawValue == raw)
        let rebuilt = T(rawValue: raw)
        precondition(rebuilt != nil)
        return rebuilt!.rawValue
    }

    _ = (any GCPhysicalInputElement).self
    typealias AxisRaw = GCAxisElementName.RawValue
    let axisRaw: AxisRaw = "left-x"
    precondition(typedRoundTrip(GCAxisElementName(rawValue: axisRaw), raw: axisRaw) == "left-x")
    typealias AxisElement = GCAxisElementName.PhysicalInputElement
    _ = AxisElement.self

    typealias ButtonRaw = GCButtonElementName.RawValue
    let buttonRaw: ButtonRaw = GCInputButtonA
    precondition(typedRoundTrip(GCButtonElementName.a, raw: buttonRaw) == GCInputButtonA)
    typealias ButtonElement = GCButtonElementName.PhysicalInputElement
    _ = ButtonElement.self

    typealias SwitchRaw = GCSwitchElementName.RawValue
    let switchRaw: SwitchRaw = "pistol"
    precondition(typedRoundTrip(GCSwitchElementName(rawValue: switchRaw), raw: switchRaw) == "pistol")
    typealias SwitchElement = GCSwitchElementName.PhysicalInputElement
    _ = SwitchElement.self

    typealias PadRaw = GCDirectionPadElementName.RawValue
    let padRaw: PadRaw = GCInputLeftThumbstick
    precondition(typedRoundTrip(GCDirectionPadElementName.leftThumbstick, raw: padRaw) == GCInputLeftThumbstick)
    typealias PadElement = GCDirectionPadElementName.PhysicalInputElement
    _ = PadElement.self

    typealias NamedRaw = GCPhysicalInputElementName.RawValue
    let namedRaw: NamedRaw = "trigger"
    precondition(typedRoundTrip(GCPhysicalInputElementName(rawValue: namedRaw), raw: namedRaw) == "trigger")
    typealias NamedElement = GCPhysicalInputElementName.PhysicalInputElement
    _ = NamedElement.self

    func typedElement<T: GCPhysicalInputElementTypedName>(_: T.Type) -> T.PhysicalInputElement.Type? {
        nil
    }
    _ = typedElement(GCAxisElementName.self)
    _ = typedElement(GCButtonElementName.self)
    _ = typedElement(GCSwitchElementName.self)
    _ = typedElement(GCDirectionPadElementName.self)
    _ = typedElement(GCPhysicalInputElementName.self)
}
