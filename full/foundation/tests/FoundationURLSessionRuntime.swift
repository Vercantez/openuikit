import Foundation

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() { fatalError("FoundationURLSessionRuntime: \(message)") }
}

private final class RetainedDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {}

private final class ProbeProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var startCount = 0

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.scheme == "probe"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.startCount += 1
        let response = HTTPURLResponse(
            url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "text/plain"]
        )!
        if request.url?.path == "/redirect" {
            client?.urlProtocol(
                self,
                wasRedirectedTo: URLRequest(url: URL(string: "probe://fixture/final")!),
                redirectResponse: response
            )
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data("protocol-ok".utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@main
private enum FoundationURLSessionRuntime {
    static func main() async throws {
        guard CommandLine.arguments.count >= 2,
              let base = URL(string: CommandLine.arguments[1]) else {
            fatalError("FoundationURLSessionRuntime: expected loopback base URL")
        }

        let defaultConfiguration = URLSessionConfiguration.default
        require(defaultConfiguration.requestCachePolicy == .useProtocolCachePolicy, "default cache policy")
        require(defaultConfiguration.timeoutIntervalForRequest == 60, "default request timeout")
        require(defaultConfiguration.timeoutIntervalForResource == 604_800, "default resource timeout")
        require(defaultConfiguration.httpCookieStorage === HTTPCookieStorage.shared, "default cookie storage")
        require(defaultConfiguration.urlCache === URLCache.shared, "default cache")
        require(defaultConfiguration.waitsForConnectivity == false, "waitsForConnectivity")
        require(defaultConfiguration.httpMaximumConnectionsPerHost == 6, "httpMaximumConnectionsPerHost")
        require(
            defaultConfiguration.httpCookieAcceptPolicy == .onlyFromMainDocumentDomain,
            "httpCookieAcceptPolicy"
        )

        let ephemeralOne = URLSessionConfiguration.ephemeral
        let ephemeralTwo = URLSessionConfiguration.ephemeral
        require(ephemeralOne.httpCookieStorage !== ephemeralTwo.httpCookieStorage, "ephemeral cookie isolation")
        require(ephemeralOne.urlCache !== ephemeralTwo.urlCache, "ephemeral cache isolation")
        require(ephemeralOne.urlCache?.memoryCapacity == 512_000, "ephemeral memory cache")
        require(ephemeralOne.urlCache?.diskCapacity == 0, "ephemeral disk cache")

        var delegate: RetainedDelegate? = RetainedDelegate()
        weak var weakDelegate = delegate
        let retainingSession = URLSession(
            configuration: .ephemeral, delegate: delegate, delegateQueue: nil
        )
        delegate = nil
        require(weakDelegate != nil, "session did not retain delegate")
        require(retainingSession.delegate === weakDelegate, "session delegate identity")

        let storage = HTTPCookieStorage()
        let hostOnly = HTTPCookie(properties: [
            .domain: "example.test", .path: "/secure", .name: "host", .value: "one",
            .expires: Date().addingTimeInterval(60),
        ])!
        let domain = HTTPCookie(properties: [
            .domain: ".example.test", .path: "/", .name: "domain", .value: "two",
        ])!
        let expired = HTTPCookie(properties: [
            .domain: "example.test", .path: "/", .name: "expired", .value: "gone",
            .expires: Date().addingTimeInterval(-1),
        ])!
        storage.setCookie(hostOnly)
        storage.setCookie(domain)
        storage.setCookie(expired)
        require(storage.cookies?.contains(where: { $0.name == "expired" }) == false, "expired cookie retained")
        require(storage.cookies(for: URL(string: "https://example.test/secure/child")!)?.count == 2, "host/path match")
        let subdomain = storage.cookies(for: URL(string: "https://sub.example.test/secure/child")!) ?? []
        require(subdomain.contains(where: { $0.name == "domain" }), "domain cookie did not match subdomain")
        require(!subdomain.contains(where: { $0.name == "host" }), "host-only cookie leaked to subdomain")
        require(storage.cookies(for: URL(string: "https://example.test/other")!)?.contains(where: { $0.name == "host" }) == false, "cookie path leaked")
        let replacementStorage = HTTPCookieStorage()
        let replacementURL = URL(string: "https://replace.test/")!
        let oldCookie = HTTPCookie(properties: [
            .domain: "replace.test", .path: "/", .name: "value", .value: "old",
        ])!
        let deletionCookie = HTTPCookie(properties: [
            .domain: "replace.test", .path: "/", .name: "value", .value: "deleted",
            .expires: Date().addingTimeInterval(-1),
        ])!
        replacementStorage.setCookie(oldCookie)
        replacementStorage.setCookies([deletionCookie], for: replacementURL, mainDocumentURL: replacementURL)
        require(replacementStorage.cookies(for: replacementURL)?.isEmpty == true, "expired replacement did not delete old cookie")

        let streamData = Data("stream-body".utf8)
        let stream = InputStream(data: streamData)
        stream.open()
        var captured = Data()
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 4)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let count = stream.read(buffer, maxLength: 4)
            require(count >= 0, "input stream read failed")
            if count == 0 { break }
            captured.append(buffer, count: count)
        }
        stream.close()
        require(captured == streamData, "bounded input stream data")

        let cache = URLCache(memoryCapacity: 128, diskCapacity: 0)
        let cacheRequest = URLRequest(url: URL(string: "https://cache.test/value")!)
        let cacheResponse = URLResponse(
            url: cacheRequest.url!, mimeType: nil, expectedContentLength: 1,
            textEncodingName: nil
        )
        cache.storeCachedResponse(
            CachedURLResponse(response: cacheResponse, data: Data([1]), storagePolicy: .notAllowed),
            for: cacheRequest
        )
        require(cache.cachedResponse(for: cacheRequest) == nil, "notAllowed response cached")

        let protocolConfiguration = URLSessionConfiguration.ephemeral
        protocolConfiguration.protocolClasses = [ProbeProtocol.self]
        let protocolSession = URLSession(configuration: protocolConfiguration)
        ProbeProtocol.startCount = 0
        let (protocolData, protocolResponse) = try await protocolSession.data(
            from: URL(string: "probe://fixture/value")!
        )
        require(String(data: protocolData, encoding: .utf8) == "protocol-ok", "URLProtocol data")
        require((protocolResponse as? HTTPURLResponse)?.statusCode == 200, "URLProtocol response")
        require(ProbeProtocol.startCount == 1, "URLProtocol interception count")

        let cachedRequest = URLRequest(url: URL(string: "probe://fixture/cached")!)
        let cachedResponse = HTTPURLResponse(
            url: cachedRequest.url!, statusCode: 200, httpVersion: nil,
            headerFields: nil
        )!
        protocolConfiguration.urlCache!.storeCachedResponse(
            CachedURLResponse(response: cachedResponse, data: Data("cached-ok".utf8)),
            for: cachedRequest
        )
        let cachedSession = URLSession(configuration: protocolConfiguration)
        let startsBeforeCache = ProbeProtocol.startCount
        let (cachedData, _) = try await cachedSession.data(for: cachedRequest)
        require(String(data: cachedData, encoding: .utf8) == "cached-ok", "useProtocolCachePolicy miss")
        require(ProbeProtocol.startCount == startsBeforeCache, "cached request reached URLProtocol")

        do {
            _ = try await protocolSession.data(from: URL(string: "probe://fixture/redirect")!)
            fatalError("FoundationURLSessionRuntime: URLProtocol redirect was silently accepted")
        } catch let error as URLError {
            require(error.code == .unsupportedURL, "URLProtocol redirect refusal error")
        }

        let networkConfiguration = URLSessionConfiguration.ephemeral
        let networkSession = URLSession(configuration: networkConfiguration)
        var redirectRequest = URLRequest(url: base.appendingPathComponent("redirect"))
        redirectRequest.httpMethod = "POST"
        redirectRequest.httpBody = Data("post-body".utf8)
        let (redirectData, redirectResponse) = try await networkSession.data(for: redirectRequest)
        let redirectHTTP = redirectResponse as! HTTPURLResponse
        require(redirectHTTP.statusCode == 200, "redirect final status")
        require(redirectHTTP.url?.path == "/final", "redirect final URL")
        require(String(data: redirectData, encoding: .utf8) == "redirect-cookie-ok", "Set-Cookie before POST-to-GET redirect")

        let (errorData, errorResponse) = try await networkSession.data(
            from: base.appendingPathComponent("status500")
        )
        require((errorResponse as? HTTPURLResponse)?.statusCode == 500, "500 status response")
        require(String(data: errorData, encoding: .utf8) == "server-error", "500 response body")

        let configurationTimeout = URLSessionConfiguration.ephemeral
        configurationTimeout.timeoutIntervalForRequest = 0.2
        configurationTimeout.timeoutIntervalForResource = 5
        do {
            _ = try await URLSession(configuration: configurationTimeout).data(
                from: base.appendingPathComponent("idle")
            )
            fatalError("FoundationURLSessionRuntime: configuration timeout was ignored")
        } catch let error as URLError {
            require(error.code == .timedOut, "configuration timeout mapping")
        }
        let explicitTimeoutConfiguration = URLSessionConfiguration.ephemeral
        explicitTimeoutConfiguration.timeoutIntervalForRequest = 5
        explicitTimeoutConfiguration.timeoutIntervalForResource = 5
        var timeoutRequest = URLRequest(url: base.appendingPathComponent("idle"))
        timeoutRequest.timeoutInterval = 0.2
        do {
            _ = try await URLSession(configuration: explicitTimeoutConfiguration).data(for: timeoutRequest)
            fatalError("FoundationURLSessionRuntime: explicit request timeout was ignored")
        } catch let error as URLError {
            require(error.code == .timedOut, "request timeout mapping")
        }

        var streamRequest = URLRequest(url: base.appendingPathComponent("echo"))
        streamRequest.httpMethod = "POST"
        streamRequest.httpBodyStream = InputStream(data: Data("stream-upload".utf8))
        let (echoData, _) = try await networkSession.data(for: streamRequest)
        require(String(data: echoData, encoding: .utf8) == "stream-upload", "stream upload")

        let started = Date()
        let results = try await withThrowingTaskGroup(of: Data.self) { group in
            for index in 1 ... 3 {
                group.addTask {
                    try await networkSession.data(
                        from: base.appendingPathComponent("delay/\(index)")
                    ).0
                }
            }
            var values: [Data] = []
            for try await value in group { values.append(value) }
            return values
        }
        require(results.count == 3, "concurrent result count")
        require(results.allSatisfy { String(data: $0, encoding: .utf8) == "delay-ok" }, "concurrent response body")
        require(Date().timeIntervalSince(started) < 0.75, "requests did not execute concurrently")

        var httpsMarker = "not-requested"
        if CommandLine.arguments.count >= 3 {
            guard let httpsURL = URL(string: CommandLine.arguments[2]),
                  httpsURL.scheme?.lowercased() == "https" else {
                fatalError("FoundationURLSessionRuntime: invalid HTTPS checkpoint URL")
            }
            let (httpsData, httpsResponse) = try await networkSession.data(from: httpsURL)
            let httpsHTTP = httpsResponse as! HTTPURLResponse
            require((200 ... 399).contains(httpsHTTP.statusCode), "HTTPS checkpoint status")
            require(!httpsData.isEmpty, "HTTPS checkpoint body")
            require(httpsHTTP.url?.scheme?.lowercased() == "https", "HTTPS effective URL")
            httpsMarker = "system-ca-verified"
        }

        let components = URLComponents(string: "https://user:pass@example.com:8080/path?q=1&b=hello%20world#frag")
        require(components?.scheme == "https", "URLComponents scheme")
        require(components?.host == "example.com", "URLComponents host")
        require(components?.port == 8080, "URLComponents port")
        require(components?.path == "/path", "URLComponents path")
        require(components?.queryItems?.count == 2, "URLComponents queryItems")
        require(components?.queryItems?.last?.value == "hello world", "URLComponents query decode")
        var built = URLComponents()
        built.scheme = "http"
        built.host = "example.com"
        built.path = "/"
        built.queryItems = [URLQueryItem(name: "k", value: "a&b")]
        require(built.percentEncodedQuery == "k=a%26b", "URLQueryItem percent-encoding")

        let dataTask = protocolSession.dataTask(with: URL(string: "probe://fixture/value")!)
        require(dataTask.state == .suspended, "new dataTask starts suspended")
        require(type(of: dataTask) == URLSessionDataTask.self, "dataTask metatype")
        let (taskData, taskResponse, taskError) = await withCheckedContinuation {
            (continuation: CheckedContinuation<(Data?, URLResponse?, (any Error)?), Never>) in
            let task = protocolSession.dataTask(with: URL(string: "probe://fixture/value")!) { data, response, error in
                continuation.resume(returning: (data, response, error))
            }
            require(task.state == .suspended, "completion dataTask starts suspended")
            task.resume()
        }
        require(taskError == nil, "completion handler error")
        require(String(data: taskData ?? Data(), encoding: .utf8) == "protocol-ok", "completion handler data")
        require((taskResponse as? HTTPURLResponse)?.statusCode == 200, "completion handler response")

        let upload = networkSession.uploadTask(with: URLRequest(url: base.appendingPathComponent("echo")), from: Data("x".utf8))
        require(type(of: upload) == URLSessionUploadTask.self, "uploadTask metatype")
        require(upload.state == .suspended, "uploadTask starts suspended")

        let download = protocolSession.downloadTask(with: URL(string: "probe://fixture/value")!)
        require(type(of: download) == URLSessionDownloadTask.self, "downloadTask metatype")

        let credential = URLCredential(user: "u", password: "p", persistence: .forSession)
        require(credential.user == "u" && credential.password == "p", "URLCredential")
        let space = URLProtectionSpace(
            host: "example.com", port: 80, protocol: "http", realm: nil, authenticationMethod: nil
        )
        require(space.host == "example.com", "URLProtectionSpace")
        _ = URLAuthenticationChallenge(
            protectionSpace: space, proposedCredential: credential,
            previousFailureCount: 0, failureResponse: nil, error: nil
        )

        let background = URLSession(
            configuration: .background(withIdentifier: "openuikit.foundation.urlsession")
        )
        require(background.configuration.identifier == "openuikit.foundation.urlsession", "background identifier")
        do {
            _ = try await background.data(from: URL(string: "probe://fixture/value")!)
            fatalError("FoundationURLSessionRuntime: background session did not fail closed")
        } catch let error as URLError {
            require(error.code == .cannotLoadFromNetwork, "background fail-closed")
        }

        let filenameResponse = HTTPURLResponse(
            url: URL(string: "http://example.com/a/b.txt")!,
            statusCode: 200, httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "text/html"]
        )!
        require(filenameResponse.suggestedFilename == "b.txt.html", "suggestedFilename MIME extension")
        require(HTTPURLResponse.localizedString(forStatusCode: 418) == "client error", "localizedString 4xx")

        final class RegisteredProbe: URLProtocol, @unchecked Sendable {
            nonisolated(unsafe) static var started = false
            override class func canInit(with request: URLRequest) -> Bool {
                request.url?.scheme == "regprobe"
            }
            override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
            override func startLoading() {
                Self.started = true
                let response = HTTPURLResponse(
                    url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1",
                    headerFields: ["Content-Type": "text/plain"]
                )!
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: Data("registered-ok".utf8))
                client?.urlProtocolDidFinishLoading(self)
            }
            override func stopLoading() {}
        }
        require(URLProtocol.registerClass(RegisteredProbe.self), "URLProtocol.registerClass")
        let registeredSession = URLSession(configuration: .ephemeral)
        let (registeredData, _) = try await registeredSession.data(
            from: URL(string: "regprobe://fixture/value")!
        )
        require(String(data: registeredData, encoding: .utf8) == "registered-ok", "registerClass intercept")
        require(RegisteredProbe.started, "registerClass startLoading")
        URLProtocol.unregisterClass(RegisteredProbe.self)

        print("FOUNDATION_URLSESSION_MACHO_OK delegate=retained configuration=isolated cookies=host-domain-path-expiry-delete redirect=set-cookie-post-get status500=response final-url=preserved concurrency=parallel input-stream=bounded urlprotocol=intercepted-cache-hit-redirect-refused timeouts=configuration-request https=\(httpsMarker) components=rfc3986 tasks=suspended-completion-upload-download background=fail-closed registerClass=global")
    }
}
