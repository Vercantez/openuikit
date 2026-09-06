import VisualIntelligence

func testPersistentIdentifier() {
    precondition(
        SemanticContentDescriptor.persistentIdentifier
            == "VisualIntelligence.SemanticContentDescriptor"
    )
}

func testSynthesizedPersistentIdentifierStability() {
    let first = SemanticContentDescriptor.persistentIdentifier
    let second = SemanticContentDescriptor.persistentIdentifier
    precondition(first == second)
    precondition(!first.isEmpty)
    let a = SemanticContentDescriptor(labels: ["a"])
    let b = SemanticContentDescriptor(labels: ["b"])
    _ = a
    _ = b
    precondition(type(of: SemanticContentDescriptor.persistentIdentifier) == String.self)
}
