@_spi(OpenUIKitHost) import VisionKit
import Foundation

/// Table-driven Linux-local bits for `ImageAnalysisInteraction.InteractionTypes`.
/// Darwin numeric ABI is unobserved (see oracle-questions.tsv).
func testInteractionTypesBits() {
    typealias Types = ImageAnalysisInteraction.InteractionTypes
    let catalog: [(Types, UInt)] = [
        (.automatic, 1 << 0),
        (.automaticTextOnly, 1 << 1),
        (.textSelection, 1 << 2),
        (.dataDetectors, 1 << 3),
        (.visualLookUp, 1 << 4),
        (.imageSubject, 1 << 5),
    ]
    for (flag, bit) in catalog {
        precondition(flag.rawValue == bit)
        precondition(Types(rawValue: bit) == flag)
        precondition(Types(rawValue: bit).contains(flag))
    }
    precondition(Types.automatic != .automaticTextOnly)
    precondition(Types.dataDetectors != .visualLookUp)
    precondition(Types.imageSubject != .textSelection)
    precondition(Types.Element.self == Types.self)
    precondition(Types.ArrayLiteralElement.self == Types.self)
    precondition(Types.RawValue.self == UInt.self)
    let passthrough = Types(rawValue: (1 << 2) | (1 << 5))
    precondition(passthrough.contains(.textSelection))
    precondition(passthrough.contains(.imageSubject))
    precondition(!passthrough.contains(.automatic))
}

func testInteractionTypesAlgebra() {
    typealias Types = ImageAnalysisInteraction.InteractionTypes
    var types: Types = []
    precondition(types.isEmpty)
    types = [.automatic, .textSelection]
    precondition(types.contains(.automatic))
    precondition(types.contains(.textSelection))
    precondition(!types.contains(.imageSubject))
    precondition(types != .automatic)
    precondition(types.union(.dataDetectors).contains(.dataDetectors))
    precondition(types.intersection(.automatic) == .automatic)
    precondition(types.subtracting(.automatic).contains(.textSelection))
    precondition(types.isSuperset(of: .automatic))
    precondition(!types.isSubset(of: .automatic))
    precondition(types.isStrictSuperset(of: .automatic))
    precondition(Types.automatic.isStrictSubset(of: types))
    precondition(!types.isDisjoint(with: .automatic))
    precondition(Types().isDisjoint(with: .automatic))

    var copy = types
    copy.insert(.imageSubject)
    precondition(copy.contains(.imageSubject))
    _ = copy.remove(.automatic)
    precondition(!copy.contains(.automatic))
    _ = copy.update(with: .visualLookUp)
    copy.formUnion(.automaticTextOnly)
    copy.formIntersection([.textSelection, .imageSubject, .visualLookUp])
    copy.formSymmetricDifference(.visualLookUp)
    copy.subtract(.imageSubject)
    precondition(copy.contains(.textSelection))

    let fromSequence = Types([.dataDetectors, .dataDetectors])
    precondition(fromSequence.contains(.dataDetectors))
    let symmetric = Types.automatic.symmetricDifference(.textSelection)
    precondition(symmetric.contains(.automatic))
    precondition(symmetric.contains(.textSelection))
}

func testPreferredAndActiveInteractionTypes() {
    let interaction = ImageAnalysisInteraction()
    precondition(interaction.preferredInteractionTypes.isEmpty)
    precondition(interaction.activeInteractionTypes.isEmpty)

    interaction.preferredInteractionTypes = [.textSelection]
    precondition(interaction.preferredInteractionTypes.contains(.textSelection))
    precondition(interaction.activeInteractionTypes.isEmpty)

    interaction.analysis = ImageAnalysis.hostFixture(transcript: "abc", resultTypes: [.text])
    precondition(interaction.activeInteractionTypes.contains(.textSelection))
    precondition(!interaction.activeInteractionTypes.contains(.automatic))

    interaction.preferredInteractionTypes = []
    precondition(interaction.activeInteractionTypes.isEmpty)
}
