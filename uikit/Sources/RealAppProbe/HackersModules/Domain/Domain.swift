// Harness stub for weiran/Hackers Domain at 83016de.
// Types and protocols the unmodified Feed screen names; sample posts live
// in Shared. No network, no HTML parser, no third-party scraper.

import Foundation

public struct VotingState: Sendable {
    public let isUpvoted: Bool
    public let score: Int?
    public let canVote: Bool
    public let canUnvote: Bool
    public let isVoting: Bool
    public let error: Error?

    public init(
        isUpvoted: Bool,
        score: Int? = nil,
        canVote: Bool,
        canUnvote: Bool = false,
        isVoting: Bool = false,
        error: Error? = nil
    ) {
        self.isUpvoted = isUpvoted
        self.score = score
        self.canVote = canVote
        self.canUnvote = canUnvote
        self.isVoting = isVoting
        self.error = error
    }
}

public protocol Votable: Identifiable, Sendable {
    var id: Int { get }
    var upvoted: Bool { get }
    var voteLinks: VoteLinks? { get }
}

public protocol ScoredVotable: Votable {
    var score: Int { get set }
}

public struct VoteLinks: Sendable, Hashable {
    public let upvote: URL?
    public let unvote: URL?

    public init(upvote: URL?, unvote: URL?) {
        self.upvote = upvote
        self.unvote = unvote
    }
}

public struct Post: Sendable, Identifiable, Hashable {
    public let id: Int
    public let url: URL
    public let title: String
    public let age: String
    public var commentsCount: Int
    public let by: String
    public var score: Int
    public let postType: PostType
    public var upvoted: Bool
    public var isBookmarked: Bool
    public var isRead: Bool
    public var voteLinks: VoteLinks?
    public var text: String?
    public var comments: [Comment]?

    public init(
        id: Int,
        url: URL,
        title: String,
        age: String,
        commentsCount: Int,
        by: String,
        score: Int,
        postType: PostType,
        upvoted: Bool,
        isBookmarked: Bool = false,
        isRead: Bool = false,
        voteLinks: VoteLinks? = nil,
        text: String? = nil,
        comments: [Comment]? = nil
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.age = age
        self.commentsCount = commentsCount
        self.by = by
        self.score = score
        self.postType = postType
        self.upvoted = upvoted
        self.isBookmarked = isBookmarked
        self.isRead = isRead
        self.voteLinks = voteLinks
        self.text = text
        self.comments = comments
    }
}

public enum PostType: String, CaseIterable, Sendable, Hashable {
    case news, ask, show, jobs, newest, best, active, bookmarks
}

public struct Comment: Sendable, Identifiable {
    public let id: Int
    public let age: String
    public let text: String
    public let by: String
    public let isFlagged: Bool
    public let level: Int
    public let upvoted: Bool
    public let voteLinks: VoteLinks?
    public let visibility: CommentVisibilityType

    public init(
        id: Int,
        age: String,
        text: String,
        by: String,
        isFlagged: Bool = false,
        level: Int,
        upvoted: Bool,
        voteLinks: VoteLinks? = nil,
        visibility: CommentVisibilityType = .visible
    ) {
        self.id = id
        self.age = age
        self.text = text
        self.by = by
        self.isFlagged = isFlagged
        self.level = level
        self.upvoted = upvoted
        self.voteLinks = voteLinks
        self.visibility = visibility
    }
}

extension Comment: Hashable {
    public static func == (lhs: Comment, rhs: Comment) -> Bool {
        lhs.id == rhs.id
            && lhs.age == rhs.age
            && lhs.text == rhs.text
            && lhs.by == rhs.by
            && lhs.isFlagged == rhs.isFlagged
            && lhs.level == rhs.level
            && lhs.upvoted == rhs.upvoted
            && lhs.voteLinks == rhs.voteLinks
            && lhs.visibility == rhs.visibility
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public extension Comment {
    func with(upvoted: Bool) -> Comment {
        Comment(
            id: id, age: age, text: text, by: by, isFlagged: isFlagged, level: level,
            upvoted: upvoted, voteLinks: voteLinks, visibility: visibility
        )
    }

    func with(voteLinks: VoteLinks?) -> Comment {
        Comment(
            id: id, age: age, text: text, by: by, isFlagged: isFlagged, level: level,
            upvoted: upvoted, voteLinks: voteLinks, visibility: visibility
        )
    }
}

public enum CommentVisibilityType: Int, Sendable {
    case visible = 3
    case compact = 2
    case hidden = 1
}

public struct User: Sendable {
    public let username: String
    public let karma: Int
    public let joined: Date

    public init(username: String, karma: Int, joined: Date) {
        self.username = username
        self.karma = karma
        self.joined = joined
    }
}

public enum HackersKitError: Error, Sendable {
    case requestFailure
    case scraperError
    case unauthenticated
    case voteRejected
    case authenticationError(error: HackersKitAuthenticationError)
}

extension HackersKitError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .voteRejected:
            return "Hacker News didn’t accept this vote. Votes can only be undone shortly after they’re cast."
        default:
            return nil
        }
    }
}

public enum HackersKitAuthenticationError: Error, Sendable {
    case badCredentials, sessionNotEstablished, serverUnreachable, noInternet, unknown
}

public extension PostType {
    var title: String {
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
}

extension Post: ScoredVotable {}
extension Comment: Votable {}

public protocol PostUseCase: Sendable {
    func getPosts(type: PostType, page: Int, nextId: Int?) async throws -> [Post]
    func getPost(id: Int) async throws -> Post
}

public protocol BookmarksUseCase: Sendable {
    func bookmarkedIDs() async -> Set<Int>
    func bookmarkedPosts() async -> [Post]
    @discardableResult
    func toggleBookmark(post: Post) async throws -> Bool
}

public protocol ReadStatusUseCase: Sendable {
    func readPostIDs() async -> Set<Int>
    func markPostRead(id: Int) async
}

public protocol SearchUseCase: Sendable {
    func searchPosts(
        query: String,
        sort: SearchSort,
        dateRange: SearchDateRange,
        page: Int,
        hitsPerPage: Int
    ) async throws -> SearchResultsPage
}

public enum SearchSort: String, CaseIterable, Sendable, Hashable {
    case popular, recent
}

public enum SearchDateRange: String, CaseIterable, Sendable, Hashable {
    case allTime, last24Hours, pastWeek, pastMonth, pastYear
}

public struct SearchResultsPage: Sendable, Equatable {
    public let posts: [Post]
    public let page: Int
    public let totalPages: Int
    public let totalResults: Int
    public let hasMore: Bool

    public init(posts: [Post], page: Int, totalPages: Int, totalResults: Int, hasMore: Bool) {
        self.posts = posts
        self.page = page
        self.totalPages = totalPages
        self.totalResults = totalResults
        self.hasMore = hasMore
    }
}

public enum TextSize: Int, CaseIterable, Sendable {
    case extraSmall = 0, small = 1, medium = 2, large = 3, extraLarge = 4

    public var displayName: String {
        switch self {
        case .extraSmall: return "Extra Small"
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .extraLarge: return "Extra Large"
        }
    }

    public var scaleFactor: Double {
        switch self {
        case .extraSmall: return 0.8
        case .small: return 0.9
        case .medium: return 1.0
        case .large: return 1.1
        case .extraLarge: return 1.2
        }
    }
}

public protocol SettingsUseCase: AnyObject, Sendable {
    var safariReaderMode: Bool { get set }
    var linkBrowserMode: LinkBrowserMode { get set }
    var showThumbnails: Bool { get set }
    var rememberFeedCategory: Bool { get set }
    var lastFeedCategory: PostType? { get set }
    var textSize: TextSize { get set }
    var compactFeedDesign: Bool { get set }
    var dimReadPosts: Bool { get set }
    var swipeCollapseThreads: Bool { get set }
    var showNextCommentButton: Bool { get set }
    func clearCache() async
    func cacheUsageBytes() async -> Int64
}

public enum LinkBrowserMode: Int, CaseIterable, Sendable {
    case inAppBrowser = 0, customBrowser = 1, systemBrowser = 2
}

public protocol VoteUseCase: Sendable {
    func upvote(post: Post) async throws
    func upvote(comment: Comment, for post: Post) async throws
    func unvote(post: Post) async throws
    func unvote(comment: Comment, for post: Post) async throws
}

public protocol AuthenticationUseCase: Sendable {
    func authenticate(username: String, password: String) async throws
    func logout() async throws
    func isAuthenticated() async -> Bool
    func getCurrentUser() async -> User?
}

public protocol VotingStateProvider: Sendable {
    func votingState(for item: any Votable) -> VotingState
    func upvote(item: any Votable) async throws
    func unvote(item: any Votable) async throws
}

public protocol CommentVotingStateProvider: Sendable {
    func upvoteComment(_ comment: Comment, for post: Post) async throws
    func unvoteComment(_ comment: Comment, for post: Post) async throws
}

public final class DefaultVotingStateProvider: VotingStateProvider, CommentVotingStateProvider, Sendable {
    public init() {}

    public func votingState(for item: any Votable) -> VotingState {
        let score: Int? = (item as? any ScoredVotable)?.score
        return VotingState(
            isUpvoted: item.upvoted,
            score: score,
            canVote: item.voteLinks?.upvote != nil,
            canUnvote: item.voteLinks?.unvote != nil,
            isVoting: false
        )
    }

    public func upvote(item: any Votable) async throws { _ = item }
    public func unvote(item: any Votable) async throws { _ = item }
    public func upvoteComment(_ comment: Comment, for post: Post) async throws {
        _ = (comment, post)
    }
    public func unvoteComment(_ comment: Comment, for post: Post) async throws {
        _ = (comment, post)
    }
}
