@_exported import Foundation

/// Linux starting point for Apple's public `VisualIntelligence` module.
///
/// The compact Xcode 26.1 surface is the `SemanticContentDescriptor` value
/// type plus its App Intents / Core Video overlays. This host stores caller
/// labels, never invents a Visual Intelligence camera scene, and never talks
/// to an App Intents resolver or ML daemon.

/// Labels describing semantic content of a Visual Intelligence scene.
///
/// On Darwin this type also conforms to App Intents display/identity protocols
/// and may carry a `CVReadOnlyPixelBuffer` from the system Visual Intelligence
/// session. Linux keeps those overlays fail-closed: `pixelBuffer` is always
/// `nil`, and display/resolver values are host tokens derived only from
/// `labels`.
public struct SemanticContentDescriptor: Equatable, Hashable, Sendable, CustomStringConvertible {
    /// Caller-supplied semantic labels. This is the only stored public field
    /// in the API digester (`isLet` + `HasStorage`).
    public let labels: [String]

    /// Linux-host construction. Apple's TBD inits also take an App Intents
    /// `IntentItemCollection` and either a pixel buffer or image-frame UUID;
    /// those parameters are not in the compact 13-identifier surface and
    /// would require undeclared modules.
    public init(labels: [String]) {
        self.labels = labels
    }

    /// The pixel buffer of the scene from Visual Intelligence.
    ///
    /// Linux never has a Visual Intelligence camera session. Always `nil`.
    public var pixelBuffer: CVReadOnlyPixelBuffer? { nil }

    /// A string that uniquely identifies this type.
    ///
    /// Linux-host token. Darwin's persistent-identifier string is unobserved.
    public static var persistentIdentifier: String {
        "VisualIntelligence.SemanticContentDescriptor"
    }

    /// A short, localized, human-readable name for the type.
    ///
    /// Linux-host name. Darwin localization catalogs are unobserved.
    public static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Semantic Content Descriptor")
    }

    /// The visual elements to display when presenting an instance of the type.
    ///
    /// Linux uses the labels joined with `", "` as the title, or the type
    /// display name when `labels` is empty. Darwin image/subtitle payloads
    /// are unobserved.
    public var displayRepresentation: DisplayRepresentation {
        let title: String
        if labels.isEmpty {
            title = Self.typeDisplayRepresentation.name
        } else {
            title = labels.joined(separator: ", ")
        }
        return DisplayRepresentation(title: title)
    }

    /// App Intents default resolver. Linux returns the unavailable specification
    /// and never resolves entities.
    public static var defaultResolverSpecification: some ResolverSpecification {
        VisualIntelligenceUnavailableResolverSpecification()
    }

    /// Concrete Linux stand-in for Apple's opaque
    /// `typealias Specification = some ResolverSpecification` (Swift rejects
    /// `some` in a typealias position on this toolchain).
    public typealias Specification = VisualIntelligenceUnavailableResolverSpecification

    public typealias UnwrappedType = SemanticContentDescriptor

    public typealias ValueType = SemanticContentDescriptor

    /// Linux-host textual representation from `labels`. Darwin's
    /// `CustomStringConvertible` format is unobserved.
    public var description: String {
        if labels.isEmpty {
            return "SemanticContentDescriptor()"
        }
        return "SemanticContentDescriptor(\(labels.joined(separator: ", ")))"
    }

    /// Synthesized `InstanceDisplayRepresentable` overlay. Linux maps the
    /// display title onto `LocalizedStringResource`. Darwin resource-table
    /// identity is unobserved.
    public var localizedStringResource: LocalizedStringResource {
        LocalizedStringResource(displayRepresentation.title)
    }
}
