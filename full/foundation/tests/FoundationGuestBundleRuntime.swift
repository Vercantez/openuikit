import Foundation

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() {
        fatalError("bundle-runtime: \(message)")
    }
}

private func write(_ text: String, to url: URL) throws {
    try Data(text.utf8).write(to: url)
}

@main
struct FoundationGuestBundleRuntime {
    static func main() throws {
        guard CommandLine.arguments.count == 2 else {
            fatalError("expected a fresh fixture parent")
        }
        let parent = URL(
            fileURLWithPath: CommandLine.arguments[1],
            isDirectory: true
        )
        let manager = FileManager.default
        let bundleRoot = parent.appendingPathComponent("Fixture.bundle", isDirectory: true)
        let contents = bundleRoot.appendingPathComponent("Contents", isDirectory: true)
        let resources = contents.appendingPathComponent("Resources", isDirectory: true)
        let english = resources.appendingPathComponent("en.lproj", isDirectory: true)
        try manager.createDirectory(at: english, withIntermediateDirectories: true)

        try write(
            """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0"><dict>
              <key>CFBundleIdentifier</key><string>org.openfoundation.fixture</string>
              <key>CFBundleName</key><string>Focus &amp; Linux</string>
              <key>CFBundlePackageType</key><string>BNDL</string>
              <key>CFBundleDevelopmentRegion</key><string>en</string>
              <key>Values</key><array><string>one</string><integer>2</integer><true/></array>
            </dict></plist>
            """,
            to: contents.appendingPathComponent("Info.plist")
        )
        try write(
            """
            /* fixture */
            "Greeting" = "Private \\"Focus\\"";
            "Escaped" = "line\\nnext";
            """,
            to: english.appendingPathComponent("Localizable.strings")
        )
        try write("domains\n", to: resources.appendingPathComponent("topdomains.txt"))

        guard let bundle = Bundle(url: bundleRoot) else {
            fatalError("valid fixture was not a bundle")
        }
        require(bundle.bundleIdentifier == "org.openfoundation.fixture", "identifier")
        require(bundle.object(forInfoDictionaryKey: "CFBundlePackageType") as? String == "BNDL", "package type")
        require(bundle.infoDictionary?["CFBundleName"] as? String == "Focus & Linux", "entity")
        require((bundle.infoDictionary?["Values"] as? [Any])?.count == 3, "array")
        require(bundle.developmentLocalization == "en", "development localization")
        require(bundle.localizations == ["en"], "localizations")
        require(bundle.preferredLocalizations.first == "en", "preferred localization")
        require(
            bundle.localizedString(forKey: "Greeting", value: nil, table: nil)
                == "Private \"Focus\"",
            "localized value"
        )
        require(
            bundle.localizedString(forKey: "Missing", value: "fallback", table: nil)
                == "fallback",
            "localized fallback"
        )
        require(
            bundle.localizedString(forKey: "Missing", value: nil, table: nil)
                == "Missing",
            "localized key fallback"
        )
        require(
            bundle.path(forResource: "topdomains", ofType: "txt")?.hasSuffix("/topdomains.txt") == true,
            "resource path"
        )
        require(bundle.path(forResource: "missing", ofType: "txt") == nil, "missing resource")
        require(bundle.appStoreReceiptURL?.lastPathComponent == "receipt", "receipt URL")

        #if FOUNDATION_GUEST_PORT
        let malformedRoot = parent.appendingPathComponent("Malformed.bundle", isDirectory: true)
        let malformedContents = malformedRoot.appendingPathComponent("Contents", isDirectory: true)
        try manager.createDirectory(
            at: malformedContents.appendingPathComponent("Resources", isDirectory: true),
            withIntermediateDirectories: true
        )
        try write(
            "<plist version=\"1.0\"><dict><key>Name</key><string>&unknown;</string></dict></plist>",
            to: malformedContents.appendingPathComponent("Info.plist")
        )
        guard let malformed = Bundle(url: malformedRoot) else {
            fatalError("malformed plist directory was not a bundle")
        }
        require(malformed.infoDictionary == nil, "unknown XML entity must fail closed")
        #endif

        #if FOUNDATION_GUEST_PORT
        print("FOUNDATION_GUEST_BUNDLE_RUNTIME_OK plist=xml localization=en malformed-entity=rejected")
        #else
        print("FOUNDATION_GUEST_BUNDLE_APPLE_OK plist=xml localization=en")
        #endif
    }
}
