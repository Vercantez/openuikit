import Foundation
@_spi(OpenUIKitHost) import ThreadNetwork

private func thExpect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

private func thExpectUnavailable(_ error: (any Error)?) {
    let typed = error as? ThreadNetworkError
    thExpect(typed == ThreadNetworkHostControl.linuxUnavailableError, "expected unavailable")
}

func testTHClientType() {
    let client = THClient()
    thExpect(type(of: client) == THClient.self, "THClient metatype")
    let object: NSObject = client
    thExpect(object === client, "THClient is an NSObject")
    let other = THClient()
    thExpect(client != other, "distinct THClient instances are not equal")
}

func testTHClientInit() {
    let client = THClient()
    thExpect(client.isKind(of: THClient.self), "init() constructs THClient")
    let asyncPreferred: () async -> Bool = client.isPreferredAvailable
    _ = asyncPreferred
}

func testTHClientCheckPreferredNetwork() {
    let client = THClient()
    let dataset = Data([0x00, 0x03, 0x00, 0x00, 0x12])
    var calls = 0
    var available = true
    client.checkPreferredNetwork(forActiveOperationalDataset: dataset) { value in
        calls += 1
        available = value
    }
    thExpect(calls == 1, "completion runs inline")
    thExpect(available == false, "Linux has no preferred Thread network")

    var emptyCalls = 0
    var emptyAvailable = true
    client.checkPreferredNetwork(forActiveOperationalDataset: Data()) { value in
        emptyCalls += 1
        emptyAvailable = value
    }
    thExpect(emptyCalls == 1, "empty dataset still completes inline")
    thExpect(emptyAvailable == false, "empty dataset is not preferred")
}

func testTHClientIsPreferredAvailable() {
    let client = THClient()
    let asyncMethod: () async -> Bool = client.isPreferredAvailable
    _ = asyncMethod
    thExpect(
        ThreadNetworkHostControl.isPreferredAvailableSync(client) == false,
        "sync twin is false"
    )
    var calls = 0
    var available = true
    client.isPreferredNetworkAvailable { value in
        calls += 1
        available = value
    }
    thExpect(calls == 1, "completion runs inline")
    thExpect(available == false, "preferred network is not available")
}

func testTHClientAllCredentials() {
    let client = THClient()
    let asyncMethod: () async throws -> Set<THCredentials> = client.allCredentials
    _ = asyncMethod
    do {
        _ = try ThreadNetworkHostControl.allCredentialsSync(client)
        preconditionFailure("Linux must not invent stored credentials")
    } catch let error as ThreadNetworkError {
        thExpect(error == .unavailable, "allCredentials sync throws unavailable")
    } catch {
        preconditionFailure("expected ThreadNetworkError.unavailable")
    }
    var calls = 0
    var credentials: Set<THCredentials>? = Set()
    var error: (any Error)?
    client.retrieveAllCredentials { set, err in
        calls += 1
        credentials = set
        error = err
    }
    thExpect(calls == 1, "completion runs inline")
    thExpect(credentials == nil, "nil set on failure, not empty success")
    thExpectUnavailable(error)
}

func testTHClientAllActiveCredentials() {
    let client = THClient()
    let asyncMethod: () async throws -> Set<THCredentials> = client.allActiveCredentials
    _ = asyncMethod
    do {
        _ = try ThreadNetworkHostControl.allActiveCredentialsSync(client)
        preconditionFailure("Linux must not invent active credentials")
    } catch let error as ThreadNetworkError {
        thExpect(error == .unavailable, "allActiveCredentials sync throws unavailable")
    } catch {
        preconditionFailure("expected ThreadNetworkError.unavailable")
    }
    var calls = 0
    var credentials: Set<THCredentials>? = Set()
    var error: (any Error)?
    client.retrieveAllActiveCredentials { set, err in
        calls += 1
        credentials = set
        error = err
    }
    thExpect(calls == 1, "completion runs inline")
    thExpect(credentials == nil, "nil set on failure")
    thExpectUnavailable(error)
}

func testTHClientPreferredCredentials() {
    let client = THClient()
    let asyncMethod: () async throws -> THCredentials = client.preferredCredentials
    _ = asyncMethod
    do {
        _ = try ThreadNetworkHostControl.preferredCredentialsSync(client)
        preconditionFailure("Linux must not invent preferred credentials")
    } catch let error as ThreadNetworkError {
        thExpect(error == .unavailable, "preferredCredentials sync throws unavailable")
    } catch {
        preconditionFailure("expected ThreadNetworkError.unavailable")
    }
    var calls = 0
    var credentials: THCredentials? = THCredentials.hostCredentials()
    var error: (any Error)?
    client.retrievePreferredCredentials { value, err in
        calls += 1
        credentials = value
        error = err
    }
    thExpect(calls == 1, "completion runs inline")
    thExpect(credentials == nil, "nil credentials on failure")
    thExpectUnavailable(error)
}

func testTHClientCredentialsForBorderAgentID() {
    let client = THClient()
    let agent = Data([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08])
    let asyncMethod: (Data) async throws -> THCredentials = client.credentials(forBorderAgentID:)
    _ = asyncMethod
    do {
        _ = try ThreadNetworkHostControl.credentialsSync(
            forBorderAgentID: agent,
            client: client
        )
        preconditionFailure("Linux must not invent border-agent credentials")
    } catch let error as ThreadNetworkError {
        thExpect(error == .unavailable, "credentials(forBorderAgentID:) throws unavailable")
    } catch {
        preconditionFailure("expected ThreadNetworkError.unavailable")
    }
    var calls = 0
    var credentials: THCredentials? = THCredentials.hostCredentials()
    var error: (any Error)?
    client.retrieveCredentials(forBorderAgent: agent) { value, err in
        calls += 1
        credentials = value
        error = err
    }
    thExpect(calls == 1, "completion runs inline")
    thExpect(credentials == nil, "nil credentials on failure")
    thExpectUnavailable(error)
}

func testTHClientCredentialsForExtendedPANID() {
    let client = THClient()
    let pan = Data([0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88])
    let asyncMethod: (Data) async throws -> THCredentials = client.credentials(forExtendedPANID:)
    _ = asyncMethod
    do {
        _ = try ThreadNetworkHostControl.credentialsSync(
            forExtendedPANID: pan,
            client: client
        )
        preconditionFailure("Linux must not invent extended-PAN credentials")
    } catch let error as ThreadNetworkError {
        thExpect(error == .unavailable, "credentials(forExtendedPANID:) throws unavailable")
    } catch {
        preconditionFailure("expected ThreadNetworkError.unavailable")
    }
    var calls = 0
    var credentials: THCredentials? = THCredentials.hostCredentials()
    var error: (any Error)?
    client.retrieveCredentials(forExtendedPANID: pan) { value, err in
        calls += 1
        credentials = value
        error = err
    }
    thExpect(calls == 1, "completion runs inline")
    thExpect(credentials == nil, "nil credentials on failure")
    thExpectUnavailable(error)
}

func testTHClientStoreCredentials() {
    let client = THClient()
    let agent = Data([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08])
    let dataset = Data([0x00, 0x03, 0x00, 0x00, 0x12])
    let asyncMethod: (Data, Data) async throws -> Void =
        client.storeCredentials(forBorderAgent:activeOperationalDataSet:)
    _ = asyncMethod
    do {
        try ThreadNetworkHostControl.storeCredentialsSync(
            forBorderAgent: agent,
            activeOperationalDataSet: dataset,
            client: client
        )
        preconditionFailure("Linux must not invent a successful store")
    } catch let error as ThreadNetworkError {
        thExpect(error == .unavailable, "storeCredentials throws unavailable")
    } catch {
        preconditionFailure("expected ThreadNetworkError.unavailable")
    }
    var calls = 0
    var error: (any Error)?
    client.storeCredentials(
        forBorderAgent: agent,
        activeOperationalDataSet: dataset
    ) { err in
        calls += 1
        error = err
    }
    thExpect(calls == 1, "completion runs inline")
    thExpectUnavailable(error)
}

func testTHClientDeleteCredentials() {
    let client = THClient()
    let agent = Data([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08])
    let asyncMethod: (Data) async throws -> Void = client.deleteCredentials(forBorderAgent:)
    _ = asyncMethod
    do {
        try ThreadNetworkHostControl.deleteCredentialsSync(
            forBorderAgent: agent,
            client: client
        )
        preconditionFailure("Linux must not invent a successful delete")
    } catch let error as ThreadNetworkError {
        thExpect(error == .unavailable, "deleteCredentials throws unavailable")
    } catch {
        preconditionFailure("expected ThreadNetworkError.unavailable")
    }
    var calls = 0
    var error: (any Error)?
    client.deleteCredentials(forBorderAgent: agent) { err in
        calls += 1
        error = err
    }
    thExpect(calls == 1, "completion runs inline")
    thExpectUnavailable(error)
}
