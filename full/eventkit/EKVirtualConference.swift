import Foundation

/// Virtual-conference URL presented to a calendar client.
open class EKVirtualConferenceURLDescriptor: NSObject {
    public let title: String?
    public let url: URL

    public init(title: String?, url: URL) {
        self.title = title
        self.url = url
        super.init()
    }

    public init(title: String?, URL: URL) {
        self.title = title
        self.url = URL
        super.init()
    }
}

/// Room-type identity advertised by a conference provider.
open class EKVirtualConferenceRoomTypeDescriptor: NSObject {
    public let title: String
    public let identifier: EKVirtualConferenceRoomTypeIdentifier

    public init(title: String, identifier: EKVirtualConferenceRoomTypeIdentifier) {
        self.title = title
        self.identifier = identifier
        super.init()
    }
}

/// Join details for a virtual conference attached to an event.
open class EKVirtualConferenceDescriptor: NSObject {
    public let title: String?
    public let urlDescriptors: [EKVirtualConferenceURLDescriptor]
    public let conferenceDetails: String?

    public init(
        title: String?,
        urlDescriptors: [EKVirtualConferenceURLDescriptor],
        conferenceDetails: String?
    ) {
        self.title = title
        self.urlDescriptors = urlDescriptors
        self.conferenceDetails = conferenceDetails
        super.init()
    }

    public init(
        title: String?,
        URLDescriptors: [EKVirtualConferenceURLDescriptor],
        conferenceDetails: String?
    ) {
        self.title = title
        self.urlDescriptors = URLDescriptors
        self.conferenceDetails = conferenceDetails
        super.init()
    }
}

/// Linux has no EventKit virtual-conference extension host. Fetch APIs fail closed.
open class EKVirtualConferenceProvider: NSObject {
    public override init() {
        super.init()
    }

    open func fetchAvailableRoomTypes(
        completionHandler: @escaping ([EKVirtualConferenceRoomTypeDescriptor]?, (any Error)?) -> Void
    ) {
        completionHandler(nil, EKMakeError(.osNotSupported))
    }

    open func fetchVirtualConference(
        identifier: EKVirtualConferenceRoomTypeIdentifier
    ) async throws -> EKVirtualConferenceDescriptor {
        _ = identifier
        throw EKMakeError(.osNotSupported)
    }
}
