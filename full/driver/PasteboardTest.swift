// PasteboardTest.swift -- execute OpenUIKit's process-local UIPasteboard from
// the linked arm64 Mach-O guest, with Foundation deliberately unavailable.
//
// Native SwiftPM tests exercise URL bridging and concurrent access. This
// probe exercises the other half of the portability claim: the same source,
// including its CPortableIO mutex and named-store registry, links and runs
// against the staged Linux-hosted Darwin ABI without Foundation or Objective-C.

import OpenUIKit

private func pasteboardCheck(_ condition: @autoclosure () -> Bool,
                             _ label: String) -> Bool {
    let passed = condition()
    print("  \(label): \(passed ? "PASS" : "FAIL")")
    return passed
}

func pasteboardSelfTest() -> Bool {
    var ok = true
    let pasteboard = UIPasteboard.withUniqueName()
    let baseline = pasteboard.changeCount

    ok = pasteboardCheck(pasteboard.string == nil
                         && pasteboard.strings?.isEmpty == true
                         && !pasteboard.hasStrings
                         && pasteboard.numberOfItems == 0
                         && pasteboard.types(forItemSet: nil) == nil
                         && pasteboard.itemSet(withPasteboardTypes: ["missing"]) ==
                            IndexSet(),
                         "empty direct-access state") && ok

    pasteboard.strings = ["one", "two"]
    ok = pasteboardCheck(pasteboard.string == "one"
                         && pasteboard.strings == ["one", "two"]
                         && pasteboard.numberOfItems == 2
                         && pasteboard.changeCount == baseline + 1,
                         "string array and change count") && ok

    let image = UIImage(bitmap: Bitmap(width: 2, height: 3), scale: 1)
    pasteboard.image = image
    ok = pasteboardCheck(pasteboard.image === image
                         && pasteboard.images?.count == 1
                         && pasteboard.hasImages
                         && !pasteboard.hasStrings,
                         "image replaces string representation") && ok

    pasteboard.colors = [.red, .blue]
    ok = pasteboardCheck(pasteboard.color == .red
                         && pasteboard.colors == [.red, .blue]
                         && pasteboard.hasColors
                         && !pasteboard.hasImages,
                         "color array replaces image representation") && ok

    pasteboard.items = [
        ["public.alpha": "a", "public.shared": 1],
        ["public.beta": "b", "public.shared": 2],
    ]
    let second = IndexSet(integer: 1)
    ok = pasteboardCheck(pasteboard.types == ["public.alpha", "public.shared"]
                         && pasteboard.types(forItemSet: second) ==
                            [["public.beta", "public.shared"]]
                         && pasteboard.contains(pasteboardTypes: ["public.beta"],
                                                inItemSet: second)
                         && pasteboard.itemSet(withPasteboardTypes: ["public.beta"]) == second
                         && pasteboard.types(forItemSet: IndexSet()) == []
                         && pasteboard.values(forPasteboardType: "missing",
                                              inItemSet: nil)?.isEmpty == true,
                         "typed item and IndexSet queries") && ok

    pasteboard.setValue("replacement", forPasteboardType: "public.replacement")
    ok = pasteboardCheck(pasteboard.numberOfItems == 1
                         && pasteboard.types == ["public.replacement"],
                         "first-item setter replaces all items") && ok

    pasteboard.setItems([[UIPasteboard.typeAutomatic: "automatic"]])
    ok = pasteboardCheck(pasteboard.string == "automatic"
                         && pasteboard.types == ["public.utf8-plain-text"],
                         "automatic string normalization") && ok

    let name = UIPasteboard.Name("OpenUIKit.guest.pasteboard")
    UIPasteboard.remove(withName: name)
    let missingBeforeCreate = UIPasteboard(name: name, create: false) == nil
    guard let first = UIPasteboard(name: name, create: true),
          let secondHandle = UIPasteboard(name: name, create: false) else {
        print("  named pasteboard creation: FAIL")
        return false
    }
    first.string = "shared"
    UIPasteboard.remove(withName: name)
    ok = pasteboardCheck(missingBeforeCreate
                         && first.string == nil
                         && secondHandle.string == nil
                         && UIPasteboard(name: name, create: false) == nil,
                         "named removal clears every live handle") && ok

    secondHandle.string = "reattached"
    ok = pasteboardCheck(first.string == "reattached"
                         && UIPasteboard(name: name, create: false)?.string ==
                            "reattached",
                         "removed live handle reattaches its name") && ok

    ok = pasteboardCheck(UIPasteboard.general === UIPasteboard.general,
                         "general singleton identity") && ok
    UIPasteboard.general.string = "clear"
    UIPasteboard.remove(withName: .general)
    ok = pasteboardCheck(UIPasteboard.general.string == nil
                         && UIPasteboard.general.numberOfItems == 0
                         && UIPasteboard(name: .general, create: false) != nil,
                         "general removal clears but preserves its name") && ok
    return ok
}
