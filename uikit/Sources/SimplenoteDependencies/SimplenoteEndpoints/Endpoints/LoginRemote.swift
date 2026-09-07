import Foundation


// MARK: - LoginRemote
//
public class LoginRemote: Remote {

    public func requestLoginEmail(email: String) async throws {
        let request = requestForLoginRequest(email: email)
        try await performDataTask(with: request)
    }

    public func requestLoginConfirmation(email: String, authCode: String) async throws -> LoginConfirmationResponse {
        let request = requestForLoginCompletion(email: email, authCode: authCode)
        return try await performDataTask(with: request, type: LoginConfirmationResponse.self)
    }
}


// MARK: - LoginConfirmationResponse
//
public struct LoginConfirmationResponse: Codable, Equatable {
    public let username: String
    public let syncToken: String
    
    public init(username: String, syncToken: String) {
        self.username = username
        self.syncToken = syncToken
    }
}


// MARK: - Private API(s)
//
private extension LoginRemote {

    func requestForLoginRequest(email: String) -> URLRequest {
        let url = URL(string: EndpointConstants.loginRequestURL)!
        return requestForURL(url, method: RemoteConstants.Method.POST, httpBody: [
            "request_source": EndpointConstants.platformName,
            "username": email.lowercased()
        ])
    }

    func requestForLoginCompletion(email: String, authCode: String) -> URLRequest {
        let url = URL(string: EndpointConstants.loginCompletionURL)!
        return requestForURL(url, method: RemoteConstants.Method.POST, httpBody: [
            "auth_code": authCode,
            "username": email
        ])
    }
}
