import SwiftUI

// This is an ordinary SwiftUI client rather than part of the SwiftUI module.
// Its sole job is to prove that the packaged native compiler-plugin libraries
// expand both source-facing macro families through the same arguments consumed
// by application, framework, and SwiftPM target compiles.
private extension EnvironmentValues {
    @Entry var portableCompilerPluginProbe: Int = 17
}

#Preview {
    Text("portable unnamed preview")
}

#Preview("portable named preview") {
    Text("portable named preview")
}

private func requireEntryExpansion(_ values: inout EnvironmentValues) -> Int {
    values.portableCompilerPluginProbe += 1
    return values.portableCompilerPluginProbe
}
