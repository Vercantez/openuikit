# Eidolon pinned runtime dependencies

Upstream source is byte-identical to the immutable revisions in [PROVENANCE.json](PROVENANCE.json). Version selection follows Eidolon `44486ed9149f16b3eb3a5e687f99ae078309f4fe` `Podfile.lock`; version tags were resolved to full commits before checkout. Each repository includes its upstream podspec and complete MIT license.

The tree contains 314 canonical Swift files and 18 byte-identical materializations of shared RxSwift Platform files in its two SwiftPM target directories (332 Swift files total). RxCocoa also carries four Objective-C runtime units. `upstream_path` identifies the original location of materialized copies. No source was modernized, replaced, or edited.

| Repository | Locked version | Immutable commit | Canonical Swift files |
|---|---|---|---:|
| RxSwift | 4.1.2 | `3e848781c7756accced855a6317a4c2ff5e8588b` | 252 |
| Moya | 11.0.0 | `0b90f7ee8dcc378fe48db18c8b281e8792244de9` | 25 |
| SwiftyJSON | 4.0.0 | `de309166a48a9dfc51d5bc4c55c0664d981de311` | 1 |
| Alamofire | 4.6.0 | `bc973c5311ce3db3f01a9fcde027fb11fa2254bf` | 17 |
| Result | 3.2.4 | `7477584259bfce2560a19e06ad9f71db441fff11` | 2 |
| Action | 3.5.0 | `9c413d35c3b0f14dd2a817c866415afd9a40e4db` | 7 |
| RxOptional | 3.3.0 | `2ae1c01d2a725ebbc7b75c8c1fc3623a54084b94` | 7 |
| NSObjectRx | 4.2.0 | `772b9c70cb59c51e9664f82037660fb97bfa621d` | 2 |
| Reachability | 4.1.0 | `06beeead15401a312622959654a2e9ec8cfa2cb9` | 1 |

Moya includes Core and RxSwift sources, matching the app’s `Moya/RxSwift` subspec. Its combined module uses `COCOAPODS`, as upstream specifies. RxSwift and RxCocoa select distinct copies of Platform sources to keep SwiftPM targets disjoint. Quick and Nimble are imported only by `KioskTests`; they are not launch dependencies and are not vendored here.

Apple Swift 6.2.1 in the app’s Swift 4 language mode emits all ten runtime Swift modules. This does not establish a runnable port: RxCocoa’s macOS target exposes `NSButton.rx.tap`, while Eidolon calls `UIButton.rx.tap`, and the latter is compiled only for iOS. A direct OpenUIKit probe fails at that exact call. Host Foundation/AppKit/SystemConfiguration and Objective-C-runtime availability are not guest evidence. See `docs/agent_reports/eidolon-launch-deps.md` for measurements.
