import Foundation

@main
private struct FoundationNSSortDescriptorNativeOracle {
    static func main() {
        let value = NSSortDescriptor(
            key: "creationDate",
            ascending: false
        )
        precondition(value.key == "creationDate")
        precondition(!value.ascending)
        let reversed = value.reversedSortDescriptor as! NSSortDescriptor
        precondition(reversed.key == "creationDate")
        precondition(reversed.ascending)
        print(
            "FOUNDATION_NSSORTDESCRIPTOR_APPLE_OK "
                + "key=creationDate ascending=false reversed=true"
        )
    }
}
