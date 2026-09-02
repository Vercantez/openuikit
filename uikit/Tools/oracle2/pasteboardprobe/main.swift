// PasteboardProbe: real-iOS oracle for UIPasteboard's direct-access surface.
//
// OpenUIKit cannot talk to iOS' system pasteboard on Linux, but it can match
// the observable relationship between `string`/`strings`, `url`/`urls`, the
// query properties, and `changeCount`.  This small app measures those rules
// on UIKit itself and writes a stable transcript to Documents/pasteboard.txt.
// Run it end-to-end with scripts/pasteboard_probe_sim.sh <outdir>.

import UIKit

private func quoted(_ value: String?) -> String {
    value.map { "\"\($0)\"" } ?? "nil"
}

private func quoted(_ values: [String]?) -> String {
    values.map { "[" + $0.map { "\"\($0)\"" }.joined(separator: ",") + "]" } ?? "nil"
}

private func optionalCount<Element>(_ values: [Element]?) -> String {
    values.map { String($0.count) } ?? "nil"
}

private func snapshot(_ label: String, _ pasteboard: UIPasteboard,
                      baseline: Int) -> String {
    let urls = pasteboard.urls?.map(\.absoluteString)
    let keys = pasteboard.items.map { $0.keys.sorted().joined(separator: "+") }
    return [
        label,
        "string=\(quoted(pasteboard.string))",
        "strings=\(quoted(pasteboard.strings))",
        "url=\(quoted(pasteboard.url?.absoluteString))",
        "urls=\(quoted(urls))",
        "images=\(pasteboard.images?.count.description ?? "nil")",
        "colors=\(pasteboard.colors?.count.description ?? "nil")",
        "keys=\(quoted(keys))",
        "items=\(pasteboard.numberOfItems)",
        "hasStrings=\(pasteboard.hasStrings)",
        "hasURLs=\(pasteboard.hasURLs)",
        "hasImages=\(pasteboard.hasImages)",
        "hasColors=\(pasteboard.hasColors)",
        "change=\(pasteboard.changeCount - baseline)",
    ].joined(separator: " ")
}

private final class PasteboardProbeDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions
                     launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let pasteboard = UIPasteboard.general
        pasteboard.items = []
        let baseline = pasteboard.changeCount
        var lines = [[
            "constants",
            "general=\(quoted(UIPasteboard.Name.general.rawValue))",
            "boardName=\(quoted(pasteboard.name.rawValue))",
            "expiration=\(quoted(UIPasteboard.OptionsKey.expirationDate.rawValue))",
            "localOnly=\(quoted(UIPasteboard.OptionsKey.localOnly.rawValue))",
            "automatic=\(quoted(UIPasteboard.typeAutomatic))",
            "strings=\(quoted(UIPasteboard.typeListString as? [String]))",
            "urls=\(quoted(UIPasteboard.typeListURL as? [String]))",
            "images=\(quoted(UIPasteboard.typeListImage as? [String]))",
            "colors=\(quoted(UIPasteboard.typeListColor as? [String]))",
        ].joined(separator: " ")]
        lines.append(snapshot("empty", pasteboard, baseline: baseline))

        pasteboard.string = "plain text"
        lines.append(snapshot("string", pasteboard, baseline: baseline))
        pasteboard.string = nil
        lines.append(snapshot("string-nil", pasteboard, baseline: baseline))

        pasteboard.strings = ["one", "two"]
        lines.append(snapshot("strings-two", pasteboard, baseline: baseline))
        pasteboard.strings = []
        lines.append(snapshot("strings-empty", pasteboard, baseline: baseline))

        pasteboard.url = URL(string: "https://example.com/one")!
        lines.append(snapshot("url", pasteboard, baseline: baseline))
        pasteboard.url = nil
        lines.append(snapshot("url-nil", pasteboard, baseline: baseline))

        pasteboard.urls = [URL(string: "https://example.com/a")!,
                           URL(string: "https://example.com/b")!]
        lines.append(snapshot("urls-two", pasteboard, baseline: baseline))
        pasteboard.urls = []
        lines.append(snapshot("urls-empty", pasteboard, baseline: baseline))

        pasteboard.image = UIImage(systemName: "star")!
        lines.append(snapshot("image", pasteboard, baseline: baseline))
        pasteboard.image = nil
        lines.append(snapshot("image-nil", pasteboard, baseline: baseline))

        pasteboard.colors = [.red, .blue]
        lines.append(snapshot("colors-two", pasteboard, baseline: baseline))
        pasteboard.colors = []
        lines.append(snapshot("colors-empty", pasteboard, baseline: baseline))

        pasteboard.string = "https://example.com/as-text"
        lines.append(snapshot("url-shaped-string", pasteboard, baseline: baseline))
        pasteboard.url = URL(string: "https://example.com/then-url")!
        lines.append(snapshot("string-then-url", pasteboard, baseline: baseline))

        // Edge semantics used by real corpus apps. Signal-iOS writes text as
        // Data, uses `typeAutomatic`, and composes custom + plain-text items.
        // These probes also distinguish nil from a present-but-empty query.
        pasteboard.items = []
        lines.append([
            "edge-empty-query",
            "types=\(optionalCount(pasteboard.types(forItemSet: nil)))",
            "values=\(optionalCount(pasteboard.values(forPasteboardType: "missing", inItemSet: nil)))",
        ].joined(separator: " "))

        pasteboard.items = [["public.alpha": "a"]]
        lines.append([
            "edge-nonempty-missing-query",
            "typesEmpty=\(optionalCount(pasteboard.types(forItemSet: IndexSet())))",
            "typesOutOfRange=\(optionalCount(pasteboard.types(forItemSet: IndexSet(integer: 99))))",
            "values=\(optionalCount(pasteboard.values(forPasteboardType: "missing", inItemSet: nil)))",
        ].joined(separator: " "))

        let hello = Data("hello".utf8)
        pasteboard.items = []
        pasteboard.addItems([["public.utf8-plain-text": hello]])
        lines.append([
            "edge-text-data",
            "string=\(quoted(pasteboard.string))",
            "strings=\(quoted(pasteboard.strings))",
            "data=\(optionalCount(pasteboard.data(forPasteboardType: "public.utf8-plain-text", inItemSet: nil)))",
        ].joined(separator: " "))

        pasteboard.items = [["custom.string": "ignored"]]
        lines.append(snapshot("edge-custom-string", pasteboard, baseline: baseline))
        pasteboard.items = [["public.text": "abstract"]]
        lines.append(snapshot("edge-public-text", pasteboard, baseline: baseline))
        pasteboard.items = [["public.text": hello]]
        lines.append(snapshot("edge-public-text-data", pasteboard, baseline: baseline))
        pasteboard.items = [["public.plain-text": "plain"]]
        lines.append(snapshot("edge-public-plain-text", pasteboard, baseline: baseline))
        pasteboard.items = [["public.plain-text": hello]]
        lines.append(snapshot("edge-public-plain-text-data", pasteboard, baseline: baseline))
        let png = UIImage(systemName: "star")!.pngData()!
        pasteboard.items = [["custom.png": png]]
        lines.append(snapshot("edge-custom-png", pasteboard, baseline: baseline))
        pasteboard.items = [["com.apple.uikit.image": png]]
        lines.append(snapshot("edge-object-image-data", pasteboard, baseline: baseline)
                     + " data=\(pasteboard.data(forPasteboardType: "com.apple.uikit.image") == nil ? "nil" : "present")")
        pasteboard.items = [["public.png": png]]
        lines.append(snapshot("edge-public-png-data", pasteboard, baseline: baseline))

        let itemURL = URL(string: "https://example.com/item")!
        pasteboard.items = [["public.url": itemURL]]
        lines.append(snapshot("edge-url-object", pasteboard, baseline: baseline))
        pasteboard.items = [["public.url": itemURL.absoluteString]]
        lines.append(snapshot("edge-url-string", pasteboard, baseline: baseline))
        pasteboard.items = [["public.url": Data(itemURL.absoluteString.utf8)]]
        lines.append(snapshot("edge-url-data", pasteboard, baseline: baseline))

        pasteboard.items = [["one": 1], ["two": 2]]
        pasteboard.setValue("replacement", forPasteboardType: "custom.value")
        lines.append(snapshot("edge-set-value", pasteboard, baseline: baseline))
        pasteboard.items = [["one": 1], ["two": 2]]
        pasteboard.setData(hello, forPasteboardType: "public.utf8-plain-text")
        lines.append(snapshot("edge-set-data", pasteboard, baseline: baseline))

        pasteboard.setItems([[UIPasteboard.typeAutomatic: "automatic text"]],
                            options: [:])
        lines.append(snapshot("edge-automatic-string", pasteboard, baseline: baseline))
        pasteboard.setItems([[UIPasteboard.typeAutomatic: itemURL]], options: [:])
        lines.append(snapshot("edge-automatic-url", pasteboard, baseline: baseline))
        pasteboard.setItems([[UIPasteboard.typeAutomatic: UIImage(systemName: "star")!]],
                            options: [:])
        lines.append(snapshot("edge-automatic-image", pasteboard, baseline: baseline))
        pasteboard.setItems([[UIPasteboard.typeAutomatic: UIColor.red]], options: [:])
        lines.append(snapshot("edge-automatic-color", pasteboard, baseline: baseline))

        let named = UIPasteboard.Name("com.openuikit.pasteboardprobe.named")
        UIPasteboard.remove(withName: named)
        let first = UIPasteboard(name: named, create: true)!
        let second = UIPasteboard(name: named, create: false)!
        first.string = "shared"
        let namedBeforeRemoval = first.changeCount
        UIPasteboard.remove(withName: named)
        lines.append([
            "edge-named-removed",
            "first=\(quoted(first.string))",
            "second=\(quoted(second.string))",
            "lookup=\(UIPasteboard(name: named, create: false) == nil ? "nil" : "present")",
            "generationChanged=\(first.changeCount != namedBeforeRemoval)",
        ].joined(separator: " "))
        second.string = "reattached"
        lines.append([
            "edge-named-reattached",
            "first=\(quoted(first.string))",
            "lookup=\(quoted(UIPasteboard(name: named, create: false)?.string))",
        ].joined(separator: " "))
        UIPasteboard.remove(withName: named)

        pasteboard.string = "clear general"
        let generalBeforeRemoval = pasteboard.changeCount
        UIPasteboard.remove(withName: .general)
        lines.append([
            "edge-general-removed",
            "string=\(quoted(pasteboard.string))",
            "items=\(pasteboard.numberOfItems)",
            "lookup=\(UIPasteboard(name: .general, create: false) == nil ? "nil" : "present")",
            "generationChanged=\(pasteboard.changeCount != generalBeforeRemoval)",
        ].joined(separator: " "))

        let docs = FileManager.default.urls(for: .documentDirectory,
                                            in: .userDomainMask)[0]
        let output = lines.joined(separator: "\n") + "\n"
        try! output.write(to: docs.appendingPathComponent("pasteboard.txt"),
                          atomically: true, encoding: .utf8)
        print(output, terminator: "")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exit(0) }
        return true
    }
}

_ = UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil,
                      NSStringFromClass(PasteboardProbeDelegate.self))
