enum SortMode: Sendable {
    case newest
}

final class WidgetDefaults: @unchecked Sendable {
    static let shared = WidgetDefaults()
    var sortMode = SortMode.newest
    var loggedIn = false
}
