#if os(iOS)
@main
struct TrueIOSTargetProbe {
    static func main() {
        print("TRUE_IOS_TRIPLE_GUEST_OK os=iOS target=arm64-apple-ios-simulator")
    }
}
#else
#error("the portable compiler did not select the iOS conditional domain")
#endif
