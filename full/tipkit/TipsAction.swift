import Foundation

extension Tips {
    public struct Action: Identifiable {
        public typealias ID = String

        public let id: String
        public let index: Int?
        public let titleText: String
        @preconcurrency public let handler: @MainActor () -> Void

        @preconcurrency
        nonisolated public init(
            id: String? = nil,
            title: some StringProtocol,
            perform handler: @escaping @MainActor () -> Void = {}
        ) {
            self.id = id ?? String(title)
            self.index = nil
            self.titleText = String(title)
            self.handler = handler
        }
    }
}
