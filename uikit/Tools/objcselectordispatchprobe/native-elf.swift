// Stock native-ELF substrate micro-oracle. Candidate source statically pins
// UIResponder's matching `import class Foundation.NSObject` branch; this
// proves that provider retains NSObject identity semantics without ObjC.
#if canImport(ObjectiveC)
#error("native-elf substrate probe must not see ObjectiveC")
#endif
import Foundation

final class NativeELFResponder: NSObject {}

let first = NativeELFResponder()
let alias = first
let second = NativeELFResponder()
precondition(Set([first, alias, second]).count == 2)
let erased: Any = first
precondition(erased is NSObjectProtocol)
print("NATIVE_ELF_NSOBJECT_ROOT_OK set=2 objc=false")
