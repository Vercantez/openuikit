#if canImport(Foundation)
#error("Foundation must remain hidden on the OpenUIKit production compile path")
#endif

#if !canImport(FoundationEssentials)
#error("FoundationEssentials is not visible on the OpenUIKit production compile path")
#endif

import FoundationEssentials

private let foundationEssentialsIndexPathGuard = FoundationEssentials.IndexPath()
