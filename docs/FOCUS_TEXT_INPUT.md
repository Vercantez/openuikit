# Focus autocomplete text input

This slice targets Mozilla Focus's unchanged
`focus-ios/Blockzilla/UIComponents/AutocompleteTextField.swift` at Focus
revision `a2832521c1daa0c23419c73705ae043ed60c9791` (tree
`065d8e374c9caa3be2915165ba7cbbe4b1d61d7e`). The complete source file is
15,157 bytes and has SHA-256
`5ebf0057037392a64f15b7e9c2730bdbde2beabd09057ea8ab0a5b454af09dfb`.
No Focus source, manifest, or dependency is changed.

## Implemented behavior

`UITextField` now exposes the core UIKit text-document model used by the
autocomplete field:

- opaque, document-owned `UITextPosition` and `UITextRange` values;
- `beginningOfDocument`, `endOfDocument`, range construction, signed position
  movement, endpoint comparison through position equality, and offset math;
- `selectedTextRange`, `text(in:)`, and ranged `replace(_:withText:)`;
- `markedTextRange`, `setMarkedText(_:selectedRange:)`, and `unmarkText()`;
- selection-aware typing, composed-character backspace and arrow movement;
- one-point `caretRect(for:)`, `firstRect(for:)`, and single-line
  `selectionRects(for:)` geometry.

Positions and delegate ranges use UTF-16 code units. A real UIKit 26.1
Catalyst probe established the sharp cases: `A😀B` has document length four;
offset two is legal and slicing `0..<2` returns `A�`; reversing endpoints
normalizes the range; replacing `1..<3` with `Z` yields `AZB` and a collapsed
caret at two. Geometry for a position inside a surrogate pair or combining
sequence snaps to the composed character's leading edge. Backspace after
either `😀` or `e` plus a combining acute mark
removes the complete composed character. Marking `2..<4` of `abcdef` with
`XYZ`, selected range `{1,1}`, yields `abXYZef`, marked range `2..<5`, and
selection `3..<4`. Passing `nil` as the marked text removes the marked span
and collapses the selection at its start, matching composition cancellation;
an empty marked string does the same only when a mark is active and is
otherwise a no-op. Direct replacement and `setMarkedText` mutations report
the selection callback without consulting `shouldChangeCharactersIn` or
emitting `.editingChanged`. Assigning `nil` to a `UITextField` selection
normalizes to a caret at document start while preserving an active mark.

Positions minted by a different field, bare base positions, and stale
out-of-bounds positions are rejected. This prevents two unrelated documents
from being joined merely because their integer offsets happen to match.

## Exact-source proof and remaining boundary

Seven override blocks are copied byte-for-byte into the focused regression:
Focus lines 44–49, 158–170, 172–178, 237–239, 277–282, 302–308, and 310–319.
Their concatenated SHA-256 is
`7e76bd95b4bbc24100cadd56f1f3e9564f76e1e3d0ffa5a7aca283e3c42b3d95`.
They compile and run as a subclass without adaptation, exercising text
override, completion-to-end selection, cursor reset through `nil`, marked
text, caret hiding, and backspace override dispatch.

Type-checking the complete untouched file against the previous OpenUIKit
surface produced 55 diagnostics. This slice removes all 37 text-document and
override diagnostics, leaving 18 unrelated diagnostics in these clusters:
portable Objective-C selector representability, accessibility override
placement, `UIKeyCommand` optionality/priority, Focus's app-local `.accent`,
Foundation/OpenUIKit `NSAttributedString` and `Timer` coexistence,
`NSStringDrawingOptions`/attributed bounding rect, and clear-button geometry.

Run the focused macOS proof with:

```sh
swift test --filter 'TextField(Editing|Selection)Tests'
```

The same production sources build in stock `swift:6.2-noble` with warnings as
errors. The implementation uses Swift UTF-16 views and deterministic font
metrics; it does not depend on Objective-C, TextKit, AppKit, or a host system
keyboard. Remaining visual selection chrome, the iOS 17.4 selection-rect
transform getter, and the `UITextView` migration are recorded in
`KNOWN_GAPS.md`.
