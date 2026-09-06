import Foundation
@_spi(OpenUIKitHost) import ManagedAppDistribution

func testContentStyleCases() {
    precondition(ManagedContentStyle.header != .compact)
    precondition(ManagedContentStyle.compact != .automatic)
    precondition(ManagedContentStyle.header != .automatic)
    precondition(ManagedContentStyle.automatic == .automatic)
}

func testContentStyleHostNames() {
    precondition(ManagedContentStyle.header._linuxName == "header")
    precondition(ManagedContentStyle.compact._linuxName == "compact")
    precondition(ManagedContentStyle.automatic._linuxName == "automatic")
}

func testOfferStateCases() {
    precondition(ManagedContentOfferState.notInstalled != .neverInstalled)
    precondition(ManagedContentOfferState.neverInstalled != .installed)
    precondition(ManagedContentOfferState.installed != .noninteractive)
    precondition(ManagedContentOfferState.noninteractive != .notInstalled)
}

func testOfferStateInstallingProgress() {
    let unknown = ManagedContentOfferState.installing(progress: nil)
    let half = ManagedContentOfferState.installing(progress: 0.5)
    precondition(unknown != half)
    precondition(unknown._linuxProgress == nil)
    precondition(half._linuxProgress == 0.5)
    precondition(ManagedContentOfferState.installed._linuxProgress == nil)
}

func testOfferStateCustomTitle() {
    let a = ManagedContentOfferState.custom(title: "Open")
    let b = ManagedContentOfferState.custom(title: "Install")
    precondition(a != b)
    precondition(a._linuxCustomTitle == "Open")
    precondition(b._linuxCustomTitle == "Install")
    precondition(ManagedContentOfferState.installed._linuxCustomTitle == nil)
}

func testOfferStateHashable() {
    precondition(ManagedContentOfferState.installed == .installed)
    precondition(Set([ManagedContentOfferState.installed, .installed, .notInstalled]).count == 2)
    var hasher = Hasher()
    ManagedContentOfferState.noninteractive.hash(into: &hasher)
    _ = hasher.finalize()
}

func testOfferStateInequality() {
    precondition(ManagedContentOfferState.installed != .notInstalled)
    precondition(!(ManagedContentOfferState.neverInstalled != .neverInstalled))
}

func testManagedContentStyleModifier() {
    let app = ManagedApp(id: "com.example.style", name: "Styled")
    let view = ManagedAppView(app: app)
    _ = view.managedContentStyle(.compact)
    precondition(ManagedContentStyleStorage.last == .compact)
    _ = view.managedContentStyle(.header)
    precondition(ManagedContentStyleStorage.last == .header)
}
