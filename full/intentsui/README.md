# Open IntentsUI

`IntentsUI.swift` is the production source for `IntentsUI.swiftmodule` and
`libIntentsUI.dylib`. It exports the same add/edit controller and delegate
spelling used by untouched Siri-shortcut screens.

The controllers are real `UIViewController` subclasses backed by the shared
`INVoiceShortcutCenter`. A platform host calls `finish(invocationPhrase:)`,
`cancel()`, or `delete()` in response to its controls; delegates receive the
installed, updated, or deleted stable shortcut identity. Empty phrases and
missing shortcuts report errors. The controllers never pretend that Apple's
Siri account or sheet is available.

The current presentation capability is `.hostDriven`. A native OpenUIKit
phrase editor can be layered on this controller contract without changing
application source, storage identity, or the public dylib boundary.
