# Foundation Progress oracle

`ProgressOracle.swift` records the public Apple Foundation behavior that the
portable `Progress` and typed observation slice implements: option raw values,
determinate/indeterminate state, fraction/completion rules, and the precise
initial/prior/old/new payload sequence. The committed output was captured on
macOS with Swift 6.2.1 on 2026-08-31. The host gate rebuilds the oracle against
the active Apple SDK and refuses drift before testing the portable module.
