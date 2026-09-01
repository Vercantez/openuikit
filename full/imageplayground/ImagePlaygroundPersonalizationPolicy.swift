/// Policy for enabling or disabling personalization in the system interface.
///
/// Raw values are Swift's synthesized `Int` assignment in declaration order.
/// Apple's runtime integers are not in the pinned public inputs.
public enum ImagePlaygroundPersonalizationPolicy: Int, Hashable, Sendable {
    case automatic
    case enabled
    case disabled
}
