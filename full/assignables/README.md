# Assignables (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`Assignables` module, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol graph,
API digester, TBD exports, and pinned `dotnet/macios` bindings (none of the
latter name this module). It is not wired into the shared guest package; that
integration is a later central-review step.

The isolated host gate (`bash tests/acceptance/test_host.sh`) compiles against
the **toolchain** Foundation. It is not an integrated Linux/EC2 guest-Foundation
result. A future EC2 run must build guest Foundation first, build this module
with those `-I/-L` paths, and execute
`tests/agent/AssignablesDependencyIdentity.swift`.

Environment marker used by this campaign:

`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`

## What is real

- `StringUserIdentity`, `AnonymousUserIdentity`, and `AnyUserIdentity` box
  `typeID` + `stringRepresentation`, round-trip through `Codable`, and nest
  `scope` on a process-local stack. `UserIdentityFactory.string` /
  `.anonymous` and `UserIdentityTypeRegistry.registerUserIdentityType` are
  process-local.
- `MergeablePartsContainerPartID` stores a `rawValue`. Well-known
  `AssignableDocument.PartIDs` / `AssignedWorkDocument.PartIDs` use the public
  property names as those strings.
- `AssignableDocument` is a process-local assignment: questions, boxes,
  pages, authors, configuration, sync `merge`, `makePart` JSON for question
  boxes/authors, `appendQuestion` / `removeQuestion`, subscripts, and
  `computeMaxScore` (sum of question max scores, optional configuration cap).
- `AssignedWorkDocument` keeps assignees, scorers, and `ScoreAnnotation`
  values. `computeScore()` uses `manualScore` when set, otherwise
  `correct * pointsPerCorrect + incorrect * pointsPerIncorrect + bonus * pointsPerBonus`.
- `AssignedWorkDocument.ScoreAnnotation.Kind` raw values follow API-digester
  child order: `unknown = 0`, `incorrect = 1`, `correct = 2`, `bonus = 3`.
- `AssignableDocument.CorrectMarkType` is `CaseIterable` in digester order
  (`checkmark`, `star`, `numeric`, `unknown`).
- `AssignableDocumentView` / `AssignedWorkDocumentView` retain bindings and
  flags; `body` is `EmptyView`.

Host-compiled sources import Foundation only. The identity probe
`tests/agent/AssignablesDependencyIdentity.swift` imports `Assignables` and
`Foundation` for the later EC2 integration build.

## Fail-closed boundaries

Linux has no PDFKit, Schoolwork, PencilKit markup, or SwiftUI layout engine.

- `AssignableDocument.init(pdfURL:id:)` and `init(pdfURL:authors:id:)` always
  throw `AssignableDocument.Error.invalidURL`.
- `exportToPDF` / `exportBaseAsPDF` return an empty `PDFDocument` (`pageCount`
  0) and never invent assignment pages.
- `pageThumbnails` / `questionThumbnails` return empty dictionaries. Thumbnail
  `UIImage` pixels are not produced.
- View markup/Pencil closures are retained and never invoked from public APIs.
- Identity `View` modifiers in `AssignablesViewSurface.swift` are **declared**,
  not implemented: there is no SwiftUI layout engine.

## Deferred / unobserved

Apple's `typeID` strings, part-id raw values, PDF error taxonomy, score
clamping vs `maxScore`, and `UserIdentity.scope` isolation remain oracle
questions. Async export/merge/thumbnail overlays are declared because the
sealed runner has no run loop.

Run the sealed host gate with:

```sh
bash full/assignables/tests/acceptance/test_host.sh
```

## Depth pass 2026-09

Exact public IDs: **1886**. Nondeferred floor for `medium-full` is 943.

- After this seed: implemented **314** / declared **1572** / deferred **0**
  (1572 includes 1536 synthesized SwiftUI.View members plus async PDF/export
  overlays the host runner cannot await).
- Top-5 implemented evidence distribution (314 rows):
  1. `AssignablesDocumentTests.swift#testAssignableDocumentInit` — 30
  2. `AssignablesWorkTests.swift#testWorkPages` — 19
  3. `AssignablesIdentityTests.swift#testStringUserIdentity` — 18
  4. `AssignablesIdentityTests.swift#testAnonymousUserIdentity` / `AssignablesEnumTests.swift#testCorrectMarkTypeCases` / `AssignablesEnumTests.swift#testScoreAnnotationKindRawValues` — 14 each
  5. `AssignablesIdentityTests.swift#testAnyUserIdentityBoxing` / `AssignablesQuestionTests.swift#testQuestionInit` — 13 each
- Enum/option-set members share table-driven tests (`testCorrectMarkTypeCases`,
  `testScoreAnnotationKindRawValues`, `testMergeablePartDataCases`). No other
  single test exceeds 40% of the remaining implemented rows (largest remaining
  citation is 30/314 ≈ 9.6%).

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
absent on this VM. The sealed gate compiles with a clean product tree
(`products=clean`). Active Cursor Build observed on this run was
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` (campaign expected
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Starting commit
`cbb368eeea236bbc0479fefa599190972ac8cfca` matched.

`origin/agent/fw-assignables` did not exist; this pass publishes that
branch from the Cursor-created work branch.

`bash full/assignables/tests/acceptance/test_host.sh` ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=Assignables lane=medium-full symbols=1886
FRAMEWORK_FANOUT_REFERENCE_OK
ASSIGNABLES_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=Assignables dylib=libAssignables.dylib
```

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` is a host-inventory token, not printed by the sealed framework gate. `swiftc` is Swift 6.2.4 / linux and the gate compiled with a clean product tree.

## Depth pass 2026-09 (wave 8)

This wave started at **314 implemented / 1572 declared / 0 deferred / 0
unavailable / 0 not-applicable** and ends at **343 implemented / 1543 declared /
0 deferred / 0 unavailable / 0 not-applicable**. It exhausts the behaviorally
reachable non-SwiftUI remainder: all 29 async identity, initialization, merge,
part-export, PDF-export, and thumbnail methods now have bounded, synchronous
runner evidence. The tests use a detached structured-concurrency task and an
`NSCondition` deadline; they do not require a main queue or run loop.

The 1536 `s:7SwiftUI4View...` rows remain `declared` rather than
`not-applicable`. The depth-pass instruction calls for `not-applicable`, but the
immutable sealed validator simultaneously requires 943 `implemented` or
`declared` rows; excluding those overlays leaves only 350 framework-owned rows
and makes the supplied gate fail before compilation. This contradictory seed
constraint remains a central-review question and was not bypassed or weakened.
The seven question-thumbnail value rows remain declared because their graph
surface exposes no public initializer and Linux intentionally returns no raster
objects; claiming a behavioral test would require adding non-Apple API or
fabricating pixels.

Top-5 implemented evidence distribution (343 rows):

1. `AssignablesDocumentTests.swift#testAssignableDocumentInit` — 30
2. `AssignablesWorkTests.swift#testWorkPages` — 19
3. `AssignablesIdentityTests.swift#testStringUserIdentity` — 18
4. `AssignablesIdentityTests.swift#testAnonymousUserIdentity`,
   `AssignablesEnumTests.swift#testCorrectMarkTypeCases`, and
   `AssignablesEnumTests.swift#testScoreAnnotationKindRawValues` — 14 each
5. `AssignablesIdentityTests.swift#testAnyUserIdentityBoxing` and
   `AssignablesQuestionTests.swift#testQuestionInit` — 13 each

Wave 8 was run with the verified campaign environment marker
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=scratch-corpus evidence=dotnet-macios`.
