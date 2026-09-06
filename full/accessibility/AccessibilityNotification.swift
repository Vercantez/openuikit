import Foundation

public enum AccessibilityNotification {
    public struct Announcement {
        public let announcement: AttributedString

        public init(_ announcement: AttributedString) {
            self.announcement = announcement
        }

        public init(_ announcement: String) {
            self.announcement = AttributedString(announcement)
        }

        public init(_ announcement: NSAttributedString) {
            self.announcement = AttributedString(announcement.string)
        }

        /// VoiceOver / TalkBack posting is unavailable. This is a documented no-op.
        public func post() {}
    }

    public struct PageScrolled {
        public let announcement: AttributedString

        public init(_ announcement: AttributedString) {
            self.announcement = announcement
        }

        public init(_ announcement: String) {
            self.announcement = AttributedString(announcement)
        }

        public init(_ announcement: NSAttributedString) {
            self.announcement = AttributedString(announcement.string)
        }

        public func post() {}
    }

    public struct LayoutChanged {
        public let element: Any?

        public init(_ element: Any? = nil) {
            self.element = element
        }

        public func post() {}
    }

    public struct ScreenChanged {
        public let element: Any?

        public init(_ element: Any? = nil) {
            self.element = element
        }

        public func post() {}
    }
}
