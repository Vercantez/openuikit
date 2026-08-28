import Dispatch
import Foundation
import XCTest
@testable import OpenUIKit

final class PasteboardTests: XCTestCase {
    private func freshPasteboard() -> UIPasteboard {
        UIPasteboard.withUniqueName()
    }

    func testDirectStringAndURLAccessMatchesIOSOracle() {
        let pasteboard = freshPasteboard()
        let baseline = pasteboard.changeCount

        XCTAssertNil(pasteboard.string)
        XCTAssertEqual(pasteboard.strings, [])
        XCTAssertNil(pasteboard.url)
        XCTAssertEqual(pasteboard.urls, [])
        XCTAssertFalse(pasteboard.hasStrings)
        XCTAssertFalse(pasteboard.hasURLs)

        pasteboard.string = "plain text"
        XCTAssertEqual(pasteboard.string, "plain text")
        XCTAssertEqual(pasteboard.strings, ["plain text"])
        XCTAssertNil(pasteboard.url)
        XCTAssertEqual(pasteboard.urls, [])
        XCTAssertTrue(pasteboard.hasStrings)
        XCTAssertFalse(pasteboard.hasURLs)
        XCTAssertEqual(pasteboard.types, ["public.utf8-plain-text"])
        XCTAssertEqual(pasteboard.changeCount - baseline, 1)

        pasteboard.string = nil
        XCTAssertNil(pasteboard.string)
        XCTAssertEqual(pasteboard.strings, [])
        XCTAssertEqual(pasteboard.changeCount - baseline, 2)

        pasteboard.strings = ["one", "two"]
        XCTAssertEqual(pasteboard.string, "one")
        XCTAssertEqual(pasteboard.strings, ["one", "two"])
        XCTAssertEqual(pasteboard.numberOfItems, 2)
        XCTAssertEqual(pasteboard.changeCount - baseline, 3)

        pasteboard.strings = []
        XCTAssertEqual(pasteboard.strings, [])
        XCTAssertEqual(pasteboard.numberOfItems, 0)
        XCTAssertEqual(pasteboard.changeCount - baseline, 4)

        let url = URL(string: "https://example.com/one")!
        pasteboard.url = url
        XCTAssertEqual(pasteboard.url, url)
        XCTAssertEqual(pasteboard.urls, [url])
        XCTAssertEqual(pasteboard.string, url.absoluteString)
        XCTAssertEqual(pasteboard.strings, [url.absoluteString])
        XCTAssertTrue(pasteboard.hasStrings)
        XCTAssertTrue(pasteboard.hasURLs)
        XCTAssertEqual(pasteboard.types, ["public.url", "public.utf8-plain-text"])
        XCTAssertEqual(pasteboard.changeCount - baseline, 5)

        pasteboard.url = nil
        XCTAssertEqual(pasteboard.urls, [])
        XCTAssertEqual(pasteboard.strings, [])
        XCTAssertEqual(pasteboard.changeCount - baseline, 6)

        let urls = [URL(string: "https://example.com/a")!,
                    URL(string: "https://example.com/b")!]
        pasteboard.urls = urls
        XCTAssertEqual(pasteboard.urls, urls)
        XCTAssertEqual(pasteboard.strings, urls.map(\.absoluteString))
        XCTAssertEqual(pasteboard.numberOfItems, 2)
        XCTAssertEqual(pasteboard.changeCount - baseline, 7)

        pasteboard.strings = ["https://example.com/as-text"]
        XCTAssertEqual(pasteboard.url?.absoluteString,
                       "https://example.com/as-text")
        XCTAssertTrue(pasteboard.hasURLs,
                      "real UIKit recognizes an absolute URL-shaped string")
        XCTAssertEqual(pasteboard.types, ["public.url", "public.utf8-plain-text"])
        XCTAssertEqual(pasteboard.changeCount - baseline, 8)
    }

    func testImageAndColorRepresentationsReplacePriorContent() {
        let pasteboard = freshPasteboard()
        let image = UIImage(bitmap: Bitmap(width: 2, height: 3), scale: 1)

        pasteboard.string = "old"
        pasteboard.image = image
        XCTAssertTrue(pasteboard.image === image)
        XCTAssertEqual(pasteboard.images?.count, 1)
        XCTAssertTrue(pasteboard.hasImages)
        XCTAssertFalse(pasteboard.hasStrings)
        XCTAssertFalse(pasteboard.hasURLs)
        XCTAssertEqual(pasteboard.strings, [])
        XCTAssertEqual(pasteboard.colors, [])
        XCTAssertEqual(pasteboard.types,
                       ["com.apple.uikit.image", "public.jpeg", "public.png"])
        XCTAssertNotNil(pasteboard.data(forPasteboardType: "public.png"))
        XCTAssertNotNil(pasteboard.data(forPasteboardType: "public.jpeg"))

        pasteboard.image = nil
        XCTAssertNil(pasteboard.image)
        XCTAssertEqual(pasteboard.images?.count, 0)
        XCTAssertFalse(pasteboard.hasImages)

        let png = Data(image.pngData()!)
        pasteboard.setData(png, forPasteboardType: "public.png")
        XCTAssertEqual(pasteboard.image?.bitmap.width, 2)
        XCTAssertEqual(pasteboard.image?.bitmap.height, 3)

        pasteboard.colors = [.red, .blue]
        XCTAssertEqual(pasteboard.color, .red)
        XCTAssertEqual(pasteboard.colors, [.red, .blue])
        XCTAssertTrue(pasteboard.hasColors)
        XCTAssertFalse(pasteboard.hasImages)
        XCTAssertEqual(pasteboard.images?.count, 0)

        pasteboard.colors = []
        XCTAssertNil(pasteboard.color)
        XCTAssertEqual(pasteboard.colors, [])
        XCTAssertFalse(pasteboard.hasColors)
    }

    func testItemModelRoundTripsAndFiltersIndexes() {
        let pasteboard = freshPasteboard()
        pasteboard.items = [
            ["public.alpha": "a", "public.shared": 1],
            ["public.beta": "b", "public.shared": 2],
        ]

        XCTAssertEqual(pasteboard.numberOfItems, 2)
        XCTAssertEqual(pasteboard.types, ["public.alpha", "public.shared"])
        XCTAssertTrue(pasteboard.contains(pasteboardTypes: ["missing", "public.alpha"]))
        XCTAssertFalse(pasteboard.contains(pasteboardTypes: ["missing"]))
        XCTAssertEqual(pasteboard.value(forPasteboardType: "public.alpha") as? String, "a")

        let second = IndexSet(integer: 1)
        XCTAssertEqual(pasteboard.types(forItemSet: second),
                       [["public.beta", "public.shared"]])
        XCTAssertTrue(pasteboard.contains(pasteboardTypes: ["public.beta"],
                                          inItemSet: second))
        XCTAssertFalse(pasteboard.contains(pasteboardTypes: ["public.alpha"],
                                           inItemSet: second))
        XCTAssertEqual(pasteboard.values(forPasteboardType: "public.shared",
                                         inItemSet: nil) as? [Int], [1, 2])
        XCTAssertEqual(pasteboard.itemSet(withPasteboardTypes: ["public.beta"]), second)
        XCTAssertEqual(pasteboard.types(forItemSet: IndexSet()), [])
        XCTAssertEqual(pasteboard.types(forItemSet: IndexSet(integer: 99)), [])
        let missingValues = pasteboard.values(forPasteboardType: "missing",
                                               inItemSet: nil)
        XCTAssertNotNil(missingValues)
        XCTAssertEqual(missingValues?.count, 0)
        XCTAssertEqual(pasteboard.itemSet(withPasteboardTypes: ["missing"]),
                       IndexSet())
        XCTAssertEqual(pasteboard.data(forPasteboardType: "missing",
                                       inItemSet: nil), [])
        XCTAssertEqual(pasteboard.data(forPasteboardType: "public.alpha",
                                       inItemSet: IndexSet()), [])

        let before = pasteboard.changeCount
        pasteboard.setValue("added", forPasteboardType: "public.extra")
        XCTAssertTrue(pasteboard.contains(pasteboardTypes: ["public.extra"]))
        XCTAssertEqual(pasteboard.types, ["public.extra"])
        XCTAssertEqual(pasteboard.numberOfItems, 1,
                       "real UIKit's first-item setter replaces the board")
        XCTAssertEqual(pasteboard.changeCount, before + 1)

        pasteboard.addItems([["public.gamma": "c"]])
        XCTAssertEqual(pasteboard.numberOfItems, 2)
        pasteboard.setItems([], options: [.localOnly: true])
        XCTAssertEqual(pasteboard.numberOfItems, 0)
        XCTAssertNil(pasteboard.types(forItemSet: nil))
        XCTAssertNil(pasteboard.values(forPasteboardType: "missing",
                                       inItemSet: nil))
        XCTAssertEqual(pasteboard.itemSet(withPasteboardTypes: ["missing"]),
                       IndexSet())
    }

    func testKnownRepresentationsAndAutomaticTypeMatchIOSOracle() {
        let pasteboard = freshPasteboard()
        let hello = Data("hello".utf8)

        pasteboard.addItems([["public.utf8-plain-text": hello]])
        XCTAssertEqual(pasteboard.strings, ["hello"])
        XCTAssertEqual(pasteboard.data(forPasteboardType: "public.utf8-plain-text",
                                       inItemSet: nil), [hello])

        pasteboard.items = [["custom.string": "ignored"]]
        XCTAssertNil(pasteboard.string)
        XCTAssertEqual(pasteboard.strings, [])
        XCTAssertFalse(pasteboard.hasStrings)

        pasteboard.items = [["public.text": "abstract"]]
        XCTAssertEqual(pasteboard.string, "abstract")
        XCTAssertTrue(pasteboard.hasStrings)
        pasteboard.items = [["public.text": hello]]
        XCTAssertEqual(pasteboard.string, "hello")
        pasteboard.items = [["public.plain-text": "plain"]]
        XCTAssertEqual(pasteboard.string, "plain")
        XCTAssertTrue(pasteboard.hasStrings)
        pasteboard.items = [["public.plain-text": hello]]
        XCTAssertEqual(pasteboard.string, "hello")

        let image = UIImage(bitmap: Bitmap(width: 2, height: 3), scale: 1)
        let png = Data(image.pngData()!)
        pasteboard.items = [["custom.png": png]]
        XCTAssertNil(pasteboard.image)
        pasteboard.items = [["com.apple.uikit.image": png]]
        XCTAssertNil(pasteboard.image,
                     "UIKit does not decode raw data under its object-image UTI")
        XCTAssertNil(pasteboard.data(forPasteboardType: "com.apple.uikit.image"))
        XCTAssertTrue(pasteboard.hasImages,
                      "UIKit's has query recognizes the declared type")
        pasteboard.items = [["public.png": png]]
        XCTAssertEqual(pasteboard.image?.bitmap.width, 2)

        let url = URL(string: "https://example.com/item")!
        pasteboard.items = [["public.url": url]]
        XCTAssertEqual(pasteboard.string, url.absoluteString)
        XCTAssertEqual(pasteboard.url, url)
        XCTAssertNil(pasteboard.data(forPasteboardType: "public.url"),
                     "OpenUIKit does not reproduce UIKit's opaque URL archive")
        pasteboard.items = [["public.url": url.absoluteString]]
        XCTAssertNil(pasteboard.string)
        XCTAssertNil(pasteboard.url)
        XCTAssertTrue(pasteboard.hasStrings)
        XCTAssertTrue(pasteboard.hasURLs)
        pasteboard.items = [["public.url": Data(url.absoluteString.utf8)]]
        XCTAssertNil(pasteboard.string)
        XCTAssertNil(pasteboard.url)
        XCTAssertTrue(pasteboard.hasStrings)
        XCTAssertTrue(pasteboard.hasURLs)

        pasteboard.setItems([[UIPasteboard.typeAutomatic: "automatic text"]])
        XCTAssertEqual(pasteboard.types, ["public.utf8-plain-text"])
        XCTAssertEqual(pasteboard.string, "automatic text")
        pasteboard.setItems([[UIPasteboard.typeAutomatic: url]])
        XCTAssertEqual(pasteboard.types,
                       ["public.url", "public.utf8-plain-text"])
        XCTAssertEqual(pasteboard.url, url)
        pasteboard.setItems([[UIPasteboard.typeAutomatic: image]])
        XCTAssertEqual(pasteboard.types,
                       ["com.apple.uikit.image", "public.jpeg", "public.png"])
        pasteboard.setItems([[UIPasteboard.typeAutomatic: UIColor.red]])
        XCTAssertEqual(pasteboard.types, ["com.apple.uikit.color"])
        XCTAssertEqual(pasteboard.color, .red)
        XCTAssertNil(pasteboard.data(forPasteboardType: "com.apple.uikit.color"),
                     "OpenUIKit does not reproduce UIKit's opaque color archive")

        pasteboard.items = [["one": 1], ["two": 2]]
        pasteboard.setData(hello, forPasteboardType: "public.utf8-plain-text")
        XCTAssertEqual(pasteboard.numberOfItems, 1)
        XCTAssertEqual(pasteboard.string, "hello")
    }

    func testNamedPasteboardsShareInvalidateAndReattach() {
        let name = UIPasteboard.Name("OpenUIKit.PasteboardTests.named")
        UIPasteboard.remove(withName: name)
        XCTAssertNil(UIPasteboard(name: name, create: false))

        let first = UIPasteboard(name: name, create: true)!
        let second = UIPasteboard(name: name, create: false)!
        first.string = "shared"
        XCTAssertEqual(second.string, "shared")
        XCTAssertEqual(first.name, name)

        first.setPersistent(true)
        XCTAssertTrue(second.isPersistent)

        UIPasteboard.remove(withName: name)
        XCTAssertNil(UIPasteboard(name: name, create: false))
        XCTAssertNil(first.string)
        XCTAssertNil(second.string)

        second.string = "reattached"
        XCTAssertEqual(first.string, "reattached")
        XCTAssertEqual(UIPasteboard(name: name, create: false)?.string,
                       "reattached",
                       "mutating a removed live handle reattaches its name")
        UIPasteboard.remove(withName: name)
    }

    func testGeneralIsAStableSingleton() {
        XCTAssertTrue(UIPasteboard.general === UIPasteboard.general)
        XCTAssertEqual(UIPasteboard.general.name, .general)
        XCTAssertEqual(UIPasteboard.Name.general.rawValue,
                       "com.apple.UIKit.pboard.general")
        XCTAssertEqual(UIPasteboard.OptionsKey.expirationDate.rawValue,
                       "expirationDate")
        XCTAssertEqual(UIPasteboard.OptionsKey.localOnly.rawValue, "localOnly")
        XCTAssertEqual(UIPasteboard.typeAutomatic, "com.apple.uikit.type-automatic")
        XCTAssertEqual(UIPasteboard.typeListString,
                       ["public.utf8-plain-text", "public.text"])
        XCTAssertEqual(UIPasteboard.typeListURL, ["public.url"])
        XCTAssertEqual(UIPasteboard.typeListImage,
                       ["public.png", "public.jpeg", "com.compuserve.gif",
                        "com.apple.uikit.image"])
        XCTAssertEqual(UIPasteboard.typeListColor, ["com.apple.uikit.color"])

        UIPasteboard.general.string = "clear me"
        let beforeRemoval = UIPasteboard.general.changeCount
        UIPasteboard.remove(withName: .general)
        XCTAssertNil(UIPasteboard.general.string)
        XCTAssertEqual(UIPasteboard.general.numberOfItems, 0)
        XCTAssertNotEqual(UIPasteboard.general.changeCount, beforeRemoval)
        XCTAssertNotNil(UIPasteboard(name: .general, create: false))
    }

    func testUniqueNamesDoNotOverwriteExplicitlyCreatedNames() {
        let first = freshPasteboard()
        let prefix = "OpenUIKit.unique."
        let suffix = first.name.rawValue.dropFirst(prefix.count)
        let next = Int(suffix)! + 1
        let reservedName = UIPasteboard.Name("\(prefix)\(next)")
        let reserved = UIPasteboard(name: reservedName, create: true)!
        reserved.string = "reserved"

        let generated = freshPasteboard()
        XCTAssertNotEqual(generated.name, reservedName)
        XCTAssertEqual(reserved.string, "reserved")
        UIPasteboard.remove(withName: reservedName)
    }

    func testReentrantValueDeinitializerRunsAfterStorageUnlocks() {
        final class ReentrantValue {
            let onDeinit: () -> Void
            init(onDeinit: @escaping () -> Void) { self.onDeinit = onDeinit }
            deinit { onDeinit() }
        }

        let pasteboard = freshPasteboard()
        let released = expectation(description: "reentrant value released")
        var value: ReentrantValue? = ReentrantValue { [weak pasteboard] in
            pasteboard?.string = "from deinit"
            released.fulfill()
        }
        pasteboard.setValue(value!, forPasteboardType: "custom.object")
        value = nil

        pasteboard.items = []
        wait(for: [released], timeout: 1)
        XCTAssertEqual(pasteboard.string, "from deinit")
    }

    func testConcurrentWritesAreSerialized() {
        let pasteboard = freshPasteboard()
        let baseline = pasteboard.changeCount
        let iterations = 200

        DispatchQueue.concurrentPerform(iterations: iterations) { index in
            pasteboard.string = "value-\(index)"
        }

        XCTAssertEqual(pasteboard.changeCount - baseline, iterations)
        XCTAssertEqual(pasteboard.numberOfItems, 1)
        XCTAssertNotNil(pasteboard.string)
    }

    func testConcurrentRemovalAndMutationStayRegistryLinearizable() {
        let queue = DispatchQueue(label: "PasteboardTests.registry",
                                  attributes: .concurrent)

        for iteration in 0..<200 {
            let name = UIPasteboard.Name("OpenUIKit.PasteboardTests.race.\(iteration)")
            UIPasteboard.remove(withName: name)
            let pasteboard = UIPasteboard(name: name, create: true)!
            pasteboard.string = "before"

            let group = DispatchGroup()
            group.enter()
            queue.async {
                UIPasteboard.remove(withName: name)
                group.leave()
            }
            group.enter()
            queue.async {
                pasteboard.string = "after"
                group.leave()
            }
            group.wait()

            if let attached = UIPasteboard(name: name, create: false) {
                XCTAssertEqual(attached.string, "after",
                               "an attached board must contain the later write")
            } else {
                XCTAssertNil(pasteboard.string,
                             "a later removal must clear every live handle")
            }
            UIPasteboard.remove(withName: name)
        }
    }
}
