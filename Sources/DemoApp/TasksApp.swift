// Tasks demo app entry point. Owner: demo app (M7.5 second app).
//
// The second app written against OpenUIKit (after the Settings demo): a todo
// list in a UINavigationController — root list, task detail, statistics.
// Hosted by `openhost --app tasks`, which boots the same UIApplication-lite
// around the navigation controller this factory returns.

import OpenUIKit

public enum TasksApp {
    /// Same iPhone-ish portrait window as the Settings demo.
    public static let windowSize = CGSize(width: 390, height: 780)

    /// Build the app's root: a UINavigationController on the Tasks list.
    public static func makeRootViewController() -> UINavigationController {
        UINavigationController(rootViewController: TasksRootViewController())
    }
}
