import GroupActivities
import Foundation

/// EC2 dependency-identity probe for GroupActivities.
/// Isolated `test_host.sh` does not compile this file. A future clean guest
/// build must import real Foundation (not a framework-local stand-in) and
/// pass `URL`, `UUID`, and `Data` through the public GroupActivities surface.
enum GroupActivitiesDependencyIdentity {
    static func main() {
        var metadata = GroupActivityMetadata()
        let fallback = URL(string: "https://example.invalid/group-activity")!
        metadata.fallbackURL = fallback
        let assigned: URL? = metadata.fallbackURL
        if assigned != fallback {
            fatalError("fallbackURL did not preserve Foundation.URL")
        }

        let identifier = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
        if identifier.uuidString.isEmpty {
            fatalError("Foundation.UUID missing")
        }

        do {
            let encoded: Data = try JSONEncoder().encode(metadata)
            if encoded.isEmpty {
                fatalError("encode(to:) produced empty Data")
            }
            let decoded = try JSONDecoder().decode(GroupActivityMetadata.self, from: encoded)
            if decoded.fallbackURL != fallback {
                fatalError("JSON Data round-trip dropped Foundation.URL")
            }
        } catch {
            fatalError("Foundation Data round-trip failed: \(error)")
        }

        print("GROUPACTIVITIES_DEPENDENCY_IDENTITY_OK foundation=URL,UUID,Data")
    }
}

GroupActivitiesDependencyIdentity.main()
