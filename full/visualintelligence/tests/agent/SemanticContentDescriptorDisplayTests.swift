import VisualIntelligence

func testTypeDisplayRepresentation() {
    let representation = SemanticContentDescriptor.typeDisplayRepresentation
    precondition(representation.name == "Semantic Content Descriptor")
    precondition(representation == TypeDisplayRepresentation(name: "Semantic Content Descriptor"))
}

func testDisplayRepresentationFromLabels() {
    let empty = SemanticContentDescriptor(labels: [])
    precondition(empty.displayRepresentation.title == "Semantic Content Descriptor")
    let labeled = SemanticContentDescriptor(labels: ["mug", "ceramic"])
    precondition(labeled.displayRepresentation.title == "mug, ceramic")
    precondition(labeled.displayRepresentation == DisplayRepresentation(title: "mug, ceramic"))
}

func testLocalizedStringResource() {
    let empty = SemanticContentDescriptor(labels: [])
    precondition(empty.localizedStringResource == LocalizedStringResource("Semantic Content Descriptor"))
    let labeled = SemanticContentDescriptor(labels: ["lamp"])
    precondition(labeled.localizedStringResource.key == labeled.displayRepresentation.title)
    precondition(labeled.localizedStringResource == LocalizedStringResource("lamp"))
}
