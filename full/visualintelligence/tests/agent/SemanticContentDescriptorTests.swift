import VisualIntelligence

func testSemanticContentDescriptorValueType() {
    let first = SemanticContentDescriptor(labels: ["cat", "indoor"])
    let same = SemanticContentDescriptor(labels: ["cat", "indoor"])
    let other = SemanticContentDescriptor(labels: ["dog"])
    precondition(first == same)
    precondition(first != other)
    precondition(first.hashValue == same.hashValue)
    precondition(type(of: first) == SemanticContentDescriptor.self)
}

func testLabelsStored() {
    let empty = SemanticContentDescriptor(labels: [])
    precondition(empty.labels.isEmpty)
    let labeled = SemanticContentDescriptor(labels: ["red", "car"])
    precondition(labeled.labels == ["red", "car"])
    precondition(labeled.labels.count == 2)
}

func testDescriptionFormat() {
    let empty = SemanticContentDescriptor(labels: [])
    precondition(empty.description == "SemanticContentDescriptor()")
    precondition(String(describing: empty) == "SemanticContentDescriptor()")
    let labeled = SemanticContentDescriptor(labels: ["oak", "tree"])
    precondition(labeled.description == "SemanticContentDescriptor(oak, tree)")
    precondition(String(describing: labeled) == labeled.description)
}
