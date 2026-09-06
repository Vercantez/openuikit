import Foundation

#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(ManagedSettings)
import ManagedSettings
#endif

/// SwiftUI picker for applications, categories, and web domains.
///
/// Darwin marks this type `@MainActor @preconcurrency`. The isolated-host
/// `View` lookalike is nonisolated, so Linux omits the actor annotation to
/// compile without SwiftUI. The picker still never presents UI.
///
/// Linux stores the selection binding and optional header/footer copy, then
/// renders `EmptyView`. It never presents Apple's FamilyActivityPicker sheet
/// and never mutates the selection.
public struct FamilyActivityPicker: View {
    public typealias Body = EmptyView

    private let headerText: String?
    private let footerText: String?
    private let selection: Binding<FamilyActivitySelection>

    public init(selection: Binding<FamilyActivitySelection>) {
        self.headerText = nil
        self.footerText = nil
        self.selection = selection
    }

    public init(
        headerText: String? = nil,
        footerText: String? = nil,
        selection: Binding<FamilyActivitySelection>
    ) {
        self.headerText = headerText
        self.footerText = footerText
        self.selection = selection
    }

    public var body: EmptyView {
        _ = selection.wrappedValue
        _ = headerText
        _ = footerText
        return EmptyView()
    }

    var linuxHeaderText: String? { headerText }
    var linuxFooterText: String? { footerText }
}

/// Icon half of a FamilyControls `Label` for an activity token.
///
/// Darwin is `@MainActor @preconcurrency`. Linux has no app/category/domain
/// artwork. `body` is `EmptyView`.
public struct FamilyActivityIconView: View {
    public typealias Body = EmptyView

    public init() {}

    public var body: EmptyView { EmptyView() }
}

/// Title half of a FamilyControls `Label` for an activity token.
///
/// Darwin is `@MainActor @preconcurrency`. Linux has no localized
/// app/category/domain titles. `body` is `EmptyView`.
public struct FamilyActivityTitleView: View {
    public typealias Body = EmptyView

    public init() {}

    public var body: EmptyView { EmptyView() }
}

extension Label where Title == FamilyActivityTitleView, Icon == FamilyActivityIconView {
    public init(_ applicationToken: ApplicationToken) {
        _ = applicationToken
        self.init(
            title: { FamilyActivityTitleView() },
            icon: { FamilyActivityIconView() }
        )
    }

    public init(_ categoryToken: ActivityCategoryToken) {
        _ = categoryToken
        self.init(
            title: { FamilyActivityTitleView() },
            icon: { FamilyActivityIconView() }
        )
    }

    public init(_ webDomainToken: WebDomainToken) {
        _ = webDomainToken
        self.init(
            title: { FamilyActivityTitleView() },
            icon: { FamilyActivityIconView() }
        )
    }
}

extension View {
    /// Presents Apple's FamilyActivityPicker as a sheet on Darwin.
    /// Linux returns `self` unchanged and does not present UI.
    public func familyActivityPicker(
        isPresented: Binding<Bool>,
        selection: Binding<FamilyActivitySelection>
    ) -> some View {
        _ = isPresented.wrappedValue
        _ = selection.wrappedValue
        return self
    }

    /// Presents Apple's FamilyActivityPicker as a sheet on Darwin.
    /// Linux returns `self` unchanged and does not present UI.
    public func familyActivityPicker(
        headerText: String? = nil,
        footerText: String? = nil,
        isPresented: Binding<Bool>,
        selection: Binding<FamilyActivitySelection>
    ) -> some View {
        _ = headerText
        _ = footerText
        _ = isPresented.wrappedValue
        _ = selection.wrappedValue
        return self
    }
}

extension FamilyActivityPicker {
    @_spi(OpenUIKitHost)
    public var hostHeaderText: String? { linuxHeaderText }

    @_spi(OpenUIKitHost)
    public var hostFooterText: String? { linuxFooterText }
}
