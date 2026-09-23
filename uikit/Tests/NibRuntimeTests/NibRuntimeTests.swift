// The storyboard / NIB runtime against real iOS 26.1.
//
// Ground truth: fixtures/nibruntime/oracle/*.json, written by
// scripts/nib_runtime_probe_sim.sh on a private iPhone 16 / iOS 26.1
// simulator running THE SAME scenario sources (NibRuntimeScenario.swift,
// EidolonNibScenario.swift) over THE SAME compiled bytes
// (fixtures/nibruntime/NibRuntimeProbe.storyboardc,
// fixtures/realapp/eidolon/nibs). A test here fails when the port's
// transcript differs from the iOS one at any recorded path, and prints every
// differing path.
#if canImport(ObjectiveC)
import Foundation
import XCTest
@testable import OpenUIKit

@MainActor
final class NibRuntimeTests: XCTestCase {
    static let uikitRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()  // NibRuntimeTests
        .deletingLastPathComponent()  // Tests
        .deletingLastPathComponent()  // uikit
        .path

    static func oracle(_ name: String) throws -> [String: Any] {
        let url = URL(fileURLWithPath: uikitRoot + "/fixtures/nibruntime/oracle/" + name)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
    }

    /// Round-trip through JSON so both sides compare as the same types.
    static func normalized(_ object: Any) throws -> Any {
        let data = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        return try JSONSerialization.jsonObject(with: data)
    }

    /// Every path at which `ours` and `theirs` differ.
    static func differences(_ ours: Any?, _ theirs: Any?, path: String = "") -> [String] {
        switch (ours, theirs) {
        case (let a as [String: Any], let b as [String: Any]):
            // `ios.`-prefixed keys are recorded by the iOS probe alone.
            return Set(a.keys).union(b.keys).filter { !$0.hasPrefix("ios.") }.sorted().flatMap {
                differences(a[$0], b[$0], path: path + "." + $0)
            }
        case (let a as [Any], let b as [Any]):
            if a.count != b.count {
                return ["\(path): count \(a.count) vs iOS \(b.count): ours \(a) iOS \(b)"]
            }
            return zip(a, b).enumerated().flatMap { differences($1.0, $1.1, path: "\(path)[\($0)]") }
        case (let a as NSNumber, let b as NSNumber):
            return abs(a.doubleValue - b.doubleValue) < 0.0015 ? [] : ["\(path): \(a) vs iOS \(b)"]
        case (let a as String, let b as String):
            return a == b ? [] : ["\(path): \(a) vs iOS \(b)"]
        case (nil, nil):
            return []
        default:
            return ["\(path): \(String(describing: ours)) vs iOS \(String(describing: theirs))"]
        }
    }

    static func knownDivergences(_ transcript: String) throws -> Set<String> {
        let url = URL(fileURLWithPath: uikitRoot + "/fixtures/nibruntime/known_divergences.json")
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        return Set((root[transcript] as? [String: Any] ?? [:]).keys)
    }

    /// NIBRUNTIME_DUMP=<dir> writes the port's transcripts beside the
    /// oracle's names, for diffing by hand.
    static func dump(_ object: Any, _ name: String) {
        guard let dir = ProcessInfo.processInfo.environment["NIBRUNTIME_DUMP"],
              let data = try? JSONSerialization.data(withJSONObject: object,
                                                     options: [.prettyPrinted, .sortedKeys]) else { return }
        try? data.write(to: URL(fileURLWithPath: dir + "/" + name))
    }

    private var savedScreen = CGRect.zero
    private var savedScale: CGFloat = 1
    private var savedCut: FontEngine.SystemFontCut = .macOS

    override func setUp() {
        super.setUp()
        OpenUIKitRuntime.nibSearchPaths = [NibRuntimeTests.uikitRoot + "/fixtures/nibruntime"]
        UINib.unhandledKeys = []
        OpenUIKitRuntime.resourceRoot = NibRuntimeTests.uikitRoot + "/Sources/OpenUIKit/Resources"
        savedCut = OpenUIKitRuntime.systemFontCut
        OpenUIKitRuntime.systemFontCut = .iOS
        // The oracle ran on an iPhone 16: 393 x 852 pt @3x.
        savedScreen = UIScreen.main.bounds
        savedScale = UIScreen.main.scale
        UIScreen.main._hostConfigure(bounds: CGRect(x: 0, y: 0, width: 393, height: 852), scale: 3)
    }

    override func tearDown() {
        OpenUIKitRuntime.nibSearchPaths = []
        OpenUIKitRuntime.systemFontCut = savedCut
        UIScreen.main._hostConfigure(bounds: savedScreen, scale: savedScale)
        super.tearDown()
    }

    // MARK: Format pieces

    func testStoryboardInfoPlist() throws {
        let path = NibRuntimeTests.uikitRoot + "/fixtures/nibruntime/NibRuntimeProbe.storyboardc/Info.plist"
        let bytes = try XCTUnwrap(ResourceIO.readFile(path))
        let plist = try XCTUnwrap(BinaryPropertyList.parse(bytes))
        XCTAssertEqual(plist["UIStoryboardDesignatedEntryPointIdentifier"]?.string, "Nav")
        XCTAssertEqual(plist["UIStoryboardVersion"], .integer(1))
        XCTAssertEqual(plist["UIViewControllerIdentifiersToNibNames"]?.dictionary?.count, 7)
        XCTAssertEqual(plist["UIViewControllerIdentifiersToNibNames"]?["Root"]?.string, "Root")
        XCTAssertNil(BinaryPropertyList.parse(Array("bplist00".utf8) + [UInt8](repeating: 0, count: 40)))
    }

    func testSwiftClassNameResolution() {
        XCTAssertEqual(UINibClassRegistry.currentMangledName("_TtC5Kiosk17AppViewController"),
                       "5Kiosk17AppViewControllerC")
        XCTAssertEqual(UINibClassRegistry.currentMangledName("_TtCO4main5Outer5Inner"),
                       "4main5OuterO5InnerC")
        XCTAssertNil(UINibClassRegistry.currentMangledName("UILabel"))
        XCTAssertTrue(UINibClassRegistry.runtimeClass("_TtC15NibRuntimeTests23ProbeRootViewController")
                      == ProbeRootViewController.self)
        XCTAssertNil(UINibClassRegistry.runtimeClass("_TtC5Kiosk23ProbeRootViewController"))
        UINibClassRegistry.moduleAliases = ["Kiosk": "NibRuntimeTests"]
        defer { UINibClassRegistry.moduleAliases = [:] }
        XCTAssertTrue(UINibClassRegistry.runtimeClass("_TtC5Kiosk23ProbeRootViewController")
                      == ProbeRootViewController.self)
    }

    // MARK: The measured scenario

    /// UIStoryboard instantiation, init(coder:), outlets, outlet collections,
    /// runtime attributes, target-action, gesture recognizers, embed / show
    /// segues, identifier instantiation — every observation the iOS 26.1
    /// probe recorded.
    func testStoryboardScenarioMatchesiOS() throws {
        let ours = try NibRuntimeTests.normalized(NibProbe.run(storyboardName: "NibRuntimeProbe"))
        NibRuntimeTests.dump(ours, "nibruntime.json")
        let theirs = try NibRuntimeTests.oracle("nibruntime.json")
        let diffs = NibRuntimeTests.differences(ours, theirs)
        XCTAssert(diffs.isEmpty, "\(diffs.count) differences from iOS 26.1:\n" + diffs.joined(separator: "\n"))
    }

    /// Stack views with safe-area constraints, a table view controller's
    /// prototype cell, a tab bar controller's relationship children, and a
    /// plain xib with a custom File's Owner — against the same iOS run.
    func testStoryboardScenario2MatchesiOS() throws {
        let ours = try NibRuntimeTests.normalized(NibProbe.runExtended(storyboardName: "NibRuntimeProbe"))
        NibRuntimeTests.dump(ours, "nibruntime2.json")
        let theirs = try NibRuntimeTests.oracle("nibruntime2.json")
        let known = try NibRuntimeTests.knownDivergences("nibruntime2.json")
        let diffs = NibRuntimeTests.differences(ours, theirs)
        let differing = Set(diffs.map { String($0.prefix(while: { $0 != ":" })) })
        let unexpected = diffs.filter { !known.contains(String($0.prefix(while: { $0 != ":" }))) }
        XCTAssert(unexpected.isEmpty, "\(unexpected.count) differences from iOS 26.1:\n"
                  + unexpected.joined(separator: "\n"))
        XCTAssertEqual(known.subtracting(differing), [],
                       "known divergences that no longer differ: remove them from the list")
    }

    /// Eidolon's own compiled view archives, no app classes, against iOS
    /// loading the same bytes the same way. Archives iOS itself cannot load
    /// without the app (KeypadView.xib: NSUnknownKeyException) are checked to
    /// be exactly those, and the rest must match.
    func testEidolonViewArchivesMatchiOS() throws {
        let theirs = try NibRuntimeTests.oracle("eidolonnibs.json")
        let nibs = NibRuntimeTests.uikitRoot + "/fixtures/realapp/eidolon/nibs/"
        let sources = ["Auction": nibs + "Auction.storyboardc/",
                       "Fulfillment": nibs + "Fulfillment.storyboardc/",
                       "xib": nibs]
        var failures: [String] = []
        var compared = 0
        var dumped: [String: Any] = [:]
        defer { NibRuntimeTests.dump(dumped, "eidolonnibs.json") }
        for key in theirs.keys.sorted() {
            guard let expected = theirs[key] as? [String: Any] else { continue }
            let parts = key.split(separator: "/", maxSplits: 1).map(String.init)
            let path = sources[parts[0]]! + parts[1]
            if expected["exception"] != nil { continue }
            let bytes = try Data(contentsOf: URL(fileURLWithPath: path))
            let ours = try NibRuntimeTests.normalized(EidolonNibProbe.load(name: parts[1], bytes: bytes))
            dumped[key] = ours
            failures += NibRuntimeTests.differences(ours, expected, path: key)
            compared += 1
        }
        XCTAssertEqual(compared, 28)
        // Measured, explained divergences (fixtures/nibruntime/
        // known_divergences.json): tolerated at exactly those paths, and each
        // must still differ, so the list only shrinks when a gap closes.
        let known = try NibRuntimeTests.knownDivergences("eidolonnibs.json")
        let differing = Set(failures.map { String($0.prefix(while: { $0 != ":" })) })
        let unexpected = failures.filter { !known.contains(String($0.prefix(while: { $0 != ":" }))) }
        XCTAssert(unexpected.isEmpty, "\(unexpected.count) differences from iOS 26.1:\n"
                  + unexpected.prefix(80).joined(separator: "\n"))
        XCTAssertEqual(known.subtracting(differing), [],
                       "known divergences that no longer differ: remove them from the list")
    }

    /// ibtool archives a `white="1"` gray as `UISystemColorName = whiteColor`
    /// plus its components, and a label's default text colour as
    /// `labelColor` (fixtures/nibruntime/NibGuest.storyboardc). `whiteColor`
    /// is one of UIColor.h's fixed class colours (not appearance-dependent),
    /// so its archived components are the colour: nothing is unhandled.
    func testFixedNamedColorsDecodeFromComponents() throws {
        OpenUIKitRuntime.nibSearchPaths = [NibRuntimeTests.uikitRoot + "/fixtures/nibruntime"]
        let controller = try XCTUnwrap(UIStoryboard(name: "NibGuest", bundle: nil)
            .instantiateInitialViewController())
        let background = try XCTUnwrap(controller.view.backgroundColor)
        var white: CGFloat = -1, alpha: CGFloat = -1
        XCTAssertTrue(background.getWhite(&white, alpha: &alpha))
        XCTAssertEqual(white, 1, accuracy: 0.001)
        XCTAssertEqual(alpha, 1, accuracy: 0.001)
        // (The probe's own classes live in the guest module, so class /
        // outlet misses are expected here; colours are what this checks.)
        XCTAssertEqual(UINib.unhandledKeys.filter { $0.hasPrefix("UISystemColorName") || $0.hasPrefix("UIColor") }, [])
    }
}
#endif
