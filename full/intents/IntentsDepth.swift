// Host dispatcher, extension routing, and resolution reflection for the
// isolated Linux Intents starting point. Apple Siri speech, account sync,
// and extension-process launch remain fail-closed.

@_spi(OpenIntentsHost)
public enum INHostIntentAction: String, Sendable {
    case handle
    case confirm
    case resolve
}

@_spi(OpenIntentsHost)
public enum INHostIntentDispatcher {
    public static func dispatch(
        _ intent: INIntent,
        action: INHostIntentAction,
        handler: Any
    ) -> Any {
        switch action {
        case .handle:
            return handle(intent, handler: handler)
        case .confirm:
            return confirm(intent, handler: handler)
        case .resolve:
            return resolve(intent, handler: handler)
        }
    }

    public static func handle(_ intent: INIntent, handler: Any) -> INIntentResponse {
        if let send = intent as? INSendMessageIntent,
           let typed = handler as? any INSendMessageIntentHandling {
            var response: INSendMessageIntentResponse?
            typed.handle(intent: send) { response = $0 }
            return response ?? INSendMessageIntentResponse(code: .failure, userActivity: nil)
        }
        if let search = intent as? INSearchForMessagesIntent,
           let typed = handler as? any INSearchForMessagesIntentHandling {
            var response: INSearchForMessagesIntentResponse?
            typed.handle(intent: search) { response = $0 }
            return response ?? INSearchForMessagesIntentResponse(code: .failure, userActivity: nil)
        }
        if let start = intent as? INStartCallIntent,
           let typed = handler as? any INStartCallIntentHandling {
            var response: INStartCallIntentResponse?
            typed.handle(intent: start) { response = $0 }
            return response ?? INStartCallIntentResponse(code: .failure, userActivity: nil)
        }
        if let car = intent as? INGetCarPowerLevelStatusIntent,
           let typed = handler as? any INGetCarPowerLevelStatusIntentHandling {
            var response: INGetCarPowerLevelStatusIntentResponse?
            typed.handle(intent: car) { response = $0 }
            return response ?? INGetCarPowerLevelStatusIntentResponse(code: .failure, userActivity: nil)
        }
        if let ride = intent as? INGetRideStatusIntent,
           let typed = handler as? any INGetRideStatusIntentHandling {
            var response: INGetRideStatusIntentResponse?
            typed.handle(intent: ride) { response = $0 }
            return response ?? INGetRideStatusIntentResponse(code: .failure, userActivity: nil)
        }
        if let list = intent as? INListRideOptionsIntent,
           let typed = handler as? any INListRideOptionsIntentHandling {
            var response: INListRideOptionsIntentResponse?
            typed.handle(intent: list) { response = $0 }
            return response ?? INListRideOptionsIntentResponse(code: .failure, userActivity: nil)
        }
        if let request = intent as? INRequestRideIntent,
           let typed = handler as? any INRequestRideIntentHandling {
            var response: INRequestRideIntentResponse?
            typed.handle(intent: request) { response = $0 }
            return response ?? INRequestRideIntentResponse(code: .failure, userActivity: nil)
        }
        return INIntentResponse()
    }

    public static func confirm(_ intent: INIntent, handler: Any) -> INIntentResponse {
        if let send = intent as? INSendMessageIntent,
           let typed = handler as? any INSendMessageIntentHandling {
            var response: INSendMessageIntentResponse?
            typed.confirm(intent: send) { response = $0 }
            return response ?? INSendMessageIntentResponse(code: .ready, userActivity: nil)
        }
        if let search = intent as? INSearchForMessagesIntent,
           let typed = handler as? any INSearchForMessagesIntentHandling {
            var response: INSearchForMessagesIntentResponse?
            typed.confirm(intent: search) { response = $0 }
            return response ?? INSearchForMessagesIntentResponse(code: .ready, userActivity: nil)
        }
        if let start = intent as? INStartCallIntent,
           let typed = handler as? any INStartCallIntentHandling {
            var response: INStartCallIntentResponse?
            typed.confirm(intent: start) { response = $0 }
            return response ?? INStartCallIntentResponse(code: .ready, userActivity: nil)
        }
        if let car = intent as? INGetCarPowerLevelStatusIntent,
           let typed = handler as? any INGetCarPowerLevelStatusIntentHandling {
            var response: INGetCarPowerLevelStatusIntentResponse?
            typed.confirm(intent: car) { response = $0 }
            return response ?? INGetCarPowerLevelStatusIntentResponse(code: .ready, userActivity: nil)
        }
        if let ride = intent as? INGetRideStatusIntent,
           let typed = handler as? any INGetRideStatusIntentHandling {
            var response: INGetRideStatusIntentResponse?
            typed.confirm(intent: ride) { response = $0 }
            return response ?? INGetRideStatusIntentResponse(code: .ready, userActivity: nil)
        }
        if let list = intent as? INListRideOptionsIntent,
           let typed = handler as? any INListRideOptionsIntentHandling {
            var response: INListRideOptionsIntentResponse?
            typed.confirm(intent: list) { response = $0 }
            return response ?? INListRideOptionsIntentResponse(code: .ready, userActivity: nil)
        }
        if let request = intent as? INRequestRideIntent,
           let typed = handler as? any INRequestRideIntentHandling {
            var response: INRequestRideIntentResponse?
            typed.confirm(intent: request) { response = $0 }
            return response ?? INRequestRideIntentResponse(code: .ready, userActivity: nil)
        }
        return INIntentResponse()
    }

    public static func resolve(_ intent: INIntent, handler: Any) -> [INIntentResolutionResult] {
        if let send = intent as? INSendMessageIntent,
           let typed = handler as? any INSendMessageIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolveContent(for: send) { results.append($0) }
            typed.resolveSpeakableGroupName(for: send) { results.append($0) }
            return results
        }
        if let search = intent as? INSearchForMessagesIntent,
           let typed = handler as? any INSearchForMessagesIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolveAttributes(for: search) { results.append($0) }
            typed.resolveDateTimeRange(for: search) { results.append($0) }
            return results
        }
        if let start = intent as? INStartCallIntent,
           let typed = handler as? any INStartCallIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolveCallCapability(for: start) { results.append($0) }
            typed.resolveDestinationType(for: start) { results.append($0) }
            return results
        }
        if let car = intent as? INGetCarPowerLevelStatusIntent,
           let typed = handler as? any INGetCarPowerLevelStatusIntentHandling {
            var result: INSpeakableStringResolutionResult?
            typed.resolveCarName(for: car) { result = $0 }
            return [result ?? INSpeakableStringResolutionResult.needsValue()]
        }
        if let request = intent as? INRequestRideIntent,
           let typed = handler as? any INRequestRideIntentHandling {
            var results: [INIntentResolutionResult] = []
            typed.resolvePartySize(for: request) { results.append($0) }
            typed.resolveRideOptionName(for: request) { results.append($0) }
            typed.resolveScheduledPickupTime(for: request) { results.append($0) }
            return results
        }
        return [INIntentResolutionResult.needsValue()]
    }
}

extension INIntentResolutionResult {
    @_spi(OpenIntentsHost)
    public var linuxOutcomeCode: Int { outcome.rawValue }
}
