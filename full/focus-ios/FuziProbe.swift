import Foundation
import Fuzi

@main
struct FuziGuestProbe {
    static func main() throws {
        for path in CommandLine.arguments.dropFirst() {
            let document = try XMLDocument(data: Data(contentsOf: URL(fileURLWithPath: path)))
            guard let root = document.root else { fatalError("missing XML root") }
            let names = root.children(tag: "ShortName").map { $0.stringValue }
            print("name=" + names.joined(separator: "|"))
            for url in root.children(tag: "Url") {
                print("url=" + (url.attr("type") ?? "") + "|" + (url.attr("template") ?? ""))
                for param in url.children(tag: "Param") {
                    print("param=" + (param.attr("name") ?? "") + "|" + (param.attr("value") ?? ""))
                }
            }
        }
    }
}
