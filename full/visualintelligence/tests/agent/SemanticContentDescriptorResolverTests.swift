import VisualIntelligence

func testDefaultResolverSpecification() {
    let specification = SemanticContentDescriptor.defaultResolverSpecification
    precondition(
        specification.linuxUnavailableToken
            == VisualIntelligenceUnavailableResolverSpecification.linuxUnavailableToken
    )
}

func testSpecificationTypeAlias() {
    let value: SemanticContentDescriptor.Specification =
        VisualIntelligenceUnavailableResolverSpecification()
    precondition(type(of: value) == VisualIntelligenceUnavailableResolverSpecification.self)
    precondition(
        SemanticContentDescriptor.Specification.self
            == VisualIntelligenceUnavailableResolverSpecification.self
    )
}

func testUnwrappedTypeAlias() {
    precondition(SemanticContentDescriptor.UnwrappedType.self == SemanticContentDescriptor.self)
    let value: SemanticContentDescriptor.UnwrappedType = SemanticContentDescriptor(labels: ["x"])
    precondition(value.labels == ["x"])
}

func testValueTypeAlias() {
    precondition(SemanticContentDescriptor.ValueType.self == SemanticContentDescriptor.self)
    let value: SemanticContentDescriptor.ValueType = SemanticContentDescriptor(labels: ["y"])
    precondition(value.labels == ["y"])
}
