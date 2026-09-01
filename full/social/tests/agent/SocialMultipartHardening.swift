@_spi(OpenUIKitHost) import Social
import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

func require(_ condition: Bool, _ message: String) {
    if !condition {
        fputs("SOCIAL_MULTIPART_HARDENING_FAIL: \(message)\n", stderr)
        exit(1)
    }
}

func multipartBoundary(from request: URLRequest) -> String {
    let header = request.value(forHTTPHeaderField: "Content-Type") ?? ""
    let marker = "boundary="
    guard let range = header.range(of: marker) else { return "" }
    return String(header[range.upperBound...])
}

func bodyString(_ request: URLRequest) -> String {
    String(data: request.httpBody ?? Data(), encoding: .utf8) ?? ""
}

let url = URL(string: "https://api.example.com/1.1/statuses/update.json")!

do {
    let injected = SLRequest(
        forServiceType: SLServiceTypeTwitter,
        requestMethod: .POST,
        url: url,
        parameters: [
            "status": "hello",
            "ok": "keep",
            "evil\nname": "lf",
            "cr\rname": "cr",
            "quoted\"name": "quote",
        ]
    )!
    injected.addMultipartData(
        Data("payload".utf8),
        withName: "media",
        type: "text/plain",
        filename: "ok.txt"
    )
    let prepared = injected.preparedURLRequest()!
    let body = bodyString(prepared)
    require(body.contains("name=\"status\""), "safe status field emitted")
    require(body.contains("name=\"ok\""), "safe ok field emitted")
    require(body.contains("name=\"media\""), "part field emitted")
    require(!body.contains("evil"), "LF parameter name rejected")
    require(!body.contains("cr\rname"), "CR parameter name rejected")
    require(!body.contains("quoted\"name"), "quote parameter name rejected")
    require(!body.contains("name=\"evil"), "LF name not inserted into disposition")
    require(!body.contains("name=\"quoted"), "quote name not inserted into disposition")
}

do {
    SLRequest.hostResetMultipartBoundaryCandidates()
    SLRequest.hostMultipartBoundaryCandidates = [
        "BoundaryCOLLIDE0",
        "BoundaryCOLLIDE1",
        "BoundarySAFE999",
    ]
    let colliding = SLRequest(
        forServiceType: SLServiceTypeTwitter,
        requestMethod: .POST,
        url: url,
        parameters: ["status": "BoundaryCOLLIDE0"]
    )!
    colliding.addMultipartData(
        Data("BoundaryCOLLIDE1".utf8),
        withName: "media",
        type: "text/plain",
        filename: "draft.bin"
    )
    let prepared = colliding.preparedURLRequest()!
    let boundary = multipartBoundary(from: prepared)
    require(boundary == "BoundarySAFE999", "retry selects first collision-free candidate")
    let body = bodyString(prepared)
    require(body.contains("--BoundarySAFE999"), "body uses tested boundary")
    require(!body.contains("--BoundaryCOLLIDE0\r\n"), "colliding candidate 0 not used")
    require(!body.contains("--BoundaryCOLLIDE1\r\n"), "colliding candidate 1 not used")
    SLRequest.hostResetMultipartBoundaryCandidates()
}

do {
    SLRequest.hostMultipartBoundaryCandidates = ["BoundaryONLYCOLLIDE"]
    let exhausted = SLRequest(
        forServiceType: SLServiceTypeTwitter,
        requestMethod: .POST,
        url: url,
        parameters: ["status": "BoundaryONLYCOLLIDE"]
    )!
    exhausted.addMultipartData(
        Data("x".utf8),
        withName: "media",
        type: "text/plain",
        filename: "ok.txt"
    )
    let prepared = exhausted.preparedURLRequest()!
    let boundary = multipartBoundary(from: prepared)
    require(!boundary.isEmpty, "generator still returns a boundary")
    require(boundary != "BoundaryONLYCOLLIDE", "colliding injected candidate is not returned")
    require(
        (prepared.value(forHTTPHeaderField: "Content-Type") ?? "").contains("boundary=\(boundary)"),
        "returned boundary was collision-tested"
    )
    let haystack = "statusBoundaryONLYCOLLIDEmediaok.txttext/plainx"
    require(!haystack.contains(boundary), "UUID continuation is collision-tested")
    SLRequest.hostResetMultipartBoundaryCandidates()
}

print("SOCIAL_MULTIPART_HARDENING_OK")
