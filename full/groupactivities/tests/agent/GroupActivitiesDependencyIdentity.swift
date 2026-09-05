@_spi(OpenUIKitHost) import GroupActivities
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

        let participant = Participant(id: UUID())
        let event = GroupSessionEvent(
            originator: participant,
            action: .play,
            url: fallback
        )
        if event.url != fallback {
            fatalError("GroupSessionEvent.url did not preserve Foundation.URL")
        }

        struct IdentityActivity: GroupActivity, Equatable {
            var label: String
            var metadata: GroupActivityMetadata {
                get async { GroupActivityMetadata() }
            }
        }

        let session = GroupSession<IdentityActivity>.makeHostSession(
            activity: IdentityActivity(label: "identity")
        )
        let messenger = GroupSessionMessenger(session: session)
        let payload = Data([0x47, 0x41])
        var seen: (any Error)?
        messenger.send(payload, to: .all) { error in
            seen = error
        }
        if seen == nil {
            fatalError("Data send must fail closed on Linux")
        }

        print("GROUPACTIVITIES_DEPENDENCY_IDENTITY_OK foundation=URL,UUID,Data")
    }
}

GroupActivitiesDependencyIdentity.main()
