@_spi(OpenUIKitHost) import NetworkExtension
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
func testFailClosedManagers() {
    neWait {
        NetworkExtensionHostPreferences.resetForHostTesting(
            rootDirectory: FileManager.default.temporaryDirectory
                .appendingPathComponent("ne-vpn-managers-\(UUID().uuidString)", isDirectory: true)
        )
        let vpnLoad = await awaitHostCallback { handler in
            NEVPNManager.shared().loadFromPreferences(completionHandler: handler)
        }
        precondition(vpnLoad == nil)
        precondition(NEVPNManager.shared().connection.status == .invalid)

        let allTunnels = await awaitHostCallback { handler in
            NETunnelProviderManager.loadAllFromPreferences { managers, error in
                handler((managers, error))
            }
        }
        precondition(allTunnels.0?.isEmpty == true)
        precondition(allTunnels.1 == nil)

        let filterLoad = await awaitHostCallback { handler in
            NEFilterManager.shared().loadFromPreferences(completionHandler: handler)
        }
        guard let filterError = filterLoad as? NSError else {
            fatalError("expected NSError from filter load")
        }
        precondition(filterError.domain == NEFilterErrorDomain)
        precondition(filterError.code == NEFilterManagerError.configurationInvalid.rawValue)
        NEFilterManager.shared().isEnabled = false
        NEFilterManager.shared().providerConfiguration = NEFilterProviderConfiguration()
        NEFilterManager.shared().providerConfiguration?.filterSockets = true

        let dnsLoad = await awaitHostCallback { handler in
            NEDNSSettingsManager.shared().loadFromPreferences(completionHandler: handler)
        }
        guard let dnsError = dnsLoad as? NSError else {
            fatalError("expected NSError from DNS settings load")
        }
        precondition(dnsError.domain == NEDNSSettingsErrorDomain)
        precondition(NEDNSSettingsManager.shared().isEnabled == false)

        let proxyLoad = await awaitHostCallback { handler in
            NEDNSProxyManager.shared().loadFromPreferences(completionHandler: handler)
        }
        guard let proxyError = proxyLoad as? NSError else {
            fatalError("expected NSError from DNS proxy load")
        }
        precondition(proxyError.domain == NEDNSProxyErrorDomain)

        let pushLoad = await awaitHostCallback { handler in
            NEAppPushManager().loadFromPreferences(completionHandler: handler)
        }
        guard let pushError = pushLoad as? NEAppPushManagerError else {
            fatalError("expected NEAppPushManagerError")
        }
        precondition(pushError.code == .configurationNotLoaded)
        precondition(NEAppPushManagerError.errorDomain == NEAppPushErrorDomain)

        let allPush = await awaitHostCallback { handler in
            NEAppPushManager.loadAllFromPreferences { managers, error in
                handler((managers, error))
            }
        }
        precondition(allPush.0 == nil)

        let relayLoad = await awaitHostCallback { handler in
            NERelayManager.shared().loadFromPreferences(completionHandler: handler)
        }
        guard let relayError = relayLoad as? NSError else {
            fatalError("expected NSError from relay load")
        }
        precondition(relayError.domain == NERelayErrorDomain)
        let relay = NERelay()
        relay.http3RelayURL = URL(string: "https://relay.example.invalid")
        NERelayManager.shared().relays = [relay]
        NERelayManager.shared().isEnabled = false

        do {
            try await NEHotspotConfigurationManager.shared.apply(
                NEHotspotConfiguration(ssid: "Example")
            )
            fatalError("hotspot apply must fail closed")
        } catch let error as NEHotspotConfigurationError {
            precondition(error == .internal)
        } catch {
            fatalError("unexpected hotspot error \(error)")
        }
        let ssids = await NEHotspotConfigurationManager.shared.configuredSSIDs()
        precondition(ssids.isEmpty)

        let currentNetwork = await awaitHostCallback { handler in
            NEHotspotNetwork.fetchCurrent(completionHandler: handler)
        }
        precondition(currentNetwork == nil)

        do {
            try await NEHotspotManager.shared.loadFromPreferences()
            fatalError("NEHotspotManager load must fail closed")
        } catch NEHotspotManager.Error.configurationNotLoaded {
            ()
        } catch {
            fatalError("unexpected hotspot manager error \(error)")
        }

        do {
            try await NEURLFilterManager.shared.loadFromPreferences()
            fatalError("URL filter load must fail closed")
        } catch let error as NEURLFilterManager.Error {
            precondition(error == .configurationNotLoaded)
            precondition(error.rawValue == 8)
        } catch {
            fatalError("unexpected URL filter error \(error)")
        }
        let urlFilterStatus = await NEURLFilterManager.shared.status
        precondition(urlFilterStatus == .invalid)
        precondition(NEURLFilterManager.shared.shouldFailClosed)
    }
}

func testFailClosedCompletions() {
    neWait {
        NetworkExtensionHostPreferences.resetForHostTesting(
            rootDirectory: FileManager.default.temporaryDirectory
                .appendingPathComponent("ne-vpn-failclosed-\(UUID().uuidString)", isDirectory: true)
        )
        let vpnSaveStale = await awaitHostCallback { handler in
            NEVPNManager.shared().saveToPreferences(completionHandler: handler)
        }
        requireVPNError(vpnSaveStale, code: .configurationStale)
        let loaded = await awaitHostCallback { handler in
            NEVPNManager.shared().loadFromPreferences(completionHandler: handler)
        }
        precondition(loaded == nil)
        let vpnSaveInvalid = await awaitHostCallback { handler in
            NEVPNManager.shared().saveToPreferences(completionHandler: handler)
        }
        requireVPNError(vpnSaveInvalid, code: .configurationInvalid)
        let vpnRemove = await awaitHostCallback { handler in
            NEVPNManager.shared().removeFromPreferences(completionHandler: handler)
        }
        precondition(vpnRemove == nil)

        let filterSave = await awaitHostCallback { handler in
            NEFilterManager.shared().saveToPreferences(completionHandler: handler)
        }
        guard let filterSaveError = filterSave as? NSError else {
            fatalError("expected NSError from filter save")
        }
        precondition(filterSaveError.domain == NEFilterErrorDomain)
        precondition(
            filterSaveError.code == NEFilterManagerError.configurationPermissionDenied.rawValue
        )
        let filterRemove = await awaitHostCallback { handler in
            NEFilterManager.shared().removeFromPreferences(completionHandler: handler)
        }
        guard let filterRemoveError = filterRemove as? NSError else {
            fatalError("expected NSError from filter remove")
        }
        precondition(
            filterRemoveError.code == NEFilterManagerError.configurationCannotBeRemoved.rawValue
        )

        let dnsSave = await awaitHostCallback { handler in
            NEDNSSettingsManager.shared().saveToPreferences(completionHandler: handler)
        }
        guard let dnsSaveError = dnsSave as? NSError else {
            fatalError("expected NSError from DNS save")
        }
        precondition(dnsSaveError.domain == NEDNSSettingsErrorDomain)
        let dnsRemove = await awaitHostCallback { handler in
            NEDNSSettingsManager.shared().removeFromPreferences(completionHandler: handler)
        }
        guard let dnsRemoveError = dnsRemove as? NSError else {
            fatalError("expected NSError from DNS remove")
        }
        precondition(
            dnsRemoveError.code == NEDNSSettingsManagerError.configurationCannotBeRemoved.rawValue
        )

        let proxySave = await awaitHostCallback { handler in
            NEDNSProxyManager.shared().saveToPreferences(completionHandler: handler)
        }
        guard let proxySaveError = proxySave as? NSError else {
            fatalError("expected NSError from DNS proxy save")
        }
        precondition(proxySaveError.domain == NEDNSProxyErrorDomain)
        let proxyRemove = await awaitHostCallback { handler in
            NEDNSProxyManager.shared().removeFromPreferences(completionHandler: handler)
        }
        guard let proxyRemoveError = proxyRemove as? NSError else {
            fatalError("expected NSError from DNS proxy remove")
        }
        precondition(
            proxyRemoveError.code == NEDNSProxyManagerError.configurationCannotBeRemoved.rawValue
        )

        let pushSave = await awaitHostCallback { handler in
            NEAppPushManager().saveToPreferences(completionHandler: handler)
        }
        guard let pushSaveError = pushSave as? NEAppPushManagerError else {
            fatalError("expected NEAppPushManagerError from push save")
        }
        precondition(pushSaveError.code == .configurationInvalid)
        let pushRemove = await awaitHostCallback { handler in
            NEAppPushManager().removeFromPreferences(completionHandler: handler)
        }
        guard let pushRemoveError = pushRemove as? NEAppPushManagerError else {
            fatalError("expected NEAppPushManagerError from push remove")
        }
        precondition(pushRemoveError.code == .configurationInvalid)

        let relaySave = await awaitHostCallback { handler in
            NERelayManager.shared().saveToPreferences(completionHandler: handler)
        }
        guard let relaySaveError = relaySave as? NSError else {
            fatalError("expected NSError from relay save")
        }
        precondition(relaySaveError.domain == NERelayErrorDomain)
        let relayRemove = await awaitHostCallback { handler in
            NERelayManager.shared().removeFromPreferences(completionHandler: handler)
        }
        guard let relayRemoveError = relayRemove as? NSError else {
            fatalError("expected NSError from relay remove")
        }
        precondition(
            relayRemoveError.code == NERelayManagerError.configurationCannotBeRemoved.rawValue
        )
        let allRelays = await awaitHostCallback { handler in
            NERelayManager.loadAllManagersFromPreferences { managers, error in
                handler((managers, error))
            }
        }
        precondition(allRelays.0.isEmpty)
        let lastRelayErrors = await awaitHostCallback { handler in
            NERelayManager.shared().getLastClientErrors(1, completionHandler: handler)
        }
        precondition(lastRelayErrors == nil)

        let filterStart = await awaitHostCallback { handler in
            NEFilterProvider().startFilter(completionHandler: handler)
        }
        guard let filterStartError = filterStart as? NSError else {
            fatalError("expected NSError from filter start")
        }
        precondition(filterStartError.domain == NEFilterErrorDomain)

        let proxyOpen = await awaitHostCallback { handler in
            NEAppProxyTCPFlow().open(withLocalFlowEndpoint: nil, completionHandler: handler)
        }
        guard let proxyOpenError = proxyOpen as? NEAppProxyFlowError else {
            fatalError("expected NEAppProxyFlowError from proxy open")
        }
        precondition(proxyOpenError.code == .notConnected)

        let datagrams = await awaitHostCallback { handler in
            NEPacketTunnelFlow().readPackets { packets, protocols in
                handler((packets, protocols))
            }
        }
        precondition(datagrams.0.isEmpty)
        precondition(datagrams.1.isEmpty)

        do {
            try await NEAppProxyTCPFlow().open(withLocalEndpoint: nil)
            fatalError("app proxy open must fail closed")
        } catch let error as NEAppProxyFlowError {
            precondition(error.code == .notConnected)
        } catch {
            fatalError("unexpected app proxy open error \(error)")
        }
        do {
            try await NEAppProxyTCPFlow().open(withLocalFlowEndpoint: nil)
            fatalError("app proxy open flow endpoint must fail closed")
        } catch let error as NEAppProxyFlowError {
            precondition(error.code == .notConnected)
        } catch {
            fatalError("unexpected app proxy open flow error \(error)")
        }

        let tcpRead = await awaitHostCallback { handler in
            NEAppProxyTCPFlow().readData { data, error in
                handler((data, error))
            }
        }
        precondition(tcpRead.0 == nil)
        do {
            try await NEAppProxyTCPFlow().write(Data([0x01]))
            fatalError("app proxy write must fail closed")
        } catch let error as NEAppProxyFlowError {
            precondition(error.code == .notConnected)
        } catch {
            fatalError("unexpected app proxy write error \(error)")
        }

        let udpFlow = NEAppProxyUDPFlow()
        let datagramRead = await udpFlow.readDatagrams()
        precondition(datagramRead.0 == nil)
        do {
            try await udpFlow.writeDatagrams([(Data([0x01]), NWHostEndpoint(hostname: "h", port: "1"))])
            fatalError("udp writeDatagrams must fail closed")
        } catch let error as NEAppProxyFlowError {
            precondition(error.code == .notConnected)
        } catch {
            fatalError("unexpected udp write error \(error)")
        }
        do {
            try await udpFlow.writeDatagrams(
                [Data([0x01])],
                sentBy: [NWHostEndpoint(hostname: "h", port: "1")]
            )
            fatalError("udp writeDatagrams sentBy must fail closed")
        } catch let error as NEAppProxyFlowError {
            precondition(error.code == .notConnected)
        } catch {
            fatalError("unexpected udp write sentBy error \(error)")
        }
        let udpWrite = await awaitHostCallback { handler in
            udpFlow.writeDatagrams(
                [(Data([0x02]), NWHostEndpoint(hostname: "h", port: "1"))],
                completionHandler: handler
            )
        }
        precondition(udpWrite != nil)

        await NEAppProxyProvider().stopProxy(with: .userInitiated)
        do {
            try await NEDNSProxyProvider().startProxy(options: nil)
            fatalError("dns proxy start must fail closed")
        } catch {
            ()
        }
        await NEDNSProxyProvider().stopProxy(with: .providerDisabled)
        await NEFilterProvider().stopFilter(with: .userInitiated)
        let controlVerdict = await NEFilterControlProvider().handleNewFlow(NEFilterFlow())
        _ = controlVerdict
        let remediateVerdict = await NEFilterControlProvider().handleRemediation(for: NEFilterFlow())
        _ = remediateVerdict
        _ = await NETunnelProvider().handleAppMessage(Data([0x00]))

        do {
            try await NEHotspotManager.shared.saveToPreferences()
            fatalError("hotspot manager save must fail closed")
        } catch NEHotspotManager.Error.configurationInvalid {
            ()
        } catch {
            fatalError("unexpected hotspot save error \(error)")
        }
        do {
            try await NEHotspotManager.shared.removeFromPreferences()
            fatalError("hotspot manager remove must fail closed")
        } catch {
            ()
        }
        do {
            try await NEURLFilterManager.shared.resetPIRCache()
            fatalError("reset PIR cache must fail closed")
        } catch let error as NEURLFilterManager.Error {
            precondition(error == .configurationInvalid)
        } catch {
            fatalError("unexpected reset PIR error \(error)")
        }
        do {
            try await NEURLFilterManager.shared.saveToPreferences()
            fatalError("url filter save must fail closed")
        } catch {
            ()
        }
        do {
            try await NEURLFilterManager.shared.refreshPIRParameters()
            fatalError("refresh PIR must fail closed")
        } catch {
            ()
        }
        do {
            try await NEURLFilterManager.shared.removeFromPreferences()
            fatalError("url filter remove must fail closed")
        } catch {
            ()
        }
        _ = NEURLFilterManager.shared.handleConfigChange()
        _ = NEURLFilterManager.shared.handleStatusChange()
        _ = await NEURLFilterManager.shared.lastDisconnectError

        let multi = await awaitHostCallback { handler in
            NWUDPSession(endpoint: NWHostEndpoint(hostname: "h", port: "1"))
                .writeMultipleDatagrams([Data([0x01])], completionHandler: handler)
        }
        precondition(multi != nil)

        let allProxyManagers = await awaitHostCallback { handler in
            NEAppProxyProviderManager.loadAllFromPreferences { managers, error in
                handler((managers, error))
            }
        }
        _ = allProxyManagers
    }
}
