# UIKit `#Preview` portability boundary

OpenUIKit supplies a real Swift declaration macro for the first UIKit Preview
source shape used by the pinned Reminder app:

```swift
#Preview {
    CreateViewController(initialDate: Date())
}
```

The macro is not a parser trick or a no-op. Its native build-host executable
emits target-side `DeveloperToolsSupport.PreviewRegistry` metadata with the
source file ID, line, column, and a `makePreview()` function. The resulting
`Preview` retains the original main-actor body and can evaluate it to the same
`UIView` or `UIViewController` instance. A renderer and interactive preview
host do not exist yet, so this is functional registration metadata rather than
an Xcode Previews replacement.

## Capability boundary

This slice accepts exactly an unnamed trailing closure whose single result is
an OpenUIKit `UIView` or `UIViewController`. It intentionally rejects named
previews, traits, additional trailing closures, multiple body expressions,
control-flow builders, non-UIKit content, and direct access to the retained
body SPI. Those surfaces require additional native measurements and should
not silently acquire invented behavior.

The public availability boundary is iOS 17, macOS 14, and tvOS 17. The emitted
registry also uses the measured visionOS 1 and watchOS 10 availability shape.
The target-side module does not depend on SwiftSyntax. SwiftSyntax and the
compiler plugin execute only on the build host, including when `swiftc`
emits ARM64 Mach-O application objects from Linux.

On Apple SDK hosts, some XCTest tool graphs already load Apple's module named
`DeveloperToolsSupport`. Swift cannot load that SDK module and OpenUIKit's
portable module of the same name into one source graph as distinct modules.
The focused native client therefore tests the real app topology (`import
UIKit`, without XCTest) and does not claim mixed-XCTest cohabitation. The
Linux-hosted Mach-O application has no Apple DeveloperToolsSupport binary and
uses the portable target unambiguously. A conditional native-module strategy
for OpenUIKit test bundles is separate work.

`Tools/previewprobe/run.sh` builds the macro and a literal `import UIKit`
client from fresh external scratch. It proves real body identity, two registry
expansions and source locations, the missing-plugin failure, named-preview
failure, SPI protection, native host executable format, and explicit target
object format. `Tools/reminderpreviewprobe/run.py` pins the entire unchanged
22-source app and its one-to-zero diagnostic delta. Its companion guest gate
uses the production Foundation-facade ordering so the host-native plugin is
tested in the same ARM64 Mach-O application path rather than only in an
isolated macro fixture.

The guest consumes the exact external Reminder project inventory rather than
silently regenerating it. Its SHA-256 is
`2e099b5f7b67e7f48deb9bc59219d2fede6cd138daf00a3e2f7d078822006e2b`;
the inventory names 22 Swift sources and two resource inputs and is reverified
against the clean pinned app before and after compilation/package assembly.

The end-to-end wrapper composes, rather than duplicates, the canonical guest
framework and application drivers. Its immutable support input is commit
`39643c4cf824f5ef6b62eb1d24c253e7290c0e50`, tree
`3bf0334c0dd264ec07e77d7b33aff10436be812d`; the loader input is machorun
commit `e6b1745bef09ac8f1e2d6e6c83f7c70d6dbe49a5`, tree
`1b41ede32d9a3ba2a5ec2d37685dc64b4eee9b43`. The Linux/aarch64 build host is
the exact image ID
`sha256:85f9d4c5089ef811c53c55be5e8683f0f582cc9b158f9d9c5348331f3dec4044`.
Its `swiftc` executable SHA-256 is
`5a7209655c37a4f4937ea5219a4af59a7c9fc52dd13c615f26682642bc3a83ff`.
The frozen plan products are pinned independently: application plan
`9d8f727b088a93514342aca4f056df8add9dcb40823bd526439f8301c6515cca`,
generated bootstrap
`224c87feb842c5a7bced67f6ce6a4fd1512f458f6b61090e3f11db754f424859`,
ordered source list
`964801e9db1d7e690d0bdce18c5993e23879b7f2cb3a8d2fb055108b66fd0e01`,
and prepared-input record
`0d100cac034975110e64b5c162cbc88debf178d3c6002498b7cde940e0291df8`.
All plugin, target-module, compiler cache, core package, and application output
roots are new. Candidate, support, loader, and app inputs remain read-only or
are bracketed by exact clean commit/tree checks.

## OpenSwiftUI provenance

The registry/source-location skeleton was adapted from OpenSwiftUI under the
MIT license. Specifically, OpenUIKit retained the use of
`MacroExpansionContext.location` at `.afterLeadingTrivia` with `.fileID`, a
compiler-unique registry name, the measured registry availability, and the
`PreviewRegistry`/`makePreview()` structure. OpenUIKit replaced OpenSwiftUI's
argument forwarding and view-hosting transformation with a bounded UIKit
body, dot-qualified portable Swift syntax, and the independently measured
single-expression UIKit wrapper. No renderer, OpenSwiftUI view, or hosting
controller implementation was copied.

The immutable provenance is:

| item | exact pin |
|---|---|
| OpenSwiftUI repository | `https://github.com/OpenSwiftUIProject/OpenSwiftUI.git` |
| OpenSwiftUI commit | `7dc2cee2132bdf59d1fa0dc851121aede28f2edf` |
| OpenSwiftUI tree | `dfae759d9a119afd1e5ccd5c4dfe0edc51699e85` |
| `Sources/OpenSwiftUIMacros/PreviewMacro.swift` SHA-256 | `f506cda6af95cd94bd4e7054c022a3c760ed776d688ff526733c67078136577f` |
| `Sources/OpenSwiftUI/Macro/PreviewMacro.swift` SHA-256 | `3c7df2e251c29e396be7d1cde64994cef3e9fd343075782bc69d939e17a6acb1` |
| upstream `LICENSE` and copied `THIRD_PARTY_LICENSES/OpenSwiftUI.txt` SHA-256 | `e3976a926431bd88d2ababcf89764f4ae5b6e7da9be4cda979dc1e50d05f2586` |
| SwiftSyntax dependency revision | `4799286537280063c85a32f09884cfbca301b1a1` |
| SwiftSyntax dependency tree | `4c96b84ec6f59391ca70d18191500c14854d3d91` |

The OpenSwiftUI repository, source files, and license were read from a clean
immutable checkout. They are provenance inputs only; OpenUIKit does not link
or package OpenSwiftUI.

## Native oracle

An iOS 26.1 SDK oracle containing only `import UIKit` and an unnamed
controller preview was compiled with macro expansions enabled. Oracle source
SHA-256 is `47a06df5611da3a0052a75950c4c9d8e79bd220293dcb5fbbde933acf8802d1a`;
the captured expansion SHA-256 is
`da72eaeb522c4464ac048cc00c1680c4fe62dcc2235446c4a8526305f14e0867`.
The iOS 26.1 `DeveloperToolsSupport` arm64e Swift interface SHA-256 is
`e3204dbc116fc410ff9623abdf0c7cb01245b3c9076ded2bbeeda3b701144c88`;
the corresponding UIKit interface SHA-256 is
`c1c37f1c73b89a95485a8c1adc8ee82a68c722bf1181e0830d25eb5e6806f956`.
It establishes the generated availability, unique registry, source metadata,
throwing `makePreview`, `DeveloperToolsSupport.Preview` construction, and
local one-expression result-builder wrapper. It does not establish named or
trait behavior, registry discovery, rendering, or host lifecycle.

## Remaining end-to-end work

Compiling a Preview does not itself launch an app or display a preview canvas.
A future host must discover registry conformances, choose/evaluate one on the
main actor, install the returned view/controller in an OpenUIKit window, and
drive the existing layout/render/event loop. That host must remain separate
from the compiler plugin: target processes must never load SwiftSyntax merely
to evaluate a retained preview body.
