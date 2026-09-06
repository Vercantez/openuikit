import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MusicKit

func testMusicDataError() {
    let url = URL(string: "https://api.music.apple.com/v1/catalog/us/search")!
    let http = HTTPURLResponse(
        url: url,
        statusCode: 401,
        httpVersion: "HTTP/1.1",
        headerFields: ["Content-Type": "application/json"]
    )!
    let original = MusicDataResponse(data: Data(#"{"errors":[]}"#.utf8), urlResponse: http)
    let error = MusicDataRequest.Error(
        id: "err.auth",
        title: "Unauthorized",
        detailText: "Missing developer token",
        code: 40101,
        status: 401,
        source: .parameter("term"),
        originalResponse: original
    )
    precondition(error.id == "err.auth")
    precondition(error.title == "Unauthorized")
    precondition(error.detailText == "Missing developer token")
    precondition(error.code == 40101)
    precondition(error.status == 401)
    precondition(error.description == "Unauthorized")
    if case .parameter(let name) = error.source {
        precondition(name == "term")
    } else {
        precondition(false)
    }
    precondition(error.originalResponse.statusCodeMatches(401))
}

func testMusicDataResponse() {
    let url = URL(string: "https://api.music.apple.com/v1/me/library")!
    let http = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
    let payload = Data(#"{"data":[]}"#.utf8)
    let response = MusicDataResponse(data: payload, urlResponse: http)
    precondition(response.data == payload)
    precondition(response.urlResponse.statusCode == 200)
    precondition(response.description.contains("200"))
    precondition(response.debugDescription == response.description)
    precondition(response == response)
    var hasher = Hasher()
    response.hash(into: &hasher)
    _ = response.hashValue
}


private extension MusicDataResponse {
    func statusCodeMatches(_ code: Int) -> Bool {
        urlResponse.statusCode == code
    }
}
