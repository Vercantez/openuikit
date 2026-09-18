import Foundation

// Wave 22: async in-process completions for leftover declared helpers.
//
// The sealed runner now awaits top-level `func test*() async`, so declared
// async helpers that complete without a Siri daemon, Shortcuts registrar,
// or prompt UI move to implemented with async behavioral pins in
// `tests/agent/AppIntentsWave22Tests.swift`. Everything added here is either
// an in-process delegation (donations record locally, queries resolve from
// the injected entity, file bytes round-trip in memory) or a deterministic
// fail-closed throw (`unsupportedOnDevice`). No success involving Shortcuts,
// Siri, Apple Pay, Screen Time, or system UI is claimed.

// MARK: - IntentParameter fail-closed confirmation

extension IntentParameter {
    /// Linux has no parameter prompt UI. Apple's async confirmation presents
    /// a system dialog; this host fails closed without inventing approval.
    public func requestConfirmation(
        for itemToConfirm: Value.ValueType,
        dialog: IntentDialog? = nil
    ) async throws -> Bool {
        _ = itemToConfirm
        _ = dialog
        throw AppIntentError.Unrecoverable.unsupportedOnDevice
    }
}

// MARK: - AppIntent fail-closed confirmations

extension AppIntent {
    public func requestConfirmation<R: IntentResult>(
        output: R,
        confirmationActionName: ConfirmationActionName = .continue,
        showPrompt: Bool = true
    ) async throws {
        _ = output
        _ = confirmationActionName
        _ = showPrompt
        throw AppIntentError.Unrecoverable.unsupportedOnDevice
    }

    public func requestConfirmation<R: IntentResult>(
        result: R,
        confirmationActionName: ConfirmationActionName = .continue,
        showPrompt: Bool = true
    ) async throws {
        _ = result
        _ = confirmationActionName
        _ = showPrompt
        throw AppIntentError.Unrecoverable.unsupportedOnDevice
    }

    public func requestConfirmation<S: SnippetIntent>(
        conditions: ConfirmationConditions = [],
        actionName: ConfirmationActionName = .continue,
        dialog: IntentDialog? = nil,
        showDialogAsPrompt: Bool = true,
        snippetIntent: S
    ) async throws {
        _ = conditions
        _ = actionName
        _ = dialog
        _ = showDialogAsPrompt
        _ = snippetIntent
        throw AppIntentError.Unrecoverable.unsupportedOnDevice
    }

    public func requestConfirmation<S: SnippetIntent>(
        conditions: ConfirmationConditions = [],
        actionName: ConfirmationActionName = .continue,
        dialog: IntentDialog? = nil,
        showDialogAsPrompt: Bool = true,
        snippetIntent: S
    ) async throws -> S.PerformResult.Value where S.PerformResult: ReturnsValue<S.PerformResult.Value> {
        _ = conditions
        _ = actionName
        _ = dialog
        _ = showDialogAsPrompt
        _ = snippetIntent
        throw AppIntentError.Unrecoverable.unsupportedOnDevice
    }
}

// MARK: - Fail-closed performs

extension ControlConfigurationIntent {
    /// Linux hosts no control-configuration runner. Performing would claim
    /// system control execution, so this fails closed.
    public func performs() async throws -> Never {
        throw AppIntentError.Unrecoverable.unsupportedOnDevice
    }
}

extension URLRepresentableIntent {
    /// Linux resolves no URL-representation registry entry. Performing
    /// would claim a system URL handoff, so this fails closed.
    public func performs() async throws -> Never {
        throw AppIntentError.Unrecoverable.unsupportedOnDevice
    }
}

extension OpenURLIntent: URLRepresentableIntent {}

// MARK: - OpenURLIntent entity-backed init (fail-closed)

extension OpenURLIntent {
    /// Linux has no URL-representation registry, so resolving an
    /// entity-backed URL stays fail-closed instead of inventing a URL.
    public init<A: URLRepresentableEntity>(urlRepresentable: A) async throws {
        _ = urlRepresentable
        throw AppIntentError.Unrecoverable.unsupportedOnDevice
    }
}
