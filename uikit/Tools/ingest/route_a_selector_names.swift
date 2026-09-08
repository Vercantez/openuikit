// Measured with Apple Swift 6.2.1, arm64-apple-macosx26.0, 2026-09-07.
// Run: swift Tools/ingest/route_a_selector_names.swift
// NSObject is enough to isolate spelling; sender type does not supply labels.
import Foundation

final class RouteASelectorNameProbe: NSObject {
    @objc func plain() {}
    @objc func changed(_ sender: NSObject) {}
    @objc func toggle(sender: NSObject) {}
    @objc func didPressSearch(sender: NSObject) {}
    @objc func keyboardWillShow(notification: Notification) {}
    @objc func mixed(sender: NSObject, event: NSObject) {}
    @objc func tappedLearnMoreFooter(gestureRecognizer: NSObject) {}
    @objc func f(with value: NSObject) {}
    @objc func didToggle(enabled: Bool) {}
    @objc func paste(clipboardString: String) {}
    @objc func pasteAndGo(clipboardString: String) {}
    @objc(chosenName:) func explicit(_ sender: NSObject) {}
}

print("plain()=" + NSStringFromSelector(#selector(RouteASelectorNameProbe.plain)))
print("changed(_:)=" + NSStringFromSelector(#selector(RouteASelectorNameProbe.changed(_:))))
print("toggle(sender:)=" + NSStringFromSelector(#selector(RouteASelectorNameProbe.toggle(sender:))))
print("didPressSearch(sender:)=" + NSStringFromSelector(#selector(RouteASelectorNameProbe.didPressSearch(sender:))))
print("keyboardWillShow(notification:)=" + NSStringFromSelector(#selector(RouteASelectorNameProbe.keyboardWillShow(notification:))))
print("mixed(sender:event:)=" + NSStringFromSelector(#selector(RouteASelectorNameProbe.mixed(sender:event:))))
print("explicit(_:)=" + NSStringFromSelector(#selector(RouteASelectorNameProbe.explicit(_:))))
print("tappedLearnMoreFooter(gestureRecognizer:)=" + NSStringFromSelector(#selector(RouteASelectorNameProbe.tappedLearnMoreFooter(gestureRecognizer:))))
print("didToggle(enabled:)=" + NSStringFromSelector(#selector(RouteASelectorNameProbe.didToggle(enabled:))))
print("paste(clipboardString:)=" + NSStringFromSelector(#selector(RouteASelectorNameProbe.paste(clipboardString:))))
print("pasteAndGo(clipboardString:)=" + NSStringFromSelector(#selector(RouteASelectorNameProbe.pasteAndGo(clipboardString:))))
print("f(with:)=" + NSStringFromSelector(#selector(RouteASelectorNameProbe.f(with:))))
