import Foundation

/// The features supported by PaperKit UI / data models.
public struct FeatureSet: Equatable, Sendable {
    /// The version of PaperKit supported.
    public var contentVersion: ContentVersion
    /// The supported shape types.
    ///
    /// Default is all shapes. Set to an empty set to disable all shapes.
    public var shapes: Set<ShapeConfiguration.Shape>
    /// The supported features.
    ///
    /// Default is all features.
    public var features: Set<Feature>
    /// The inks types that are supported.
    ///
    /// Defaults to all inks.
    public var inks: Set<PKInkingTool.InkType>
    /// The allowed ends of line for arrows.
    ///
    /// Default is `.all`.
    public var lineMarkerPositions: LineMarkerPositions
    /// The maximum exposure to allow for choosing colors.
    ///
    /// Default is 1.0, which is SDR.
    public var colorMaximumLinearExposure: CGFloat

    init(
        contentVersion: ContentVersion,
        shapes: Set<ShapeConfiguration.Shape>,
        features: Set<Feature>,
        inks: Set<PKInkingTool.InkType>,
        lineMarkerPositions: LineMarkerPositions,
        colorMaximumLinearExposure: CGFloat
    ) {
        self.contentVersion = contentVersion
        self.shapes = shapes
        self.features = features
        self.inks = inks
        self.lineMarkerPositions = lineMarkerPositions
        self.colorMaximumLinearExposure = colorMaximumLinearExposure
    }

    /// The features that PaperKit markup supports.
    public enum Feature: Equatable, Hashable, Sendable, CaseIterable {
        /// Supports image elements.
        case images
        /// Supports inserting stickers.
        case stickers
        /// Supports loupe elements.
        case loupes
        /// Supports link elements.
        case links
        /// Supports shapes with fills.
        case shapeFills
        /// Supports shapes with strokes.
        case shapeStrokes
        /// Supports shapes with opacity.
        case shapeOpacity
        /// Supports shapes with text.
        case text
        /// Supports drawing.
        case drawing
    }

    /// Which ends of a line can have arrows.
    public struct LineMarkerPositions: OptionSet, Hashable, Sendable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        /// Neither end of a line has markers.
        ///
        /// Linux bit `1 << 0`. Apple's exact bits are an oracle question.
        public static let plain = LineMarkerPositions(rawValue: 1 << 0)
        /// Either the start/end of a line has a marker.
        public static let single = LineMarkerPositions(rawValue: 1 << 1)
        /// Both the start and end of a line has a marker.
        public static let double = LineMarkerPositions(rawValue: 1 << 2)
        /// All possible combinations of marker positions.
        public static let all: LineMarkerPositions = [.plain, .single, .double]
    }

    public enum ContentVersion: Int, Sendable, Hashable {
        /// The PaperKit version that supports markup from iOS 19.
        ///
        /// Linux maps this case to raw value `1`, matching
        /// `PKContentVersion.version1`. Apple's exact integer is unobserved.
        case version1 = 1

        /// A property that returns latest version of PaperKit, which supports
        /// all currently available features.
        public static var latest: ContentVersion { .version1 }

        /// The PencilKit content version that this PaperKit version relies on.
        ///
        /// Linux `version1` includes every documented ink, including reed
        /// (`PKContentVersion.version4` / `.latest`). The Darwin pairing is
        /// an oracle question.
        public var pencilKitContentVersion: PKContentVersion {
            .latest
        }
    }

    /// A maximally empty feature set.
    public static var empty: FeatureSet {
        FeatureSet(
            contentVersion: .version1,
            shapes: [],
            features: [],
            inks: [],
            lineMarkerPositions: [],
            colorMaximumLinearExposure: 1.0
        )
    }

    /// A new feature set supporting all features in `.version1`.
    public static var version1: FeatureSet {
        FeatureSet(
            contentVersion: .version1,
            shapes: Set(ShapeConfiguration.Shape.allCases),
            features: Set(Feature.allCases),
            inks: paperKitAllInkTypes(),
            lineMarkerPositions: .all,
            colorMaximumLinearExposure: 1.0
        )
    }

    /// A new feature set supporting all features.
    ///
    /// Only `ContentVersion.version1` exists in the pinned graph, so
    /// `.latest` currently equals `.version1`.
    public static var latest: FeatureSet { .version1 }

    /// Returns a Boolean value that indicates whether the given feature
    /// exists in the set.
    public func contains(_ feature: Feature) -> Bool {
        features.contains(feature)
    }

    /// Inserts the given feature in the set if it is not already present.
    public mutating func insert(_ newFeature: Feature) {
        features.insert(newFeature)
    }

    /// Removes the given feature.
    public mutating func remove(_ feature: Feature) {
        features.remove(feature)
    }

    /// Returns a Boolean value that indicates whether this feature set is a
    /// subset of the given feature set.
    public func isSubset(of other: FeatureSet) -> Bool {
        features.isSubset(of: other.features)
            && shapes.isSubset(of: other.shapes)
            && inks.isSubset(of: other.inks)
            && lineMarkerPositions.isSubset(of: other.lineMarkerPositions)
            && colorMaximumLinearExposure <= other.colorMaximumLinearExposure
            && contentVersion.rawValue <= other.contentVersion.rawValue
    }
}
