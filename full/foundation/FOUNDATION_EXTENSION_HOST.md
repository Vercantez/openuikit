# Foundation extension host boundary

`NSExtensionHost.swift` owns the app-facing Foundation identities used by app
extensions and by framework categories in NotificationCenter and
UserNotificationsUI. It implements `NSExtensionContext`, `NSExtensionItem`,
`NSExtensionRequestHandling`, the bounded `NSItemProvider` identity required by
extension-item attachments, and the public iOS extension keys and notification
names.

The value and copy behavior is pinned against Xcode 26.1 Foundation. A fresh
item has nil content and an empty `userInfo`; setting attributed values copies
them and reflects their keys; setting `userInfo` updates the exposed properties;
copying an item deep-copies its attributed strings and item providers.
`NSExtensionItem` and the bounded provider participate in secure coding. The
guest's current Foundation-hidden `NSCoder` is not yet a keyed archiver, so the
guest path uses a thread-safe, 64-coder in-process transport and rejects a
missing/evicted snapshot. Native host tests use a real secure
`NSKeyedArchiver`/`NSKeyedUnarchiver` round trip.

There is no Apple extension daemon on Linux. `open(_:completionHandler:)`
always reports `false`; `completeRequest` reports its background callback as
expired; and host intent is available only through the `OpenUIKitHost` SPI.
These callbacks run after releasing internal locks, and every mutable state
path uses `Synchronization.Mutex`.

The bounded `NSItemProvider` preserves in-process items, exact registered type
identifiers, suggested names, copying, and secure metadata coding. UTI
conformance, representation coercion, file coordination, and XPC transfer are
deferred to the full NSItemProvider port rather than reported as working.
