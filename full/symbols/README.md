# Symbols (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`Symbols` module, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol graph, API
digester, and TBD exports. It is not wired into the shared guest package; that
integration is a later central-review step.

The module is a **value-type configuration surface** for SF Symbol animations
(`SymbolEffect` and friends). Linux implements those values. It does not render
symbols, drive Core Animation, or claim SwiftUI/UIKit `symbolEffect` playback.

## Depth pass 2026-09

Coverage of the 201 exact public identifiers (fresh seed: no prior
implementation, coverage, or agent tests):

- **before:** 0 implemented / 0 declared / 0 deferred / 0 unavailable
- **after:** 201 implemented / 0 declared / 0 deferred / 0 unavailable

Every public identifier is a protocol, marker, hashable effect struct, modifier,
or `SymbolEffectOptions` token. Those are portable. The 20-app corpus summary
lists no Symbols rankings (`requestedFamilies` empty); apps consume these types
through SwiftUI/UIKit, which remain out of this leaf module.

Top-5 evidence distribution (of 201 implemented rows; 40% cap = 80):

1. `VariableColorWiggleTests.swift#testWiggleSymbolEffect` — 19 (9.5%)
2. `DrawReplaceAutomaticTests.swift#testReplaceSymbolEffect` — 16 (8.0%)
3. `VariableColorWiggleTests.swift#testVariableColorSymbolEffect` — 14 (7.0%)
4. `DrawReplaceAutomaticTests.swift#testDrawOffSymbolEffect` — 13 (6.5%)
5. `PulseScaleAppearTests.swift#testScaleSymbolEffect` (and four other
   12-row family tests) — 12 (6.0%)

No test is cited by more than 40% of implemented rows. There are no public
enum/option-set/C-constant catalogs; each family has its own focused test.

## What is real

`libSymbols.dylib` compiles the overlay with `-warnings-as-errors`.

- `SymbolEffect` requires `configuration`. Constrained extensions expose
  `.pulse`, `.bounce`, `.variableColor`, `.scale`, `.appear`, `.disappear`,
  `.replace`, `.automatic`, `.wiggle`, `.rotate`, `.breathe`, `.drawOn`, and
  `.drawOff`.
- Marker protocols `DiscreteSymbolEffect`, `IndefiniteSymbolEffect`,
  `TransitionSymbolEffect`, and `ContentTransitionSymbolEffect` match the
  graph `conformsTo` edges (for example `ScaleSymbolEffect` is indefinite
  only; `ReplaceSymbolEffect` is a content transition).
- Modifiers are last-write-wins on that axis (`byLayer` / `wholeSymbol` /
  `individually`; `up` / `down`; variable-color fill, reverse, and inactive
  layers; wiggle motion including `custom(angle:)`; draw-off reverse).
  Unmodified axes stay unspecified instead of inventing Apple renderer
  defaults.
- `ReplaceSymbolEffect.upUp` / `offUp` / `downUp` static factories equal the
  instance modifiers on `.replace`. `magic(fallback:)` snapshots the receiver
  and the fallback into `MagicReplace`.
- `SymbolEffectOptions` stores speed and a repeat mode. Static factories
  (`speed(_:)`, `repeating`, `repeat(_:)`) produce a fresh value; instance
  methods keep the other axis. `RepeatBehavior.periodic` is
  `periodic(nil, delay: nil)` per the default-argument signature.
- `SymbolEffectConfiguration` is an opaque `Hashable` snapshot. Equal effects
  have equal configurations; different kinds never compare equal.

`tests/agent/SymbolsLoadSmoke.swift` is the canonical schema-v2 marker source.
The sealed gate derives its runner from `implemented` coverage and
`*Tests.swift`.

## Fail-closed boundaries

- No SF Symbol asset catalog, Core Animation player, or SwiftUI/UIKit view
  exists in this module. Effects never "run".
- `NSSymbolEffect` / `NSSymbolContentTransition` ObjC classes from TBD
  exports are not in the 201-ID Swift census and are not invented here.
  There is no `objcEffect` bridging success path.
- Unmodified effect defaults (layer, bounce direction, whether `repeating`
  equals `repeat(.continuous)`) are not claimed. See `oracle-questions.tsv`.
- `RepeatBehavior` is not independently `Equatable` in the census; compare
  behaviors by applying them to `SymbolEffectOptions`.

## Tests

- `tests/agent/SymbolsLoadSmoke.swift` — canonical import/marker source
- `tests/agent/*Tests.swift` — focused top-level `test*` probes (no stdout,
  no run-loop waits)
- `tests/agent/SymbolsDependencyIdentity.swift` — Foundation `TimeInterval`
  / `Date` values through `RepeatBehavior.periodic(_:delay:)`

Sealed gate: `bash full/symbols/tests/acceptance/test_host.sh`.
