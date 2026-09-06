// Darwin Apple Foundation / Linux corelibs have no guest
// `_portableWillChangeValue` (that lives on NSObject in
// full/foundation/Progress.swift). OpenUIKit's WebKit target is not
// compiled against the guest Foundation, so the typed-KVO brackets in
// WebKitWebView._setObserved are no-ops here. String-key KVO
// `_deliverStringKVO` still fires.
// MEASURED: `swift build --target WebKit` 2026-09-06, two errors at
// WebKitWebView.swift:1135/1148 cannot find in scope.

extension WKWebView {
    func _portableWillChangeValue<Value>(
        for keyPath: KeyPath<WKWebView, Value>, oldValue: Value
    ) {
        _ = keyPath
        _ = oldValue
    }

    func _portableDidChangeValue<Value>(
        for keyPath: KeyPath<WKWebView, Value>,
        oldValue: Value,
        newValue: Value
    ) {
        _ = keyPath
        _ = oldValue
        _ = newValue
    }
}
