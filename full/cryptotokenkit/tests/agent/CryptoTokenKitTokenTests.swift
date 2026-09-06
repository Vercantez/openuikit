import Foundation
import CryptoTokenKit

private func tkMust(_ condition: Bool, _ message: String) {
    if !condition {
        preconditionFailure(message)
    }
}

func testTKTokenInitAndConfiguration() {
    let driver = TKTokenDriver()
    let token = TKToken(tokenDriver: driver, instanceID: "inst-a")
    tkMust(token.tokenDriver === driver, "driver")
    tkMust(token.configuration.instanceID == "inst-a", "instance")
    tkMust(token.delegate == nil, "delegate")
    tkMust(token.keychainContents != nil, "contents")
    token.configuration.configurationData = Data([0x01])
    tkMust(token.configuration.configurationData == Data([0x01]), "config data")
}

func testTKTokenDriverConfigurationCatalog() {
    let classID = "com.openuikit.ctk.test.\(UUID().uuidString)"
    let configuration = TKTokenDriver.Configuration(classID: classID)
    tkMust(configuration.classID == classID, "classID")
    tkMust(TKTokenDriver.Configuration.driverConfigurations[classID] === configuration, "registry")
    let added = configuration.addTokenConfiguration(for: "tok-1")
    tkMust(added.instanceID == "tok-1", "added")
    tkMust(configuration.tokenConfigurations["tok-1"] === added, "map")
    let again = configuration.addTokenConfiguration(for: "tok-1")
    tkMust(again === added, "idempotent")
    configuration.removeTokenConfiguration(for: "tok-1")
    tkMust(configuration.tokenConfigurations["tok-1"] == nil, "removed")
}

func testTKTokenConfigurationKeyLookup() {
    let configuration = TKToken.Configuration(instanceID: "cfg")
    let objectID = NSNumber(value: 42)
    let key = TKTokenKeychainKey(objectID: objectID)
    key.keyType = "RSA"
    key.keySizeInBits = 2048
    key.canSign = true
    key.canDecrypt = false
    key.canPerformKeyExchange = false
    key.isSuitableForLogin = true
    key.applicationTag = Data([0x01])
    key.publicKeyData = Data([0x02])
    key.publicKeyHash = Data([0x03])
    let certificate = TKTokenKeychainCertificate(objectID: NSNumber(value: 43), data: Data([0x30]))
    configuration.keychainItems = [key, certificate]
    let foundKey = try! configuration.key(for: objectID)
    tkMust(foundKey.canSign, "canSign")
    tkMust(foundKey.keyType == "RSA", "keyType")
    tkMust(foundKey.keySizeInBits == 2048, "bits")
    tkMust(foundKey.applicationTag == Data([0x01]), "tag")
    tkMust(foundKey.publicKeyData == Data([0x02]), "pub")
    tkMust(foundKey.publicKeyHash == Data([0x03]), "hash")
    tkMust(foundKey.isSuitableForLogin, "login")
    let foundCert = try! configuration.certificate(for: NSNumber(value: 43))
    tkMust(foundCert.data == Data([0x30]), "cert data")
    do {
        _ = try configuration.key(for: NSNumber(value: 99))
        preconditionFailure("missing key")
    } catch {
        tkMust(TKError.Code.objectNotFound ~= error, "objectNotFound")
    }
}

func testTKTokenKeychainItemProperties() {
    let objectID = "item-1" as NSString
    let item = TKTokenKeychainItem(objectID: objectID)
    tkMust((item.objectID as? NSString) == objectID, "id")
    item.label = "signing"
    item.constraints = [NSNumber(value: TKTokenOperation.signData.rawValue): "pin"]
    tkMust(item.label == "signing", "label")
    tkMust(item.constraints?.count == 1, "constraints")
}

func testTKTokenKeychainContentsFill() {
    let contents = TKTokenKeychainContents()
    tkMust(contents.items.isEmpty, "empty")
    let key = TKTokenKeychainKey(objectID: NSNumber(value: 1))
    let certificate = TKTokenKeychainCertificate(objectID: NSNumber(value: 2), data: Data([0x05]))
    contents.fill(with: [key, certificate])
    tkMust(contents.items.count == 2, "filled")
    tkMust(try! contents.key(forObjectID: NSNumber(value: 1)) === key, "key")
    tkMust(try! contents.certificate(forObjectID: NSNumber(value: 2)).data == Data([0x05]), "cert")
    do {
        _ = try contents.certificate(forObjectID: NSNumber(value: 1))
        preconditionFailure("wrong type")
    } catch {
        tkMust(TKError.Code.objectNotFound ~= error, "not cert")
    }
}

func testTKTokenSessionInit() {
    let token = TKToken(tokenDriver: TKTokenDriver(), instanceID: "s")
    let session = TKTokenSession(token: token)
    tkMust(session.token === token, "token")
    tkMust(session.delegate == nil, "delegate")
}

func testTKTokenAuthOperationFinish() {
    let operation = TKTokenAuthOperation()
    try! operation.finish()
}

func testTKTokenAuthOperationInitCoder() {
    let operation = TKTokenAuthOperation()
    let data = try! NSKeyedArchiver.archivedData(withRootObject: operation, requiringSecureCoding: true)
    let decoded = try! NSKeyedUnarchiver.unarchivedObject(ofClass: TKTokenAuthOperation.self, from: data)
    tkMust(decoded != nil, "round trip")
}

func testTKTokenPasswordAuthOperationFailClosed() {
    let operation = TKTokenPasswordAuthOperation()
    operation.password = "secret"
    tkMust(operation.password == "secret", "password")
    do {
        try operation.finish()
        preconditionFailure("password finish")
    } catch {
        tkMust(TKError.Code.notImplemented ~= error, "password")
    }
}

func testTKTokenSmartCardPINAuthOperationProperties() {
    let operation = TKTokenSmartCardPINAuthOperation()
    operation.apduTemplate = Data([0x00, 0x20])
    operation.pin = "1234"
    operation.pinByteOffset = 5
    operation.pinFormat.maxPINLength = 8
    operation.smartCard = TKSmartCard()
    tkMust(operation.apduTemplate == Data([0x00, 0x20]), "apdu")
    tkMust(operation.pin == "1234", "pin")
    tkMust(operation.pinByteOffset == 5, "offset")
    tkMust(operation.pinFormat.maxPINLength == 8, "format")
    tkMust(operation.smartCard != nil, "card")
    do {
        try operation.finish()
        preconditionFailure("pin finish")
    } catch {
        tkMust(TKError.Code.notImplemented ~= error, "pin")
    }
}

func testTKTokenWatcherEmpty() {
    let watcher = TKTokenWatcher()
    tkMust(watcher.tokenIDs.isEmpty, "ids")
    tkMust(watcher.tokenInfo(forTokenID: "x") == nil, "info")
    var inserted = false
    watcher.setInsertionHandler { _ in inserted = true }
    let watcher2 = TKTokenWatcher { _ in inserted = true }
    watcher2.addRemovalHandler({ _ in }, forTokenID: "gone")
    tkMust(inserted == false, "no hardware events")
}

func testTKTokenWatcherTokenInfo() {
    let info = TKTokenWatcher.TokenInfo(tokenID: "tok", driverName: "drv", slotName: "slot")
    tkMust(info.tokenID == "tok", "id")
    tkMust(info.driverName == "drv", "driver")
    tkMust(info.slotName == "slot", "slot")
}

func testTKSmartCardTokenAndSession() {
    let driver = TKSmartCardTokenDriver()
    let card = TKSmartCard()
    let aid = Data([0xA0, 0x00])
    let token = TKSmartCardToken(smartCard: card, aid: aid, instanceID: "sc-1", tokenDriver: driver)
    tkMust(token.aid == aid, "aid")
    let token2 = TKSmartCardToken(smartCard: card, AID: aid, instanceID: "sc-2", tokenDriver: driver)
    tkMust(token2.aid == aid, "AID")
    let session = TKSmartCardTokenSession(token: token)
    let attached = try! session.getSmartCard()
    tkMust(attached === card, "getSmartCard")
    tkMust(session.smartCard === card, "smartCard")
}

func testTKSmartCardTokenRegistrationManagerFailClosed() {
    let manager = TKSmartCardTokenRegistrationManager.default
    tkMust(manager.registeredSmartCardTokens.isEmpty, "empty")
    do {
        try manager.registerSmartCard(tokenID: "t", promptMessage: "pair")
        preconditionFailure("register")
    } catch {
        tkMust(TKError.Code.notImplemented ~= error, "register")
    }
    do {
        try manager.unregisterSmartCard(tokenID: "t")
        preconditionFailure("unregister")
    } catch {
        tkMust(TKError.Code.notImplemented ~= error, "unregister")
    }
}

func testTKTokenKeyExchangeParameters() {
    let parameters = TKTokenKeyExchangeParameters(requestedSize: 32, sharedInfo: Data([0x01]))
    tkMust(parameters.requestedSize == 32, "size")
    tkMust(parameters.sharedInfo == Data([0x01]), "info")
    let empty = TKTokenKeyExchangeParameters()
    tkMust(empty.requestedSize == 0, "zero")
    tkMust(empty.sharedInfo == nil, "nil info")
}

func testTKTokenKeyAlgorithmTypeExists() {
    _ = TKTokenKeyAlgorithm()
}

func testTKTokenDriverDelegateDefault() {
    final class Probe: NSObject, TKTokenDriverDelegate {}
    let probe = Probe()
    let driver = TKTokenDriver()
    driver.delegate = probe
    tkMust(driver.delegate === probe, "delegate")
    do {
        _ = try probe.tokenDriver(driver, tokenFor: TKToken.Configuration(instanceID: "x"))
        preconditionFailure("tokenFor")
    } catch {
        tkMust(TKError.Code.notImplemented ~= error, "tokenFor")
    }
    probe.tokenDriver(driver, terminateToken: TKToken(tokenDriver: driver, instanceID: "x"))
}

func testTKTokenDelegateCreateSession() {
    final class Probe: NSObject, TKTokenDelegate {
        func createSession(_ token: TKToken) throws -> TKTokenSession {
            TKTokenSession(token: token)
        }
    }
    let probe = Probe()
    let token = TKToken(tokenDriver: TKTokenDriver(), instanceID: "d")
    token.delegate = probe
    let session = try! probe.createSession(token)
    tkMust(session.token === token, "session")
    probe.token(token, terminateSession: session)
}

func testTKTokenSessionDelegateDefaults() {
    final class Probe: NSObject, TKTokenSessionDelegate {}
    let probe = Probe()
    let token = TKToken(tokenDriver: TKTokenDriver(), instanceID: "d")
    let session = TKTokenSession(token: token)
    session.delegate = probe
    tkMust(
        probe.tokenSession(session, supports: .signData, keyObjectID: NSNumber(value: 1), algorithm: TKTokenKeyAlgorithm()) == false,
        "supports"
    )
    do {
        _ = try probe.tokenSession(session, sign: Data(), keyObjectID: NSNumber(value: 1), algorithm: TKTokenKeyAlgorithm())
        preconditionFailure("sign")
    } catch {
        tkMust(TKError.Code.notImplemented ~= error, "sign")
    }
    do {
        _ = try probe.tokenSession(session, decrypt: Data(), keyObjectID: NSNumber(value: 1), algorithm: TKTokenKeyAlgorithm())
        preconditionFailure("decrypt")
    } catch {
        tkMust(TKError.Code.notImplemented ~= error, "decrypt")
    }
    do {
        _ = try probe.tokenSession(
            session,
            performKeyExchange: Data(),
            keyObjectID: NSNumber(value: 1),
            algorithm: TKTokenKeyAlgorithm(),
            parameters: TKTokenKeyExchangeParameters()
        )
        preconditionFailure("kex")
    } catch {
        tkMust(TKError.Code.notImplemented ~= error, "kex")
    }
    do {
        _ = try probe.tokenSession(session, beginAuthFor: .signData, constraint: NSObject())
        preconditionFailure("auth")
    } catch {
        tkMust(TKError.Code.authenticationNeeded ~= error, "auth")
    }
}

func testTKSmartCardTokenDriverDelegate() {
    final class Probe: NSObject, TKSmartCardTokenDriverDelegate {
        func tokenDriver(
            _ driver: TKSmartCardTokenDriver,
            createTokenFor smartCard: TKSmartCard,
            aid AID: Data?
        ) throws -> TKSmartCardToken {
            TKSmartCardToken(smartCard: smartCard, aid: AID, instanceID: "created", tokenDriver: driver)
        }
    }
    let probe = Probe()
    let driver = TKSmartCardTokenDriver()
    let token = try! probe.tokenDriver(driver, createTokenFor: TKSmartCard(), aid: nil)
    tkMust(token.configuration.instanceID == "created", "created")
}

func testTKSmartCardUserInteractionDelegateDefaults() {
    final class Probe: NSObject, TKSmartCardUserInteractionDelegate {}
    let probe = Probe()
    let interaction = TKSmartCardUserInteraction()
    interaction.delegate = probe
    probe.characterEntered(in: interaction)
    probe.correctionKeyPressed(in: interaction)
    probe.invalidCharacterEntered(in: interaction)
    probe.newPINConfirmationRequested(in: interaction)
    probe.newPINRequested(in: interaction)
    probe.oldPINRequested(in: interaction)
    probe.validationKeyPressed(in: interaction)
}
