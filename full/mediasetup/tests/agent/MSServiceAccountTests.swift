import Foundation
import MediaSetup

func testServiceAccountIsNSObjectSubclass() {
    let account = MSServiceAccount(serviceName: "Music", accountName: "pat")
    precondition(account is NSObject)
    let same = account
    precondition(account == same)
    precondition(account === same)
    let other = MSServiceAccount(serviceName: "Music", accountName: "pat")
    precondition(account !== other)
    precondition(account != other)
}

func testServiceAccountInitStoresNames() {
    let account = MSServiceAccount(serviceName: "Podcasts", accountName: "kit")
    precondition(account.serviceName == "Podcasts")
    precondition(account.accountName == "kit")
    precondition(account.clientID == nil)
    precondition(account.clientSecret == nil)
    precondition(account.configurationURL == nil)
    precondition(account.authorizationTokenURL == nil)
    precondition(account.authorizationScope == nil)

    let empty = MSServiceAccount(serviceName: "", accountName: "")
    precondition(empty.serviceName.isEmpty)
    precondition(empty.accountName.isEmpty)
}

func testServiceAccountAccountNameReadonly() {
    let account = MSServiceAccount(serviceName: "Radio", accountName: "ada")
    precondition(account.accountName == "ada")
    let again = MSServiceAccount(serviceName: "Radio", accountName: "ada")
    precondition(again.accountName == account.accountName)
    precondition(again !== account)
}

func testServiceAccountServiceNameReadonly() {
    let account = MSServiceAccount(serviceName: "Radio", accountName: "ada")
    precondition(account.serviceName == "Radio")
    let spaced = MSServiceAccount(serviceName: "  Music  ", accountName: "x")
    precondition(spaced.serviceName == "  Music  ")
}

func testServiceAccountClientIDRoundTrip() {
    let account = MSServiceAccount(serviceName: "s", accountName: "a")
    precondition(account.clientID == nil)
    account.clientID = "client-1"
    precondition(account.clientID == "client-1")
    account.clientID = ""
    precondition(account.clientID == "")
    account.clientID = nil
    precondition(account.clientID == nil)
}

func testServiceAccountClientSecretRoundTrip() {
    let account = MSServiceAccount(serviceName: "s", accountName: "a")
    precondition(account.clientSecret == nil)
    account.clientSecret = "secret-value"
    precondition(account.clientSecret == "secret-value")
    account.clientSecret = nil
    precondition(account.clientSecret == nil)
}

func testServiceAccountConfigurationURLRoundTrip() {
    let account = MSServiceAccount(serviceName: "s", accountName: "a")
    precondition(account.configurationURL == nil)
    var url = URL(string: "https://media.example/config")!
    account.configurationURL = url
    precondition(account.configurationURL == URL(string: "https://media.example/config"))
    url = URL(string: "https://media.example/other")!
    precondition(account.configurationURL?.absoluteString == "https://media.example/config")
    account.configurationURL = nil
    precondition(account.configurationURL == nil)
}

func testServiceAccountAuthorizationTokenURLRoundTrip() {
    let account = MSServiceAccount(serviceName: "s", accountName: "a")
    precondition(account.authorizationTokenURL == nil)
    let url = URL(string: "https://media.example/token")!
    account.authorizationTokenURL = url
    precondition(account.authorizationTokenURL == url)
    account.authorizationTokenURL = URL(string: "https://media.example/token2")
    precondition(account.authorizationTokenURL?.path == "/token2")
}

func testServiceAccountAuthorizationScopeRoundTrip() {
    let account = MSServiceAccount(serviceName: "s", accountName: "a")
    precondition(account.authorizationScope == nil)
    account.authorizationScope = "streaming offline"
    precondition(account.authorizationScope == "streaming offline")
    account.authorizationScope = nil
    precondition(account.authorizationScope == nil)
}
