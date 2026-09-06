import Foundation
import Glibc
import ManagedApp

func managedAppExpect(_ condition: Bool, _ message: String = "") {
    precondition(condition, message)
}

func managedAppExpectEqual<T: Equatable>(_ lhs: T, _ rhs: T, _ message: String = "") {
    precondition(lhs == rhs, "\(message): \(String(describing: lhs)) != \(String(describing: rhs))")
}

final class ManagedAppBox<Value>: @unchecked Sendable {
    var value: Value

    init(_ value: Value) {
        self.value = value
    }
}

func managedAppAwait<T: Sendable>(
    _ body: @escaping @Sendable () async throws -> T
) -> Result<T, Error> {
    var fds: [Int32] = [0, 0]
    precondition(pipe(&fds) == 0, "pipe")
    let readFd = fds[0]
    let writeFd = fds[1]
    let box = ManagedAppBox<Result<T, Error>?>(nil)
    Task {
        do {
            box.value = .success(try await body())
        } catch {
            box.value = .failure(error)
        }
        var token: UInt8 = 1
        _ = write(writeFd, &token, 1)
        close(writeFd)
    }
    var token: UInt8 = 0
    _ = read(readFd, &token, 1)
    close(readFd)
    guard let result = box.value else {
        preconditionFailure("async probe did not complete")
    }
    return result
}

func managedAppAwaitValue<T: Sendable>(
    _ body: @escaping @Sendable () async throws -> T
) -> T {
    switch managedAppAwait(body) {
    case .success(let value):
        return value
    case .failure(let error):
        preconditionFailure("unexpected error: \(error)")
    }
}

func managedAppAwaitManagedAppError<T: Sendable>(
    _ body: @escaping @Sendable () async throws -> T
) -> ManagedAppError {
    switch managedAppAwait(body) {
    case .success:
        preconditionFailure("expected ManagedAppError")
    case .failure(let error):
        guard let typed = error as? ManagedAppError else {
            preconditionFailure("expected ManagedAppError, got \(error)")
        }
        return typed
    }
}

struct ManagedAppProbeConfiguration: Codable, Equatable, Sendable {
    var name: String
}

struct ManagedAppProbeDecodingError: ManagedAppConfigurationDecodingError, Equatable {
    var code: ManagedAppConfigurationDecodingErrorCode
    var message: String
}
