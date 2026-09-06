import Foundation

/// Web application manifest wrapper. Construction succeeds only when
/// `jsonData` is a JSON object. Schema fields beyond that are unobserved.
public final class BEWebAppManifest: NSObject, @unchecked Sendable {
    public let jsonData: Data
    public let manifestURL: URL

    public init?(jsonData: Data, manifestURL: URL) {
        guard
            let object = try? JSONSerialization.jsonObject(with: jsonData),
            object is [String: Any]
        else {
            return nil
        }
        self.jsonData = jsonData
        self.manifestURL = manifestURL
        super.init()
    }

    public convenience init?(JSONData jsonData: Data, manifestURL: URL) {
        self.init(jsonData: jsonData, manifestURL: manifestURL)
    }
}
