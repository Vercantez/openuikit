# SwiftUI settings runtime

This slice implements the production SwiftUI surface used by the six
`Blockzilla/InternalSettings` views in Mozilla Focus at commit
`a2832521c1daa0c23419c73705ae043ed60c9791`. The upstream application sources
remain unchanged.

The literal `SwiftUI` module now provides `Text(verbatim:)`, caption fonts,
sections with headers and footers, toggles, text fields, pickers, the
destination-value `NavigationLink` initializer, text-valued navigation bar
titles, `disabled`, `onChange`, and `onReceive` for any Combine publisher.
These declarations produce retained graph nodes rather than compile-only
values.

The OpenUIKit renderer backs toggles and fields with real `UISwitch` and
`UITextField` controls. Compact pickers render a labelled selectable row and
advance through the tagged option set when activated. All three write through
their bindings and cause the existing deferred graph invalidation path to
render the new value. Disabled state composes through nested modifiers and
prevents target/action delivery.

`onChange` keeps its previous typed value at the modifier's structural graph
identity, skips the initial render, and delivers only changes after graph
evaluation. `onReceive` retains one cancellable at that same structural
identity, supports publishers with any failure type, queues synchronous
publishers until evaluation completes, and cancels subscriptions when a
conditional branch or root value removes the modifier.

This is functional settings UI, but not a claim of pixel identity with every
SwiftUI form style. The compact picker currently uses an inline cyclic
selection interaction rather than Apple's navigation/menu presentation, and
form chrome is the deterministic OpenUIKit rendering already used by the
Linux guest path.
