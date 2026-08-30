// Typecheck-only host seam. Native UIKit synthesizes UIApplicationMain for an
// @main app delegate; OpenUIKit leaves process ownership to its Linux host.
// Keeping this extension outside Reminder preserves every app/vendor byte.
extension AppDelegate {
    static func main() {}
}
