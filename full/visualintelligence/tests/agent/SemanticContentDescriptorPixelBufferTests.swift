import VisualIntelligence

func testPixelBufferFailClosed() {
    let empty = SemanticContentDescriptor(labels: [])
    precondition(empty.pixelBuffer == nil)
    let labeled = SemanticContentDescriptor(labels: ["scene"])
    precondition(labeled.pixelBuffer == nil)
    let _: CVReadOnlyPixelBuffer? = labeled.pixelBuffer
}
