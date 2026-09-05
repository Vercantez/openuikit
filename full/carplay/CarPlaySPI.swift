import Foundation

@_spi(OpenUIKitHost)
extension CPAlertAction {
    public func openuikit_invokeHandler() {
        handler(self)
    }
}

@_spi(OpenUIKitHost)
extension CPBarButton {
    public func openuikit_invokeHandler() {
        storedHandler?(self)
    }
}

@_spi(OpenUIKitHost)
extension CPButton {
    public func openuikit_invokeHandler() {
        storedHandler?(self)
    }
}

@_spi(OpenUIKitHost)
extension CPGridButton {
    public func openuikit_invokeHandler() {
        storedHandler?(self)
    }
}

@_spi(OpenUIKitHost)
extension CPTextButton {
    public func openuikit_invokeHandler() {
        storedHandler?(self)
    }
}

@_spi(OpenUIKitHost)
extension CPMapButton {
    public func openuikit_invokeHandler() {
        storedHandler?(self)
    }
}

@_spi(OpenUIKitHost)
extension CPDashboardButton {
    public func openuikit_invokeHandler() {
        storedHandler?(self)
    }
}

@_spi(OpenUIKitHost)
extension CPNowPlayingButton {
    public func openuikit_invokeHandler() {
        storedHandler?(self)
    }
}

@_spi(OpenUIKitHost)
extension CPSelectableListItem {
    public func openuikit_invokeHandler() {
        var completed = false
        handler?(self) {
            completed = true
        }
        _ = completed
    }
}

@_spi(OpenUIKitHost)
extension CPListImageRowItem {
    public func openuikit_invokeRowHandler(index: Int) {
        listImageRowHandler?(self, index) {}
    }
}

@_spi(OpenUIKitHost)
extension CPListTemplate {
    public func openuikit_select(_ item: CPListItem) async {
        if let handler = item.handler {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                handler(item) {
                    continuation.resume()
                }
            }
        }
        await delegate?.listTemplate(self, didSelect: item)
    }
}
