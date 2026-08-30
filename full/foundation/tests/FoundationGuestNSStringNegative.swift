import Foundation

@main
struct FoundationGuestNSStringNegative {
    static func main() {
        let unsupported = NSString(
            data: Data([0x41, 0x00]),
            encoding: String.Encoding.utf16LittleEndian.rawValue
        )
        let missingBytes = NSString(
            bytes: nil,
            length: 1,
            encoding: String.Encoding.utf8.rawValue
        )
        let invalid: [UInt8] = [0xF0, 0x28, 0x8C, 0x28]
        let malformed = invalid.withUnsafeBytes {
            NSString(
                bytes: $0.baseAddress,
                length: $0.count,
                encoding: String.Encoding.utf8.rawValue
            )
        }
        precondition(unsupported == nil)
        precondition(missingBytes == nil)
        precondition(malformed == nil)
        print("FOUNDATION_GUEST_NSSTRING_NEGATIVE_OK unsupported=1 missing=1 malformed=1")
    }
}
