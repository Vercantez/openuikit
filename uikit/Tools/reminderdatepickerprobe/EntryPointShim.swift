// Typecheck-only host seam. Native UIKit synthesizes UIApplicationMain for an
// @main app delegate; OpenUIKit deliberately leaves process ownership to its
// Linux host. Extending the unchanged delegate outside the app repository
// prevents that unrelated entry-point difference from short-circuiting this
// 22-source compatibility census. This file adds no UIKit API.
extension AppDelegate {
    static func main() {}
}
