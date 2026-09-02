#if canImport(Foundation)
import Foundation
#elseif canImport(FoundationEssentials)
import FoundationEssentials
import OpenUIKit
#else
#error("The Bundle probe needs Foundation or FoundationEssentials + OpenUIKit")
#endif
import BundleProbeFramework

private func normalized(_ url: URL?, beneath root: URL) -> String {
    guard let url else { return "nil" }
#if canImport(Foundation)
    // macOS temporary directories may be spelled through `/var` while
    // Foundation reports a bundle through its `/private/var` target.
    let path = url.resolvingSymlinksInPath().path
    let rootPath = root.resolvingSymlinksInPath().path
#else
    let path = url.standardized.path
    let rootPath = root.standardized.path
#endif
    if path == rootPath { return "$ROOT" }
    if path.hasPrefix(rootPath + "/") {
        return "$ROOT" + path.dropFirst(rootPath.count)
    }
    return path
}

private func requirePath(
    _ actual: URL?,
    _ expected: URL,
    beneath root: URL,
    _ label: String
) {
    let actualPath = normalized(actual, beneath: root)
    let expectedPath = normalized(expected, beneath: root)
    precondition(actualPath == expectedPath, "\(label): \(actualPath) != \(expectedPath)")
    print("\(label)\t\(actualPath)")
}

private func requireNil(_ actual: URL?, _ label: String) {
    precondition(actual == nil, "\(label): expected nil, got \(String(describing: actual))")
    print("\(label)\tnil")
}

private func assertNamedResources(
    _ bundle: Bundle,
    expectedRoot: URL,
    fixtureRoot: URL,
    label: String
) {
    requirePath(bundle.bundleURL, expectedRoot, beneath: fixtureRoot, "\(label).bundleURL")
    let resources: URL
    if expectedRoot.pathExtension == "app" {
        resources = expectedRoot.appendingPathComponent("Contents/Resources", isDirectory: true)
    } else if expectedRoot.pathExtension == "framework" {
        resources = expectedRoot.appendingPathComponent("Resources", isDirectory: true)
    } else {
        resources = expectedRoot
    }
    requirePath(bundle.resourceURL, resources, beneath: fixtureRoot, "\(label).resourceURL")
    requirePath(
        bundle.url(forResource: "extensionless", withExtension: nil),
        resources.appendingPathComponent("extensionless"),
        beneath: fixtureRoot,
        "\(label).extensionless.nil"
    )
    requirePath(
        bundle.url(forResource: "extensionless", withExtension: ""),
        resources.appendingPathComponent("extensionless"),
        beneath: fixtureRoot,
        "\(label).extensionless.empty"
    )
    requirePath(
        bundle.url(forResource: "alpha", withExtension: "txt"),
        resources.appendingPathComponent("alpha.txt"),
        beneath: fixtureRoot,
        "\(label).alpha.txt"
    )
    requirePath(
        bundle.url(forResource: "alpha", withExtension: ".txt"),
        resources.appendingPathComponent("alpha.txt"),
        beneath: fixtureRoot,
        "\(label).alpha.dotExtension"
    )
    requirePath(
        bundle.url(forResource: "alpha.txt", withExtension: nil),
        resources.appendingPathComponent("alpha.txt"),
        beneath: fixtureRoot,
        "\(label).nameWithSuffix.nil"
    )
    requirePath(
        bundle.url(forResource: "alpha.txt", withExtension: ""),
        resources.appendingPathComponent("alpha.txt"),
        beneath: fixtureRoot,
        "\(label).nameWithSuffix.empty"
    )
    requirePath(
        bundle.url(forResource: "alpha.txt", withExtension: "txt"),
        resources.appendingPathComponent("alpha.txt.txt"),
        beneath: fixtureRoot,
        "\(label).nameWithSuffix.txt"
    )
    requirePath(
        bundle.url(forResource: "nested/child", withExtension: "txt"),
        resources.appendingPathComponent("nested/child.txt"),
        beneath: fixtureRoot,
        "\(label).nested"
    )
    requirePath(
        bundle.url(forResource: "nested/../alpha", withExtension: "txt"),
        resources.appendingPathComponent("alpha.txt"),
        beneath: fixtureRoot,
        "\(label).normalizedInsideRoot"
    )
    requireNil(
        bundle.url(forResource: "missing", withExtension: "txt"),
        "\(label).missing"
    )
}

precondition(CommandLine.arguments.count == 2, "usage: BundleProbe /absolute/fixture/root")
let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true).standardized
let mainRoot = root.appendingPathComponent("MainProbe.app", isDirectory: true)
let flatRoot = root.appendingPathComponent("Flat.bundle", isDirectory: true)
let structuredRoot = root.appendingPathComponent("Structured.app", isDirectory: true)
let frameworkRoot = root.appendingPathComponent("Probe.framework", isDirectory: true)
let dynamicRoot = mainRoot.appendingPathComponent(
    "Contents/Frameworks/DynamicProbe.framework",
    isDirectory: true
)

guard let filesystemRootBundle = Bundle(path: "/") else {
    fatalError("could not open filesystem root bundle")
}
let filesystemRootURL = URL(fileURLWithPath: "/", isDirectory: true)
requirePath(
    filesystemRootBundle.bundleURL,
    filesystemRootURL,
    beneath: root,
    "root.bundleURL"
)
requirePath(
    filesystemRootBundle.resourceURL,
    filesystemRootURL,
    beneath: root,
    "root.resourceURL"
)
let rootRelativeResource = String(root.path.dropFirst()) + "/root-child"
requirePath(
    filesystemRootBundle.url(forResource: rootRelativeResource, withExtension: "txt"),
    root.appendingPathComponent("root-child.txt"),
    beneath: root,
    "root.namedChild"
)

assertNamedResources(Bundle.main, expectedRoot: mainRoot, fixtureRoot: root, label: "main")

guard let flat = Bundle(path: flatRoot.path),
      let structured = Bundle(url: structuredRoot),
      let framework = Bundle(path: frameworkRoot.path) else {
    fatalError("could not open fixture bundles")
}
assertNamedResources(flat, expectedRoot: flatRoot, fixtureRoot: root, label: "flat")
assertNamedResources(structured, expectedRoot: structuredRoot, fixtureRoot: root, label: "structured")
assertNamedResources(framework, expectedRoot: frameworkRoot, fixtureRoot: root, label: "framework")

let dynamic = Bundle(for: BundleProbeFrameworkFinder.self)
assertNamedResources(dynamic, expectedRoot: dynamicRoot, fixtureRoot: root, label: "dynamic")

requireNil(Bundle(path: root.appendingPathComponent("missing.bundle").path)?.bundleURL, "init.missing")
requireNil(Bundle(path: root.appendingPathComponent("ordinary-file").path)?.bundleURL, "init.file")

#if !canImport(Foundation)
// Foundation treats nil/empty names with a nonempty extension as enumeration
// and permits paths to leave the resource root. Those broader contracts are
// outside this exact slice, so the fallback fails closed.
requireNil(flat.url(forResource: nil, withExtension: "txt"), "guest.nilName")
requireNil(flat.url(forResource: "", withExtension: "txt"), "guest.emptyName")
requireNil(flat.url(forResource: "../outside", withExtension: "txt"), "guest.parentEscape")
requireNil(flat.url(forResource: "leaf-escape", withExtension: "txt"), "guest.leafSymlink")
requireNil(
    flat.url(forResource: "via-outside/child", withExtension: "txt"),
    "guest.intermediateSymlink"
)
requireNil(flat.url(forResource: "inside-link", withExtension: "txt"), "guest.inRootSymlink")
print("BUNDLE_GUEST_SYMLINK_COMPONENT_GATE_OK")
print("BUNDLE_GUEST_FAIL_CLOSED_OK")
#endif

print("BUNDLE_ROOT_RESOURCE_CONTRACT_OK")
print("BUNDLE_EXACT_NAMED_RESOURCE_CONTRACT_OK")
