import Foundation

/// Values you use to update properties in a postback, such as the conversion value.
public struct PostbackUpdate: Sendable {
    /// Values that describe the types of conversions.
    public enum ConversionType: String, Hashable, Sendable {
        /// The value that represents the installation of an app after an ad interaction.
        case install
        /// The value that represents someone reengaging with an app they've previously installed.
        case reengagement
    }

    /// An integer that represents the fine conversion value.
    public let fineConversionValue: Int
    /// A Boolean value that indicates whether the system should lock the postback.
    public let lockPostback: Bool
    /// An enumeration that represents the coarse conversion value.
    public let coarseConversionValue: CoarseConversionValue?
    /// Conversion types the system uses to determine which postbacks to update.
    ///
    /// If `nil`, the advertised-app API would update all postback types. Linux
    /// still fail-closes at `Postback.updateConversionValue`.
    public let conversionTypes: [PostbackUpdate.ConversionType]?
    /// An optional conversion tag that selects a specific reengagement conversion.
    public let conversionTag: String?

    /// Creates a new postback update with conversion values, conversion types, and a lock flag.
    public init(
        fineConversionValue: Int,
        lockPostback: Bool,
        coarseConversionValue: CoarseConversionValue? = nil,
        conversionTypes: [PostbackUpdate.ConversionType]? = nil
    ) {
        self.fineConversionValue = fineConversionValue
        self.lockPostback = lockPostback
        self.coarseConversionValue = coarseConversionValue
        self.conversionTypes = conversionTypes
        self.conversionTag = nil
    }

    /// Creates a new postback update that also carries a conversion tag.
    public init(
        fineConversionValue: Int,
        lockPostback: Bool,
        conversionTag: String,
        coarseConversionValue: CoarseConversionValue? = nil,
        conversionTypes: [PostbackUpdate.ConversionType]? = nil
    ) {
        self.fineConversionValue = fineConversionValue
        self.lockPostback = lockPostback
        self.coarseConversionValue = coarseConversionValue
        self.conversionTypes = conversionTypes
        self.conversionTag = conversionTag
    }
}

/// Methods that advertised apps use to update conversion values for ad attributions.
///
/// Linux has no Apple postback pipeline. `isSupported` is `false`, and every
/// update method throws a fail-closed `AdAttributionKitError`.
public struct Postback: Sendable {
    /// Query parameter AdAttributionKit appends to a reengagement universal link.
    ///
    /// Documented as the `AdAttributionKitReengagementOpen` key.
    public static var reengagementOpenURLParameter: String {
        "AdAttributionKitReengagementOpen"
    }

    /// Whether the framework supports postbacks on this device.
    public static var isSupported: Bool {
        LinuxAdAttributionBoundary.isSupported
    }

    /// Updates a conversion value and optionally locks the postback.
    public static func updateConversionValue(
        _ fineConversionValue: Int,
        lockPostback: Bool
    ) async throws {
        _ = (fineConversionValue, lockPostback)
        throw LinuxAdAttributionBoundary.postbackUnavailable(conversionTag: nil)
    }

    /// Updates the conversion value with fine and coarse values, and optionally locks the postback.
    public static func updateConversionValue(
        _ fineConversionValue: Int,
        coarseConversionValue: CoarseConversionValue,
        lockPostback: Bool
    ) async throws {
        _ = (fineConversionValue, coarseConversionValue, lockPostback)
        throw LinuxAdAttributionBoundary.postbackUnavailable(conversionTag: nil)
    }

    /// Updates the conversion value using a postback update configuration.
    public static func updateConversionValue(
        _ postbackUpdate: PostbackUpdate
    ) async throws {
        throw LinuxAdAttributionBoundary.postbackUnavailable(
            conversionTag: postbackUpdate.conversionTag
        )
    }
}
