import Foundation
import FoundationNetworking
import IdentityLookup

func testMessageFilterQueryRequestFields() {
    let request = ILMessageFilterQueryRequest(
        sender: "+15555550333",
        messageBody: "Win a prize",
        receiverISOCountryCode: "US"
    )
    precondition(request.sender == "+15555550333")
    precondition(request.messageBody == "Win a prize")
    precondition(request.receiverISOCountryCode == "US")
}

func testMessageFilterQueryRequestSecureCodingRoundTrip() {
    let original = ILMessageFilterQueryRequest(
        sender: "ALERT",
        messageBody: "body",
        receiverISOCountryCode: "GB"
    )
    let data = try! NSKeyedArchiver.archivedData(
        withRootObject: original,
        requiringSecureCoding: true
    )
    let decoded = try! NSKeyedUnarchiver.unarchivedObject(
        ofClass: ILMessageFilterQueryRequest.self,
        from: data
    )
    precondition(decoded?.sender == "ALERT")
    precondition(decoded?.messageBody == "body")
    precondition(decoded?.receiverISOCountryCode == "GB")
}

func testMessageFilterQueryResponseDefaults() {
    let response = ILMessageFilterQueryResponse()
    precondition(response.action == .none)
    precondition(response.subAction == .none)
    response.action = .junk
    response.subAction = .promotionalOffers
    precondition(response.action == .junk)
    precondition(response.subAction == .promotionalOffers)
}

func testMessageFilterQueryResponseSecureCodingRoundTrip() {
    let original = ILMessageFilterQueryResponse()
    original.action = .transaction
    original.subAction = .transactionalFinance
    let data = try! NSKeyedArchiver.archivedData(
        withRootObject: original,
        requiringSecureCoding: true
    )
    let decoded = try! NSKeyedUnarchiver.unarchivedObject(
        ofClass: ILMessageFilterQueryResponse.self,
        from: data
    )
    precondition(decoded?.action == .transaction)
    precondition(decoded?.subAction == .transactionalFinance)
}

func testCapabilitiesQueryResponseSubActions() {
    let response = ILMessageFilterCapabilitiesQueryResponse()
    precondition(response.promotionalSubActions.isEmpty)
    precondition(response.transactionalSubActions.isEmpty)
    response.promotionalSubActions = [.promotionalCoupons, .promotionalOffers]
    response.transactionalSubActions = [.transactionalOrders, .transactionalHealth]
    precondition(response.promotionalSubActions == [.promotionalCoupons, .promotionalOffers])
    precondition(response.transactionalSubActions == [.transactionalOrders, .transactionalHealth])
}

func testCapabilitiesQueryResponseSecureCodingRoundTrip() {
    let original = ILMessageFilterCapabilitiesQueryResponse()
    original.promotionalSubActions = [.promotionalOthers]
    original.transactionalSubActions = [.transactionalCarrier]
    let data = try! NSKeyedArchiver.archivedData(
        withRootObject: original,
        requiringSecureCoding: true
    )
    let decoded = try! NSKeyedUnarchiver.unarchivedObject(
        ofClass: ILMessageFilterCapabilitiesQueryResponse.self,
        from: data
    )
    precondition(decoded?.promotionalSubActions == [.promotionalOthers])
    precondition(decoded?.transactionalSubActions == [.transactionalCarrier])
}

func testCapabilitiesQueryRequestCoding() {
    let original = ILMessageFilterCapabilitiesQueryRequest()
    let data = try! NSKeyedArchiver.archivedData(
        withRootObject: original,
        requiringSecureCoding: true
    )
    let decoded = try! NSKeyedUnarchiver.unarchivedObject(
        ofClass: ILMessageFilterCapabilitiesQueryRequest.self,
        from: data
    )
    precondition(decoded != nil)
}

func testNetworkResponseStoresURLAndData() {
    let url = URL(string: "https://example.invalid/filter")!
    let payload = Data("payload".utf8)
    let http = HTTPURLResponse(
        url: url,
        statusCode: 204,
        httpVersion: "HTTP/1.1",
        headerFields: nil
    )!
    let response = ILNetworkResponse(urlResponse: http, data: payload)
    precondition(response.data == payload)
    precondition(response.urlResponse.statusCode == 204)
    precondition(response.urlResponse.url == url)
}

func testNetworkResponseSecureCodingRoundTrip() {
    let url = URL(string: "https://example.invalid/filter-roundtrip")!
    let payload = Data([0x01, 0x02, 0x03])
    let http = HTTPURLResponse(
        url: url,
        statusCode: 201,
        httpVersion: "HTTP/1.1",
        headerFields: nil
    )!
    let original = ILNetworkResponse(urlResponse: http, data: payload)
    let data = try! NSKeyedArchiver.archivedData(
        withRootObject: original,
        requiringSecureCoding: true
    )
    let decoded = try! NSKeyedUnarchiver.unarchivedObject(
        ofClass: ILNetworkResponse.self,
        from: data
    )
    precondition(decoded?.data == payload)
    precondition(decoded?.urlResponse.statusCode == 201)
    precondition(decoded?.urlResponse.url == url)
}

func testDeferQueryRequestToNetworkFailsClosed() {
    let context = ILMessageFilterExtensionContext()
    var receivedResponse: ILNetworkResponse? = ILNetworkResponse(
        urlResponse: HTTPURLResponse(
            url: URL(string: "https://example.invalid")!,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!,
        data: Data()
    )
    var receivedError: (any Error)?
    context.deferQueryRequestToNetwork { response, error in
        receivedResponse = response
        receivedError = error
    }
    precondition(receivedResponse == nil)
    let filterError = receivedError as? ILMessageFilterError
    precondition(filterError?.code == .invalidNetworkURL)
}

func testMessageFilterExtensionConstructs() {
    let ext = ILMessageFilterExtension()
    precondition(type(of: ext) == ILMessageFilterExtension.self)
}

func testMessageFilterQueryHandlingConformance() {
    final class Handler: NSObject, ILMessageFilterQueryHandling {
        func handle(
            _ queryRequest: ILMessageFilterQueryRequest,
            context: ILMessageFilterExtensionContext
        ) async -> ILMessageFilterQueryResponse {
            _ = queryRequest
            _ = context
            let response = ILMessageFilterQueryResponse()
            response.action = .none
            return response
        }
    }
    let handler: any ILMessageFilterQueryHandling = Handler()
    precondition(handler is NSObject)
}

func testMessageFilterCapabilitiesQueryHandlingConformance() {
    final class Handler: NSObject, ILMessageFilterCapabilitiesQueryHandling {
        func handle(
            _ capabilitiesQueryRequest: ILMessageFilterCapabilitiesQueryRequest,
            context: ILMessageFilterExtensionContext
        ) async -> ILMessageFilterCapabilitiesQueryResponse {
            _ = capabilitiesQueryRequest
            _ = context
            return ILMessageFilterCapabilitiesQueryResponse()
        }
    }
    let handler: any ILMessageFilterCapabilitiesQueryHandling = Handler()
    precondition(handler is NSObject)
}
