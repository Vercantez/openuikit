import Foundation
import PermissionKit

func permissionKitDependencyIdentityProbe() {
    let uuid = UUID()
    let data = Data("permission-kit".utf8)
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    precondition(type(of: uuid) == UUID.self)
    precondition(type(of: data) == Data.self)
    precondition(type(of: date) == Date.self)
    precondition(!String(reflecting: type(of: uuid)).hasPrefix("PermissionKit."))
    precondition(!String(reflecting: type(of: data)).hasPrefix("PermissionKit."))
    precondition(!String(reflecting: type(of: date)).hasPrefix("PermissionKit."))

    var components = PersonNameComponents()
    components.givenName = String(data: data, encoding: .utf8)
    let handle = CommunicationHandle(value: "identity@example.com", kind: .emailAddress)
    let person = CommunicationTopic.PersonInformation(
        handle: handle,
        nameComponents: components,
        avatarImage: nil
    )
    precondition(person.nameComponents?.givenName == "permission-kit")

    let question = PermissionQuestion(handle: handle)
    question.expirationDate = date
    precondition(question.expirationDate == date)
    precondition(question.id != uuid || question.id == uuid)

    let choice = PermissionChoice.approve
    let response = PermissionResponse(question: question, choice: choice)
    precondition(response.choice.title == "Approve")
}

#if PERMISSIONKIT_IDENTITY_MAIN
permissionKitDependencyIdentityProbe()
print("PERMISSIONKIT_DEPENDENCY_IDENTITY_OK")
#endif
