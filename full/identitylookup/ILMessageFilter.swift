import Foundation
import FoundationNetworking

/// Base class for a Message Filter app extension. Linux has no extension
/// host; constructing an instance does not install or enable filtering.
open class ILMessageFilterExtension: NSObject {
    public override init() {
        super.init()
    }
}

/// Extension context used to defer a filter query to the associated
/// network service. Darwin subclasses `NSExtensionContext`; Linux has no
/// Foundation `NSExtensionContext`, so this is an `NSObject` stand-in.
open class ILMessageFilterExtensionContext: NSObject {
    public override init() {
        super.init()
    }

    /// Always fail-closed. Linux has no `ILMessageFilterNetworkURL` and no
    /// Message Filter daemon, so the completion runs immediately with
    /// `ILMessageFilterError.invalidNetworkURL`.
    public func deferQueryRequestToNetwork(
        completion: @escaping (ILNetworkResponse?, (any Error)?) -> Void
    ) {
        completion(nil, IdentityLookupLinux.filterError(.invalidNetworkURL))
    }
}

/// Offline query describing an SMS/MMS from an unknown sender.
open class ILMessageFilterQueryRequest: NSObject, NSSecureCoding {
    public private(set) var sender: String?
    public private(set) var messageBody: String?
    public private(set) var receiverISOCountryCode: String?

    public static var supportsSecureCoding: Bool { true }

    public init(
        sender: String?,
        messageBody: String?,
        receiverISOCountryCode: String?
    ) {
        self.sender = sender
        self.messageBody = messageBody
        self.receiverISOCountryCode = receiverISOCountryCode
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.sender = IdentityLookupLinux.decodeString(coder, key: "linuxSender")
        self.messageBody = IdentityLookupLinux.decodeString(coder, key: "linuxMessageBody")
        self.receiverISOCountryCode = IdentityLookupLinux.decodeString(
            coder,
            key: "linuxReceiverISOCountryCode"
        )
        super.init()
    }

    open func encode(with coder: NSCoder) {
        IdentityLookupLinux.encodeString(sender, coder, key: "linuxSender")
        IdentityLookupLinux.encodeString(messageBody, coder, key: "linuxMessageBody")
        IdentityLookupLinux.encodeString(
            receiverISOCountryCode,
            coder,
            key: "linuxReceiverISOCountryCode"
        )
    }
}

/// Offline decision for a Message Filter query.
open class ILMessageFilterQueryResponse: NSObject, NSSecureCoding {
    public var action: ILMessageFilterAction
    public var subAction: ILMessageFilterSubAction

    public static var supportsSecureCoding: Bool { true }

    public override init() {
        self.action = .none
        self.subAction = .none
        super.init()
    }

    public required init?(coder: NSCoder) {
        let actionRaw = IdentityLookupLinux.decodeInt(coder, key: "linuxAction") ?? 0
        let subRaw = IdentityLookupLinux.decodeInt(coder, key: "linuxSubAction") ?? 0
        self.action = ILMessageFilterAction(rawValue: actionRaw) ?? .none
        self.subAction = ILMessageFilterSubAction(rawValue: subRaw) ?? .none
        super.init()
    }

    open func encode(with coder: NSCoder) {
        IdentityLookupLinux.encodeInt(action.rawValue, coder, key: "linuxAction")
        IdentityLookupLinux.encodeInt(subAction.rawValue, coder, key: "linuxSubAction")
    }
}

/// Body of a network-deferral response. Only the system constructs this on
/// Darwin; Linux allows a local value for coding tests and never pretends it
/// came from Apple's filter network.
open class ILNetworkResponse: NSObject, NSSecureCoding {
    public private(set) var urlResponse: FoundationNetworking.HTTPURLResponse
    public private(set) var data: Data

    public static var supportsSecureCoding: Bool { true }

    public init(urlResponse: FoundationNetworking.HTTPURLResponse, data: Data) {
        self.urlResponse = urlResponse
        self.data = data
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard
            let urlString = IdentityLookupLinux.decodeString(coder, key: "linuxURL"),
            let url = URL(string: urlString),
            let status = IdentityLookupLinux.decodeInt(coder, key: "linuxStatus"),
            let payload = coder.decodeObject(of: NSData.self, forKey: "linuxData") as Data?,
            let response = FoundationNetworking.HTTPURLResponse(
                url: url,
                statusCode: status,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )
        else {
            return nil
        }
        self.urlResponse = response
        self.data = payload
        super.init()
    }

    open func encode(with coder: NSCoder) {
        IdentityLookupLinux.encodeString(
            urlResponse.url?.absoluteString,
            coder,
            key: "linuxURL"
        )
        IdentityLookupLinux.encodeInt(urlResponse.statusCode, coder, key: "linuxStatus")
        coder.encode(data as NSData, forKey: "linuxData")
    }
}

/// Capabilities probe sent to a Message Filter extension. Empty on Linux;
/// no host fills this in.
open class ILMessageFilterCapabilitiesQueryRequest: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init()
        _ = coder
    }

    open func encode(with coder: NSCoder) {
        _ = coder
    }
}

/// Capabilities advertised by a Message Filter extension.
open class ILMessageFilterCapabilitiesQueryResponse: NSObject, NSSecureCoding {
    public var promotionalSubActions: [ILMessageFilterSubAction]
    public var transactionalSubActions: [ILMessageFilterSubAction]

    public static var supportsSecureCoding: Bool { true }

    public override init() {
        self.promotionalSubActions = []
        self.transactionalSubActions = []
        super.init()
    }

    public required init?(coder: NSCoder) {
        let promoCount = IdentityLookupLinux.decodeInt(coder, key: "linuxPromoCount") ?? 0
        var promo: [ILMessageFilterSubAction] = []
        for index in 0..<promoCount {
            let raw = IdentityLookupLinux.decodeInt(coder, key: "linuxPromo[\(index)]") ?? 0
            promo.append(ILMessageFilterSubAction(rawValue: raw) ?? .none)
        }
        let txnCount = IdentityLookupLinux.decodeInt(coder, key: "linuxTxnCount") ?? 0
        var txn: [ILMessageFilterSubAction] = []
        for index in 0..<txnCount {
            let raw = IdentityLookupLinux.decodeInt(coder, key: "linuxTxn[\(index)]") ?? 0
            txn.append(ILMessageFilterSubAction(rawValue: raw) ?? .none)
        }
        self.promotionalSubActions = promo
        self.transactionalSubActions = txn
        super.init()
    }

    open func encode(with coder: NSCoder) {
        IdentityLookupLinux.encodeInt(
            promotionalSubActions.count,
            coder,
            key: "linuxPromoCount"
        )
        for (index, action) in promotionalSubActions.enumerated() {
            IdentityLookupLinux.encodeInt(action.rawValue, coder, key: "linuxPromo[\(index)]")
        }
        IdentityLookupLinux.encodeInt(
            transactionalSubActions.count,
            coder,
            key: "linuxTxnCount"
        )
        for (index, action) in transactionalSubActions.enumerated() {
            IdentityLookupLinux.encodeInt(action.rawValue, coder, key: "linuxTxn[\(index)]")
        }
    }
}

/// Message Filter query handling. Darwin uses an ObjC completion; the Swift
/// overlay is `async`. Linux declares the overlay signature. There is no
/// extension host to invoke it.
public protocol ILMessageFilterQueryHandling: NSObjectProtocol {
    func handle(
        _ queryRequest: ILMessageFilterQueryRequest,
        context: ILMessageFilterExtensionContext
    ) async -> ILMessageFilterQueryResponse
}

/// Message Filter capabilities handling. Same overlay notes as
/// `ILMessageFilterQueryHandling`.
public protocol ILMessageFilterCapabilitiesQueryHandling: NSObjectProtocol {
    func handle(
        _ capabilitiesQueryRequest: ILMessageFilterCapabilitiesQueryRequest,
        context: ILMessageFilterExtensionContext
    ) async -> ILMessageFilterCapabilitiesQueryResponse
}
