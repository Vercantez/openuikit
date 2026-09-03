import Foundation
import CoreSpotlight

/// Schema-v2 sealed runner compiles `CoreSpotlightLoadSmoke.swift` and
/// `*Tests.swift`. This probe remains as the named runtime entry the wave-5
/// house rules ask for; it does not print.
func coreSpotlightRuntimeProbe() {
  _ = CSSearchableIndex.isIndexingAvailable()
  _ = CSIndexErrorDomain
  _ = CSSearchableItemActionType
}
