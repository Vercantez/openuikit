#if !canImport(Darwin)
public extension NSUserActivity {
    var shortcutAvailability: INShortcutAvailabilityOptions {
        get { [] }
        set { _ = newValue }
    }
}
#endif
