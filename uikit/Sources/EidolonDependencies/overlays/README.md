# Build-time overlays for vendored Eidolon dependencies

The vendored sources stay byte-identical to PROVENANCE.json. Where the current
toolchain (Xcode 26.1 / Swift 6.2.1) rejects a locked dependency, the smallest
compile-only change is kept here as a patch. The `EidolonSourceOverlay`
SwiftPM build-tool plugin (`Plugins/EidolonSourceOverlay`) applies it at build
time to the pristine file (the target excludes the original). The real-UIKit
golden build of Eidolon applies the same patch files to its CocoaPods
checkout, so the port and the golden compile identical source.

| patch | why | behaviour |
|---|---|---|
| `RxTableViewReactiveArrayDataSource.swift.patch`, `RxCollectionViewReactiveArrayDataSource.swift.patch` (RxCocoa 4.1.2) | The SequenceWrapper subclass declares `typealias Element = S`, which Swift 6.2.1 lets shadow the inherited `CellFactory`'s `Element`, so its pass-through `override init(cellFactory:)` "does not override a designated initializer". MEASURED against Apple's own UIKit (stock iPhoneSimulator26.1 SDK) with `repro-cellFactory-init.swift` here: `xcrun --sdk iphonesimulator swiftc -typecheck -swift-version 4 -target arm64-apple-ios26.1-simulator repro-cellFactory-init.swift` fails the same way. Not an OpenUIKit issue. | Deleting the redundant override (its body is only `super.init(cellFactory:)`) makes the subclass inherit the identical designated initializer. |

Why not exclude the two files: RxCocoa's own `UITableView+Rx` / `UICollectionView+Rx`
(`rx.items`) reference these classes, so the module needs them even though
Eidolon's Kiosk does not call `rx.items`.
