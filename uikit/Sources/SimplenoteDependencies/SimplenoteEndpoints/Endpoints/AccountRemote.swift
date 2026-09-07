import Foundation


// MARK: - AccountVerificationRemote
//
public class AccountRemote: Remote {
    
    /// Send verification request for specified email address
    ///
    public func verify(email: String, completion: @escaping (_ result: Result<Data?, RemoteError>) -> Void) {
        let request = verificationURLRequest(email: email)
        performDataTask(with: request, completion: completion)
    }
    
    /// Send account deletion request for user
    ///
    public func requestDelete(_ user: UserProtocol, completion: @escaping (_ result: Result<Data?, RemoteError>) -> Void) {
        let request = deleteRequest(user: user)
        performDataTask(with: request, completion: completion)
    }
}


// MARK: - Private Helpers
//
private extension AccountRemote {

    private func verificationURLRequest(email: String) -> URLRequest {
        let base64EncodedEmail = email.data(using: .utf8)!.base64EncodedString()
        let verificationURL = URL(string: EndpointConstants.simplenoteVerificationURL)!

        var request = URLRequest(url: verificationURL.appendingPathComponent(base64EncodedEmail),
                                 cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                 timeoutInterval: RemoteConstants.timeout)
        request.httpMethod = RemoteConstants.Method.GET

        return request
    }

    private func deleteRequest(user: UserProtocol) -> URLRequest {
        let url = URL(string: EndpointConstants.accountDeletionURL)!

        var request = URLRequest(url: url,
                                 cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                 timeoutInterval: RemoteConstants.timeout)
        request.httpMethod = RemoteConstants.Method.POST
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = [
            "username": user.email.lowercased(),
            "token": user.authToken
        ]
        request.httpBody = try? JSONEncoder().encode(body)

        return request
    }
}
