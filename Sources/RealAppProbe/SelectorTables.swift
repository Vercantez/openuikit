// HARNESS CODE — the selector dispatch tables the vendored app source cannot
// supply for itself.
//
// docs/OBJC_RUNTIME.md item 1: native ELF has no Objective-C interoperability,
// so even NSObject-backed OpenUIKit targets must publish a name -> method
// table there. Real UIKit needs none of this. It is two lines plus one line
// per action, and it is the single largest per-file source cost the real-app
// harness measured — counted as such in docs/REAL_APP_TEST.md.
//
// It lives OUTSIDE Vendored/ so the vendored files stay a clean diff against
// the app's own source.

import OpenUIKit

extension SimpleActionView: SelectorDispatching {
    static let actions: ActionTable<SimpleActionView> = [
        .action("switchToggled:", SimpleActionView.switchToggled),
        .action("actionTapped", SimpleActionView.actionTapped),
    ]
    func perform(_ name: String, with sender: Any?) -> Bool {
        Self.actions.perform(name, on: self, with: sender)
    }
}
