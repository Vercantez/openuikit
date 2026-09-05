// Harness stub for weiran/Hackers DesignSystem at 83016de.
// PostDisplayView / pills / colours / scaled fonts are the feed-row
// visuals. ThumbnailView is a generated safari-placeholder (no network,
// no ImageIO, no VariableBlur). Satisfies Focus's `import DesignSystem`
// as well (SettingsViewController does not name any DesignSystem types).

import Domain
import Shared
import SwiftUI
import UIKit

public enum FocusDesignSystemStub {}

// MARK: - Colours
//
// Asset catalog hexes are not in this harness. Light-mode feed capture
// uses systemOrange for the brand tint (same fallback AppColors.swift
// uses when UIColor(named:) misses).

public enum AppColors {
    public static var upvoted: Color { Color(uiColor: .systemOrange) }
    public static var appTint: Color { Color(uiColor: .systemOrange) }
    public static let background = Color(uiColor: .systemBackground)
    public static let secondaryBackground = Color(uiColor: .secondarySystemBackground)
    public static let tertiaryBackground = Color(uiColor: .tertiarySystemBackground)
    public static let groupedBackground = Color(uiColor: .systemGroupedBackground)
    public static let success = Color(uiColor: .systemGreen)
    public static let warning = Color(uiColor: .systemOrange)
    public static let danger = Color(uiColor: .systemRed)
    public static var upvotedColor: Color { upvoted }
    public static var appTintColor: Color { appTint }

    public static func separator(for colorScheme: ColorScheme) -> Color {
        Color(uiColor: .separator).opacity(colorScheme == .dark ? 0.6 : 0.3)
    }

    public static func pillBackground(for style: PillStyle, colorScheme: ColorScheme) -> Color {
        switch style {
        case .upvote(isActive: true):
            return upvotedColor.opacity(0.2)
        case .bookmark(isSaved: true):
            return appTintColor.opacity(0.2)
        case .upvote(isActive: false), .bookmark(isSaved: false), .comments:
            return Color.secondary.opacity(colorScheme == .dark ? 0.18 : 0.14)
        }
    }

    public static func pillForeground(for style: PillStyle, colorScheme: ColorScheme) -> Color {
        _ = colorScheme
        switch style {
        case .upvote(isActive: true): return upvotedColor
        case .bookmark(isSaved: true): return appTintColor
        case .upvote(isActive: false), .bookmark(isSaved: false), .comments:
            return Color.secondary
        }
    }

    public enum PillStyle: Sendable {
        case upvote(isActive: Bool)
        case bookmark(isSaved: Bool)
        case comments
    }
}

public struct AppDefaultButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.65 : 1)
    }
}

// MARK: - Text scaling

struct TextScalingEnvironmentKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1.0
}

public extension EnvironmentValues {
    var textScaling: CGFloat {
        get { self[TextScalingEnvironmentKey.self] }
        set { self[TextScalingEnvironmentKey.self] = newValue }
    }
}

public extension View {
    func textScaling(_ scaleFactor: CGFloat) -> some View {
        environment(\.textScaling, scaleFactor)
    }

    func textScaling(for textSize: TextSize) -> some View {
        environment(\.textScaling, CGFloat(textSize.scaleFactor))
    }

    func scaledFont(_ font: Font) -> some View {
        modifier(ScaledFont(font: font))
    }
}

public extension Font {
    func scaled(with factor: CGFloat) -> Font {
        if let titleFont = scaledTitleFont(with: factor) { return titleFont }
        if let textFont = scaledTextFont(with: factor) { return textFont }
        return self
    }

    private func scaledTitleFont(with factor: CGFloat) -> Font? {
        switch self {
        case .largeTitle:
            return .system(size: 34 * factor, weight: .regular, design: .default)
        case .title:
            return .system(size: 28 * factor, weight: .regular, design: .default)
        case .title2:
            return .system(size: 22 * factor, weight: .regular, design: .default)
        case .title3:
            return .system(size: 20 * factor, weight: .regular, design: .default)
        default:
            return nil
        }
    }

    private func scaledTextFont(with factor: CGFloat) -> Font? {
        switch self {
        case .headline:
            return .system(size: 17 * factor, weight: .semibold, design: .default)
        case .body:
            return .system(size: 17 * factor, weight: .regular, design: .default)
        case .callout:
            return .system(size: 16 * factor, weight: .regular, design: .default)
        case .subheadline:
            return .system(size: 15 * factor, weight: .regular, design: .default)
        case .footnote:
            return .system(size: 13 * factor, weight: .regular, design: .default)
        case .caption:
            return .system(size: 12 * factor, weight: .regular, design: .default)
        case .caption2:
            return .system(size: 11 * factor, weight: .regular, design: .default)
        default:
            return nil
        }
    }
}

struct ScaledFont: ViewModifier {
    @Environment(\.textScaling) private var textScaling
    let font: Font

    func body(content: Content) -> some View {
        content.font(font.scaled(with: textScaling))
    }
}

// MARK: - Thumbnail placeholder (no network)

public struct ThumbnailView: View {
    let url: URL?
    let isEnabled: Bool
    let showsPlaceholder: Bool
    let thumbnailSize: CGSize?

    public init(
        url: URL?,
        isEnabled: Bool = true,
        showsPlaceholder: Bool = true,
        thumbnailSize: CGSize? = nil
    ) {
        self.url = url
        self.isEnabled = isEnabled
        self.showsPlaceholder = showsPlaceholder
        self.thumbnailSize = thumbnailSize
    }

    public var body: some View {
        if showsPlaceholder {
            Image(systemName: "safari")
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.secondary.opacity(0.1))
                .frame(width: thumbnailSize?.width, height: thumbnailSize?.height)
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Empty / loading

public struct AppLoadingStateView: View {
    private let message: String?
    private let fillsSpace: Bool

    public init(message: String? = nil, fillsSpace: Bool = true) {
        self.message = message
        self.fillsSpace = fillsSpace
    }

    public var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(nil)
            if let message {
                Text(message)
                    .scaledFont(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
        .frame(maxHeight: fillsSpace ? .infinity : nil)
    }
}

public struct AppEmptyStateView: View {
    private let iconSystemName: String?
    private let title: String
    private let subtitle: String?
    private let fillsSpace: Bool

    public init(
        iconSystemName: String? = nil,
        title: String,
        subtitle: String? = nil,
        fillsSpace: Bool = true
    ) {
        self.iconSystemName = iconSystemName
        self.title = title
        self.subtitle = subtitle
        self.fillsSpace = fillsSpace
    }

    public var body: some View {
        VStack(spacing: 12) {
            if let iconSystemName {
                Image(systemName: iconSystemName)
                    .scaledFont(.title2)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            Text(title)
                .scaledFont(.headline)
                .multilineTextAlignment(.center)
            if let subtitle {
                Text(subtitle)
                    .scaledFont(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
        .frame(maxHeight: fillsSpace ? .infinity : nil)
    }
}

// MARK: - Post row (DesignSystem cell visual)

public struct PostDisplayView: View {
    @Environment(\.colorScheme) var colorScheme
    let post: Post
    let votingState: VotingState?
    let showPostText: Bool
    let showThumbnails: Bool
    let compactMode: Bool
    let dimReadPost: Bool
    let titleLineLimit: Int?
    let showsTitle: Bool
    let thumbnailSize: CGFloat
    let onThumbnailTap: (() -> Void)?
    let onUpvoteTap: (() async -> Bool)?
    let onUnvoteTap: (() async -> Bool)?
    let onBookmarkTap: (() async -> Bool)?
    let onCommentsTap: (() -> Void)?
    let matchedGeometryNamespace: Namespace.ID?
    let isMatchedGeometrySource: Bool
    @State var displayedScore: Int
    @State var displayedUpvoted: Bool
    @State var displayedBookmarked: Bool

    public init(
        post: Post,
        votingState: VotingState? = nil,
        showPostText: Bool = false,
        showThumbnails: Bool = true,
        compactMode: Bool = false,
        dimReadPost: Bool = false,
        titleLineLimit: Int? = nil,
        showsTitle: Bool = true,
        thumbnailSize: CGFloat = 55,
        onThumbnailTap: (() -> Void)? = nil,
        onUpvoteTap: (() async -> Bool)? = nil,
        onUnvoteTap: (() async -> Bool)? = nil,
        onBookmarkTap: (() async -> Bool)? = nil,
        onCommentsTap: (() -> Void)? = nil,
        matchedGeometryNamespace: Namespace.ID? = nil,
        isMatchedGeometrySource: Bool = true
    ) {
        self.post = post
        self.votingState = votingState
        self.showPostText = showPostText
        self.showThumbnails = showThumbnails
        self.compactMode = compactMode
        self.dimReadPost = dimReadPost
        self.titleLineLimit = titleLineLimit
        self.showsTitle = showsTitle
        self.thumbnailSize = thumbnailSize
        self.onThumbnailTap = onThumbnailTap
        self.onUpvoteTap = onUpvoteTap
        self.onUnvoteTap = onUnvoteTap
        self.onBookmarkTap = onBookmarkTap
        self.onCommentsTap = onCommentsTap
        self.matchedGeometryNamespace = matchedGeometryNamespace
        self.isMatchedGeometrySource = isMatchedGeometrySource
        _displayedScore = State(initialValue: post.score)
        _displayedUpvoted = State(initialValue: post.upvoted)
        _displayedBookmarked = State(initialValue: post.isBookmarked)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                Button(action: { onThumbnailTap?() }, label: {
                    ThumbnailView(url: post.url, isEnabled: showThumbnails)
                        .frame(width: thumbnailSize, height: thumbnailSize)
                        .clipShape(.rect(cornerRadius: min(16, thumbnailSize * 0.3)))
                        .contentShape(Rectangle())
                })
                .buttonStyle(.plain)
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel("Open link")

                VStack(alignment: .leading, spacing: 6) {
                    if compactMode {
                        HStack(spacing: 6) {
                            if let host = post.url.host, !HackerNewsConstants.isItemURL(post.url) {
                                Text(truncatedHost(host).uppercased())
                                    .scaledFont(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                Text("•")
                                    .scaledFont(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            inlineUpvoteStat
                            Text("•")
                                .scaledFont(.caption)
                                .foregroundStyle(.secondary)
                            inlineCommentsStat
                        }
                    } else if let host = post.url.host, !HackerNewsConstants.isItemURL(post.url) {
                        Text(truncatedHost(host).uppercased())
                            .scaledFont(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    if showsTitle {
                        Text(post.title)
                            .scaledFont(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(titleLineLimit)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if !compactMode {
                        HStack(spacing: 8) {
                            upvotePill
                            commentsPill
                            Spacer(minLength: 8)
                            if onBookmarkTap != nil {
                                bookmarkPill
                            }
                        }
                        .scaledFont(.caption)
                        .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(dimReadPost && post.isRead ? 0.55 : 1.0)
    }

    private func truncatedHost(_ host: String) -> String {
        if host.hasPrefix("www.") {
            return String(host.dropFirst(4))
        }
        return host
    }

    var inlineUpvoteStat: some View {
        let score = displayedScore
        let isUpvoted = displayedUpvoted
        let iconName = isUpvoted ? "arrow.up.circle.fill" : "arrow.up"
        let color: Color = isUpvoted
            ? AppColors.pillForeground(for: .upvote(isActive: true), colorScheme: colorScheme)
            : .secondary
        return HStack(spacing: 3) {
            Image(systemName: iconName)
                .scaledFont(.caption2)
                .foregroundStyle(color)
            Text("\(score)")
                .scaledFont(.caption)
                .foregroundStyle(color)
        }
    }

    var inlineCommentsStat: some View {
        HStack(spacing: 3) {
            Image(systemName: "message")
                .scaledFont(.caption2)
                .foregroundStyle(.secondary)
            Text("\(post.commentsCount)")
                .scaledFont(.caption)
                .foregroundStyle(.secondary)
        }
    }

    var upvotePill: some View {
        pill(
            iconName: displayedUpvoted ? "arrow.up.circle.fill" : "arrow.up",
            text: "\(displayedScore)",
            style: .upvote(isActive: displayedUpvoted)
        )
    }

    var commentsPill: some View {
        Button(action: { onCommentsTap?() }, label: {
            pill(iconName: "message", text: "\(post.commentsCount)", style: .comments)
        })
        .buttonStyle(.plain)
    }

    var bookmarkPill: some View {
        pill(
            iconName: displayedBookmarked ? "bookmark.fill" : "bookmark",
            text: displayedBookmarked ? "Saved" : "Save",
            style: .bookmark(isSaved: displayedBookmarked)
        )
    }

    func pill(iconName: String, text: String, style: AppColors.PillStyle) -> some View {
        let background = AppColors.pillBackground(for: style, colorScheme: colorScheme)
        let foreground = AppColors.pillForeground(for: style, colorScheme: colorScheme)
        return HStack(spacing: 4) {
            Image(systemName: iconName)
                .scaledFont(.caption2)
                .foregroundStyle(foreground)
                .frame(width: 12, height: 12)
            Text(text)
                .scaledFont(.caption)
                .foregroundStyle(foreground)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Capsule().fill(background))
    }
}

public enum PostHeaderMatchedGeometryElement {
    public static func thumbnail(postID: Int) -> String { "post-header-\(postID)-thumbnail" }
    public static func domain(postID: Int) -> String { "post-header-\(postID)-domain" }
    public static func upvote(postID: Int) -> String { "post-header-\(postID)-upvote" }
    public static func comments(postID: Int) -> String { "post-header-\(postID)-comments" }
}

public enum VotingContextMenuItems {
    @ViewBuilder
    public static func postVotingMenuItems(
        for post: Post,
        onVote: @escaping @Sendable () -> Void,
        onUnvote: @escaping @Sendable () -> Void = {}
    ) -> some View {
        if post.voteLinks?.upvote != nil, !post.upvoted {
            Button { onVote() } label: { Label("Upvote", systemImage: "arrow.up") }
        }
        if post.voteLinks?.unvote != nil, post.upvoted {
            Button { onUnvote() } label: { Label("Unvote", systemImage: "arrow.uturn.down") }
        }
    }
}
