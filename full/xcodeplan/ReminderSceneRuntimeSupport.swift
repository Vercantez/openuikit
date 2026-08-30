// Build-support declarations for the deliberately narrow Reminder lifecycle
// executable. They are NOT app source and they do not claim the other twenty
// Reminder files compile. The unchanged SceneDelegate needs these three model
// names before it can construct and install its real navigation/window graph.

import UIKit

final class StorageManager {
    static let shared = StorageManager()

    func fetchReminders() -> [Int] {
        // This call exists only inside Reminder's unchanged willConnect body,
        // so the marker proves that body actually executed in the guest.
        print("REMINDER_UNCHANGED_WILL_CONNECT_OK")
        return []
    }
}

final class HomeViewModel {
    init(initialReminders: [Int]) {}
}

final class HomeViewController: UIViewController {
    convenience init(viewModel: HomeViewModel) { self.init() }
}
