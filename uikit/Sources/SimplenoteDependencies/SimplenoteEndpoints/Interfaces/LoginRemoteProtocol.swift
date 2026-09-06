import Foundation


// MARK: - LoginRemoteProtocol
//
public protocol LoginRemoteProtocol {
    func requestLoginEmail(email: String) async throws
    func requestLoginConfirmation(email: String, authCode: String) async throws -> LoginConfirmationResponse
}


extension LoginRemote: LoginRemoteProtocol { }
