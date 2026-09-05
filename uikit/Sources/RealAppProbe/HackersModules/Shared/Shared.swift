// Harness stub for weiran/Hackers Shared at 83016de.
// Satisfies the unmodified Feed module's `import Shared`. Sample posts are
// fixed (no network). Thumbnails, share sheets, Safari, and iCloud are
// no-ops. Images are generated placeholders in DesignSystem.ThumbnailView.

import Combine
import Domain
import Foundation
import Observation
import SwiftUI
import UIKit

// MARK: - Sample feed (fixed posts; ages are literals, not DateFormatter)

public enum HackersFeedSample {
    public static let posts: [Post] = [
        post(id: 1, host: "example.com", title: "Show HN: A tiny UIKit Hacker News client",
             age: "3 hours ago", comments: 128, by: "pg", score: 312),
        post(id: 2, host: "arxiv.org", title: "The measured cost of a layout pass",
             age: "5 hours ago", comments: 54, by: "dang", score: 201),
        post(id: 3, host: "news.ycombinator.com", title: "Ask HN: What did you ship this week?",
             age: "7 hours ago", comments: 89, by: "ask", score: 156),
        post(id: 4, host: "github.com", title: "Open-sourcing our SwiftUI feed cells",
             age: "9 hours ago", comments: 41, by: "weiran", score: 178),
        post(id: 5, host: "ietf.org", title: "HTTP/3 is not a silver bullet",
             age: "11 hours ago", comments: 73, by: "tptacek", score: 244),
        post(id: 6, host: "apple.com", title: "Notes on Dynamic Type at 3x",
             age: "14 hours ago", comments: 22, by: "johndoe", score: 97),
        post(id: 7, host: "wikipedia.org", title: "A brief history of the news.yc list",
             age: "18 hours ago", comments: 16, by: "colin", score: 64),
        post(id: 8, host: "swift.org", title: "Swift 6.2 default isolation on app targets",
             age: "1 day ago", comments: 35, by: "tkremenek", score: 188),
    ]

    private static func post(
        id: Int, host: String, title: String, age: String,
        comments: Int, by: String, score: Int
    ) -> Post {
        Post(
            id: id,
            url: URL(string: "https://\(host)/item/\(id)")!,
            title: title,
            age: age,
            commentsCount: comments,
            by: by,
            score: score,
            postType: .news,
            upvoted: false,
            voteLinks: VoteLinks(
                upvote: URL(string: "https://news.ycombinator.com/vote?id=\(id)")!,
                unvote: nil
            )
        )
    }
}

// MARK: - Navigation

public enum PostLinkPresentation: Hashable, Sendable {
    case collapsedBrowser
    case expandedComments
}

@MainActor
public protocol NavigationStoreProtocol: AnyObject, Observable {
    var selectedPost: Post? { get set }
    var selectedPostId: Int? { get set }
    var showingLogin: Bool { get set }
    var showingSettings: Bool { get set }
    func showPost(_ post: Post)
    func showPostLink(_ post: Post, presentation: PostLinkPresentation)
    func showPost(withId id: Int)
    func showLogin()
    func showSettings()
    func selectPostType(_ type: PostType)
    func openURLInPrimaryContext(_ url: URL, pushOntoDetailStack: Bool) -> Bool
}

public extension NavigationStoreProtocol {
    func showPostLink(_ post: Post) {
        showPostLink(post, presentation: .collapsedBrowser)
    }

    func openURLInPrimaryContext(_ url: URL) -> Bool {
        openURLInPrimaryContext(url, pushOntoDetailStack: true)
    }
}

@MainActor
@Observable
public final class HackersNavigationStore: NavigationStoreProtocol {
    public var selectedPost: Post?
    public var selectedPostId: Int?
    public var showingLogin = false
    public var showingSettings = false

    public init() {}

    public func showPost(_ post: Post) {
        selectedPost = post
        selectedPostId = post.id
    }

    public func showPostLink(_ post: Post, presentation: PostLinkPresentation) {
        _ = presentation
        showPost(post)
    }

    public func showPost(withId id: Int) { selectedPostId = id }
    public func showLogin() { showingLogin = true }
    public func showSettings() { showingSettings = true }
    public func selectPostType(_ type: PostType) { _ = type }
    public func openURLInPrimaryContext(_ url: URL, pushOntoDetailStack: Bool) -> Bool {
        _ = (url, pushOntoDetailStack)
        return false
    }
}

// MARK: - LoadingStateManager
//
// Seed [Post] with HackersFeedSample so FeedViewModel.init's empty
// LoadingStateManager already has rows. openrender has no run loop, so
// FeedView.task { await loadFeed() } never fires there; the simulator
// .task is then a no-op (hasAttemptedLoad && !posts.isEmpty).

@MainActor
@Observable
public final class LoadingStateManager<T: Sendable>: @unchecked Sendable {
    public var data: T
    public private(set) var isLoading = false
    public private(set) var error: Error?
    public private(set) var hasAttemptedLoad = false

    private var loadData: (@Sendable () async throws -> T)?
    private var shouldSkipLoad: (@Sendable (T) -> Bool)?
    private var loadGeneration = 0

    public init(
        initialData: T,
        shouldSkipLoad: @escaping @Sendable (T) -> Bool = { _ in false },
        loadData: @escaping @Sendable () async throws -> T
    ) {
        data = Self.seeded(initialData)
        hasAttemptedLoad = Self.isSeeded(initialData)
        self.shouldSkipLoad = shouldSkipLoad
        self.loadData = loadData
    }

    public init(initialData: T) {
        data = Self.seeded(initialData)
        hasAttemptedLoad = Self.isSeeded(initialData)
        shouldSkipLoad = nil
        loadData = nil
    }

    public func setLoadFunction(
        shouldSkipLoad: @escaping @Sendable (T) -> Bool = { _ in false },
        loadData: @escaping @Sendable () async throws -> T
    ) {
        self.shouldSkipLoad = shouldSkipLoad
        self.loadData = loadData
    }

    @MainActor
    public func loadIfNeeded() async {
        guard !isLoading else { return }
        guard let shouldSkipLoad else { return }
        guard !hasAttemptedLoad || !shouldSkipLoad(data) else { return }
        await performLoad()
    }

    @MainActor
    public func refresh() async {
        await performLoad()
    }

    @MainActor
    private func performLoad() async {
        guard let loadData else { return }
        let loader = loadData
        loadGeneration += 1
        let generation = loadGeneration
        isLoading = true
        error = nil
        do {
            let result = try await loader()
            guard generation == loadGeneration else { return }
            data = result
            hasAttemptedLoad = true
        } catch {
            guard generation == loadGeneration else { return }
            self.error = error
            hasAttemptedLoad = true
        }
        if generation == loadGeneration {
            isLoading = false
        }
    }

    @MainActor
    public func reset() {
        loadGeneration += 1
        isLoading = false
        hasAttemptedLoad = false
        error = nil
    }

    private static func isSeeded(_ initial: T) -> Bool {
        (initial as? [Post])?.isEmpty == true
    }

    private static func seeded(_ initial: T) -> T {
        if isSeeded(initial), let posts = HackersFeedSample.posts as? T {
            return posts
        }
        return initial
    }
}

// MARK: - Controllers / use cases

@MainActor
public final class BookmarksController {
    public init(bookmarksUseCase: any BookmarksUseCase = DependencyContainer.shared.getBookmarksUseCase()) {
        _ = bookmarksUseCase
    }

    @discardableResult
    public func refreshBookmarks() async -> Set<Int> { [] }

    public func annotatedPosts(from posts: [Post]) -> [Post] { posts }

    public func bookmarkedPosts() async -> [Post] { [] }

    public func isBookmarked(_ postID: Int) -> Bool {
        _ = postID
        return false
    }

    @discardableResult
    public func toggle(post: Post) async -> Bool {
        !post.isBookmarked
    }
}

@MainActor
public final class ReadStatusController {
    public init(readStatusUseCase: any ReadStatusUseCase = DependencyContainer.shared.getReadStatusUseCase()) {
        _ = readStatusUseCase
    }

    @discardableResult
    public func refreshReadStatus() async -> Set<Int> { [] }

    public func annotatedPosts(from posts: [Post]) -> [Post] { posts }

    public func isRead(_ postID: Int) -> Bool {
        _ = postID
        return false
    }

    public func markRead(postID: Int) async { _ = postID }
}

@MainActor
@Observable
public final class VotingViewModel {
    public var navigationStore: NavigationStoreProtocol?
    public var lastError: Error?
    public var isVoting: Bool { false }

    public init(
        votingStateProvider: VotingStateProvider,
        commentVotingStateProvider: CommentVotingStateProvider,
        authenticationUseCase: any AuthenticationUseCase
    ) {
        _ = (votingStateProvider, commentVotingStateProvider, authenticationUseCase)
    }

    public func upvote(post: inout Post) async { _ = post }
    public func unvote(post: inout Post) async { _ = post }
    public func votingState(for item: any Votable) -> VotingState {
        VotingState(
            isUpvoted: item.upvoted,
            score: (item as? any ScoredVotable)?.score,
            canVote: false,
            canUnvote: false
        )
    }
    public func canVote(item: any Votable) -> Bool {
        _ = item
        return false
    }
    public func canUnvote(item: any Votable) -> Bool {
        _ = item
        return false
    }
    public func clearError() { lastError = nil }
}

public final class DependencyContainer: @unchecked Sendable {
    public static let shared = DependencyContainer()

    private let posts: [Post]
    private let settings = SampleSettingsUseCase()
    private let voting = DefaultVotingStateProvider()

    private init() {
        posts = HackersFeedSample.posts
    }

    public func getPostUseCase() -> any PostUseCase { SamplePostUseCase(posts: posts) }
    public func getVoteUseCase() -> any VoteUseCase { SampleVoteUseCase() }
    public func getSettingsUseCase() -> any SettingsUseCase { settings }
    public func getSearchUseCase() -> any SearchUseCase { SampleSearchUseCase() }
    public func getBookmarksUseCase() -> any BookmarksUseCase { SampleBookmarksUseCase() }
    public func getReadStatusUseCase() -> any ReadStatusUseCase { SampleReadStatusUseCase() }
    public func getVotingStateProvider() -> any VotingStateProvider { voting }
    public func getCommentVotingStateProvider() -> any CommentVotingStateProvider { voting }
    public func getAuthenticationUseCase() -> any AuthenticationUseCase { SampleAuthUseCase() }

    @MainActor
    public func makeBookmarksController() -> BookmarksController {
        BookmarksController(bookmarksUseCase: getBookmarksUseCase())
    }

    @MainActor
    public func makeReadStatusController() -> ReadStatusController {
        ReadStatusController(readStatusUseCase: getReadStatusUseCase())
    }
}

final class SamplePostUseCase: PostUseCase, @unchecked Sendable {
    let posts: [Post]
    init(posts: [Post]) { self.posts = posts }
    func getPosts(type: PostType, page: Int, nextId: Int?) async throws -> [Post] {
        _ = (type, page, nextId)
        return posts
    }
    func getPost(id: Int) async throws -> Post {
        if let post = posts.first(where: { $0.id == id }) { return post }
        throw HackersKitError.requestFailure
    }
}

final class SampleVoteUseCase: VoteUseCase, Sendable {
    func upvote(post: Post) async throws { _ = post }
    func upvote(comment: Comment, for post: Post) async throws { _ = (comment, post) }
    func unvote(post: Post) async throws { _ = post }
    func unvote(comment: Comment, for post: Post) async throws { _ = (comment, post) }
}

final class SampleSettingsUseCase: SettingsUseCase, @unchecked Sendable {
    var safariReaderMode = false
    var linkBrowserMode = LinkBrowserMode.inAppBrowser
    var showThumbnails = true
    var rememberFeedCategory = false
    var lastFeedCategory: PostType?
    var textSize = TextSize.medium
    var compactFeedDesign = false
    var dimReadPosts = false
    var swipeCollapseThreads = false
    var showNextCommentButton = true
    func clearCache() async {}
    func cacheUsageBytes() async -> Int64 { 0 }
}

final class SampleSearchUseCase: SearchUseCase, Sendable {
    func searchPosts(
        query: String, sort: SearchSort, dateRange: SearchDateRange,
        page: Int, hitsPerPage: Int
    ) async throws -> SearchResultsPage {
        _ = (query, sort, dateRange, page, hitsPerPage)
        return SearchResultsPage(posts: [], page: 0, totalPages: 0, totalResults: 0, hasMore: false)
    }
}

final class SampleBookmarksUseCase: BookmarksUseCase, Sendable {
    func bookmarkedIDs() async -> Set<Int> { [] }
    func bookmarkedPosts() async -> [Post] { [] }
    func toggleBookmark(post: Post) async throws -> Bool { !post.isBookmarked }
}

final class SampleReadStatusUseCase: ReadStatusUseCase, Sendable {
    func readPostIDs() async -> Set<Int> { [] }
    func markPostRead(id: Int) async { _ = id }
}

final class SampleAuthUseCase: AuthenticationUseCase, Sendable {
    func authenticate(username: String, password: String) async throws {
        _ = (username, password)
    }
    func logout() async throws {}
    func isAuthenticated() async -> Bool { false }
    func getCurrentUser() async -> User? { nil }
}

// MARK: - Display helpers the Feed files call

public enum AccessibilityIdentifier {
    public enum Feed {
        public static let list = "feed.list"
        public static let searchResults = "search.results"
        public static let settingsButton = "settings.button"
        public static let searchSortMenu = "search.sort.menu"
        public static let searchDateMenu = "search.date.menu"
        public static func category(_ value: String) -> String { "feed.category.\(value)" }
        public static func post(_ id: Int) -> String { "feed.post.\(id)" }
        public static let whatsNewPanel = "feed.whatsNewPanel"
        public static let whatsNewPanelDismiss = "feed.whatsNewPanel.dismiss"
    }
}

public struct HackerNewsConstants {
    public static let baseURL = "https://news.ycombinator.com"
    public static let host = "news.ycombinator.com"

    public static func isItemURL(_ url: URL) -> Bool {
        guard let urlHost = url.host?.lowercased() else { return false }
        if urlHost != host { return false }
        let path = url.path
        var trimmed = path
        while trimmed.hasPrefix("/") { trimmed.removeFirst() }
        while trimmed.hasSuffix("/") { trimmed.removeLast() }
        return trimmed == "item"
    }
}

public extension Post {
    var hackerNewsURL: URL {
        URL(string: "\(HackerNewsConstants.baseURL)/item?id=\(id)")!
    }
}

public extension PostType {
    var displayName: String {
        switch self {
        case .news: return "Top"
        case .ask: return "Ask"
        case .show: return "Show"
        case .jobs: return "Jobs"
        case .newest: return "New"
        case .best: return "Best"
        case .active: return "Active"
        case .bookmarks: return "Bookmarks"
        }
    }

    var iconName: String {
        switch self {
        case .news: return "flame"
        case .ask: return "bubble.left.and.bubble.right"
        case .show: return "eye"
        case .jobs: return "briefcase"
        case .newest: return "clock"
        case .best: return "star"
        case .active: return "bolt"
        case .bookmarks: return "bookmark"
        }
    }
}

public extension View {
    @ViewBuilder
    func `if`(_ condition: Bool, transform: (Self) -> some View) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

@MainActor
public enum DeviceLayout {
    public static var usesPadLayout: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    public static var isRunningOnMac: Bool { false }

    public static func prefersInlineCustomBrowser(mode: LinkBrowserMode) -> Bool {
        guard mode == .customBrowser else { return false }
        return !usesPadLayout
    }
}

public final class ContentSharePresenter: @unchecked Sendable {
    public static let shared = ContentSharePresenter()
    private init() {}
    @MainActor
    public func sharePost(_ post: Post) { _ = post }
}

@MainActor
public enum LinkOpener {
    public static func openURL(_ url: URL, with post: Post? = nil) {
        _ = (url, post)
    }
}

public extension Notification.Name {
    static let refreshRequired = NSNotification.Name(rawValue: "RefreshRequiredNotification")
    static let userDidLogout = NSNotification.Name(rawValue: "UserDidLogoutNotification")
    static let bookmarksDidChange = NSNotification.Name(rawValue: "BookmarksDidChangeNotification")
    static let readStatusDidChange = NSNotification.Name(rawValue: "ReadStatusDidChangeNotification")
}
