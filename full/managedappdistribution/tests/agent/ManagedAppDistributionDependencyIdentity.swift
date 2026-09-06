import Foundation
import ManagedAppDistribution

// Isolated-host identity probe. The sealed host gate does not compile this
// file. The later EC2 integration build imports real Foundation and passes
// genuine Foundation values through public ManagedAppDistribution APIs.
func managedAppDistributionDependencyIdentityProbe() {
    let data = Data("managed-app".utf8)
    let url = URL(string: "https://example.invalid/privacy")!
    let measurement = Measurement(value: Double(data.count), unit: UnitInformationStorage.bytes)
    precondition(type(of: data) == Data.self)
    precondition(type(of: url) == URL.self)
    precondition(type(of: measurement) == Measurement<UnitInformationStorage>.self)
    precondition(!String(reflecting: type(of: data)).hasPrefix("ManagedAppDistribution."))
    precondition(!String(reflecting: type(of: url)).hasPrefix("ManagedAppDistribution."))

    let app = ManagedApp(
        id: String(data: data, encoding: .utf8) ?? "id",
        name: "Identity",
        fileSize: measurement,
        developerWebsite: url,
        privacyPolicy: url
    )
    precondition(app.fileSize == measurement)
    precondition(app.privacyPolicy == url)

    let error = ManagedAppDistributionError.networkError
    precondition(!error.description.isEmpty)
}
