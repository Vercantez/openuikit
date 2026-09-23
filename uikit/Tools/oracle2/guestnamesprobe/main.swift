// guestnamesprobe -- the ladder's remaining ABSENT Foundation class names
// (NSUUID, NSDecimalNumber, NSCharacterSet, NSException), the Apple side
// (run.sh, iOS 26.1 simulator) and the guest side
// (Tools/guestprobes/GuestNamesProbe.probe.sh) of the same program.
import Foundation

func say(_ items: Any...) { print(items.map { "\($0)" }.joined(separator: " ")) }

func uuids() {
    let text = "e621e1f8-c36c-495a-93fc-0c247a3e6e5f"
    let parsed = NSUUID(uuidString: text)
    say("nsuuid.parse", parsed?.uuidString ?? "nil")
    say("nsuuid.invalid", NSUUID(uuidString: "not-a-uuid") == nil)
    let fresh = NSUUID()
    say("nsuuid.fresh", fresh.uuidString.count, fresh.uuidString == fresh.uuidString.uppercased(),
        fresh.isEqual(NSUUID(uuidString: fresh.uuidString)), fresh.isEqual(NSUUID()))
    let bridged = parsed! as UUID
    say("nsuuid.bridge", bridged.uuidString, (UUID(uuidString: text)! as NSUUID).uuidString)
    say("nsuuid.hash.equal", parsed!.hash == NSUUID(uuidString: text.uppercased())!.hash)
    var bytes = [UInt8](repeating: 0, count: 16)
    parsed!.getBytes(&bytes)
    say("nsuuid.bytes", bytes.prefix(4).map { String($0, radix: 16) }.joined(separator: ","))
    let fromBytes = NSUUID(uuidBytes: bytes)
    say("nsuuid.fromBytes", fromBytes.uuidString)
}

func decimals() {
    let a = NSDecimalNumber(string: "1.10")
    let b = NSDecimalNumber(string: "2.205")
    say("decimal.string", a.stringValue, b.stringValue, a.description)
    say("decimal.add", a.adding(b).stringValue)
    say("decimal.sub", a.subtracting(b).stringValue)
    say("decimal.mul", a.multiplying(by: b).stringValue)
    say("decimal.div", NSDecimalNumber(string: "1").dividing(by: NSDecimalNumber(string: "3")).stringValue)
    say("decimal.double", b.doubleValue, b.intValue, NSDecimalNumber(string: "-7.9").intValue)
    say("decimal.nan", NSDecimalNumber(string: "abc").stringValue,
        NSDecimalNumber(string: "abc") == NSDecimalNumber.notANumber)
    say("decimal.constants", NSDecimalNumber.zero.stringValue, NSDecimalNumber.one.stringValue)
    say("decimal.compare", a.compare(b).rawValue, b.compare(a).rawValue, a.compare(NSDecimalNumber(string: "1.1")).rawValue)
    say("decimal.int", NSDecimalNumber(value: 42).stringValue, NSDecimalNumber(value: 2.5).stringValue)
    say("decimal.mantissa", NSDecimalNumber(mantissa: 12345, exponent: -2, isNegative: true).stringValue)
    say("decimal.decimal", NSDecimalNumber(decimal: Decimal(string: "3.14")!).stringValue,
        (NSDecimalNumber(string: "9.99") as Decimal).description)
    say("decimal.power", NSDecimalNumber(string: "1.5").raising(toPower: 2).stringValue,
        NSDecimalNumber(string: "1.5").multiplying(byPowerOf10: 3).stringValue)
    let handler = NSDecimalNumberHandler(roundingMode: .plain, scale: 2, raiseOnExactness: false,
                                         raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
    say("decimal.round", NSDecimalNumber(string: "2.345").rounding(accordingToBehavior: handler).stringValue,
        NSDecimalNumber(string: "2.344").rounding(accordingToBehavior: handler).stringValue,
        NSDecimalNumber(string: "-2.345").rounding(accordingToBehavior: handler).stringValue)
    say("decimal.locale", NSDecimalNumber(string: "1,5", locale: Locale(identifier: "de_DE")).stringValue)
}

func characterSets() {
    let text = "  Hello, World!\n"
    say("nscharset.trim", "[\(text.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines))]")
    say("nscharset.split", "Hello, World".components(separatedBy: NSCharacterSet.alphanumerics.inverted)
        .filter { !$0.isEmpty }.joined(separator: "|"))
    let digits = NSCharacterSet.decimalDigits
    say("nscharset.digits", "a1b2".unicodeScalars.filter { digits.contains($0) }.count)
    let custom = NSCharacterSet(charactersIn: "xyz")
    say("nscharset.custom", custom.characterIsMember(unichar(UInt8(ascii: "y"))),
        custom.characterIsMember(unichar(UInt8(ascii: "a"))), (custom as CharacterSet).contains("z"))
    let mutable = NSMutableCharacterSet(charactersIn: "ab")
    mutable.addCharacters(in: "c")
    say("nscharset.mutable", (mutable as CharacterSet).contains("c"), mutable.characterIsMember(unichar(UInt8(ascii: "d"))))
    say("nscharset.upper", NSCharacterSet.uppercaseLetters.contains("Q"), NSCharacterSet.uppercaseLetters.contains("q"))
    say("nscharset.url", "a b/c?d".addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed) ?? "nil",
        "a b#c".addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlFragmentAllowed) ?? "nil")
}

func exceptions() {
    let name = NSExceptionName("GuestProbeException")
    let exception = NSException(name: name, reason: "because", userInfo: ["k": "v"])
    say("nsexception", exception.name.rawValue, exception.reason ?? "nil",
        exception.userInfo?["k"] as? String ?? "nil")
    say("nsexception.names", NSExceptionName.invalidArgumentException.rawValue,
        NSExceptionName.internalInconsistencyException.rawValue,
        NSExceptionName.rangeException.rawValue, NSExceptionName.genericException.rawValue)
}

@main
struct GuestNamesProbe {
    static func main() {
        print("guestnamesprobe v1")
        uuids()
        decimals()
        characterSets()
        exceptions()
        print("guestnamesprobe done")
    }
}
