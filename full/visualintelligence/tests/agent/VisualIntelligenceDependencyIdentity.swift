import Foundation
import VisualIntelligence

/// Future clean EC2 probe. Isolated Linux hosts typecheck Foundation values
/// through public VisualIntelligence APIs; this file is not compiled by the
/// sealed host gate.
func visualIntelligenceDependencyIdentityProbe() {
    let stamp = Date(timeIntervalSince1970: 1_700_000_000)
    precondition(type(of: stamp) == Date.self)
    precondition(!String(reflecting: type(of: stamp)).hasPrefix("VisualIntelligence."))

    let labels = ["plant"]
    let descriptor = SemanticContentDescriptor(labels: labels)
    precondition(descriptor.labels == labels)
    precondition(type(of: descriptor.labels) == [String].self)

    let described = String(describing: descriptor)
    precondition(type(of: described) == String.self)

    _ = VisualIntelligenceLinuxUnavailableError(operation: "dependency-identity")
}

#if VISUALINTELLIGENCE_IDENTITY_MAIN
visualIntelligenceDependencyIdentityProbe()
print("VISUALINTELLIGENCE_DEPENDENCY_IDENTITY_OK")
#endif
