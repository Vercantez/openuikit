import Foundation
import SecureElementCredential

func testInstanceTypeCases() {
    let cases: [CredentialSession.Credential.InstanceInfo.InstanceType] = [
        .standalone,
        .headApplication,
        .groupApplication,
    ]
    precondition(cases.count == 3)
    precondition(Set(cases).count == 3)
    precondition(
        CredentialSession.Credential.InstanceInfo.InstanceType.standalone
            != .headApplication
    )
}

func testInstanceTypeEquality() {
    let a = CredentialSession.Credential.InstanceInfo.InstanceType.standalone
    let b = CredentialSession.Credential.InstanceInfo.InstanceType.standalone
    precondition(a == b)
    precondition(a != .groupApplication)
}

func testInstanceTypeHash() {
    let a = CredentialSession.Credential.InstanceInfo.InstanceType.headApplication
    let b = CredentialSession.Credential.InstanceInfo.InstanceType.headApplication
    var h1 = Hasher()
    var h2 = Hasher()
    a.hash(into: &h1)
    b.hash(into: &h2)
    precondition(h1.finalize() == h2.finalize())
    precondition(a.hashValue == b.hashValue)
    precondition(a.hashValue != CredentialSession.Credential.InstanceInfo.InstanceType.standalone.hashValue)
}

func testInstanceAID() {
    let info = CredentialSession.Credential.InstanceInfo(
        instanceAID: Data([0xAA]),
        packageAID: Data([0xBB]),
        moduleAID: Data([0xCC]),
        securityDomainAID: Data([0xDD]),
        securityDomainKeyInfo: Data([0xEE]),
        lifeCycleState: Data([0xFF]),
        instanceType: .headApplication
    )
    precondition(info.instanceAID == Data([0xAA]))
}

func testPackageAID() {
    let info = CredentialSession.Credential.InstanceInfo(
        instanceAID: Data(),
        packageAID: Data([0x10, 0x20]),
        moduleAID: Data(),
        securityDomainAID: Data(),
        securityDomainKeyInfo: Data(),
        lifeCycleState: Data(),
        instanceType: .standalone
    )
    precondition(info.packageAID == Data([0x10, 0x20]))
}

func testModuleAID() {
    let info = CredentialSession.Credential.InstanceInfo(
        instanceAID: Data(),
        packageAID: Data(),
        moduleAID: Data([0x30]),
        securityDomainAID: Data(),
        securityDomainKeyInfo: Data(),
        lifeCycleState: Data(),
        instanceType: .standalone
    )
    precondition(info.moduleAID == Data([0x30]))
}

func testSecurityDomainAID() {
    let info = CredentialSession.Credential.InstanceInfo(
        instanceAID: Data(),
        packageAID: Data(),
        moduleAID: Data(),
        securityDomainAID: Data([0x40, 0x41]),
        securityDomainKeyInfo: Data(),
        lifeCycleState: Data(),
        instanceType: .groupApplication
    )
    precondition(info.securityDomainAID == Data([0x40, 0x41]))
}

func testSecurityDomainKeyInfo() {
    let key = Data([0x01, 0x02, 0x03, 0x04])
    let info = CredentialSession.Credential.InstanceInfo(
        instanceAID: Data(),
        packageAID: Data(),
        moduleAID: Data(),
        securityDomainAID: Data(),
        securityDomainKeyInfo: key,
        lifeCycleState: Data(),
        instanceType: .standalone
    )
    precondition(info.securityDomainKeyInfo == key)
}

func testLifeCycleState() {
    let info = CredentialSession.Credential.InstanceInfo(
        instanceAID: Data(),
        packageAID: Data(),
        moduleAID: Data(),
        securityDomainAID: Data(),
        securityDomainKeyInfo: Data(),
        lifeCycleState: Data([0x0F]),
        instanceType: .standalone
    )
    precondition(info.lifeCycleState == Data([0x0F]))
}

func testInstanceTypeProperty() {
    let info = CredentialSession.Credential.InstanceInfo(
        instanceAID: Data(),
        packageAID: Data(),
        moduleAID: Data(),
        securityDomainAID: Data(),
        securityDomainKeyInfo: Data(),
        lifeCycleState: Data(),
        instanceType: .groupApplication
    )
    precondition(info.instanceType == .groupApplication)
}

func testInstanceInfoEquality() {
    let make: () -> CredentialSession.Credential.InstanceInfo = {
        CredentialSession.Credential.InstanceInfo(
            instanceAID: Data([0x01]),
            packageAID: Data([0x02]),
            moduleAID: Data([0x03]),
            securityDomainAID: Data([0x04]),
            securityDomainKeyInfo: Data([0x05]),
            lifeCycleState: Data([0x06]),
            instanceType: .standalone
        )
    }
    precondition(make() == make())
    let other = CredentialSession.Credential.InstanceInfo(
        instanceAID: Data([0x99]),
        packageAID: Data([0x02]),
        moduleAID: Data([0x03]),
        securityDomainAID: Data([0x04]),
        securityDomainKeyInfo: Data([0x05]),
        lifeCycleState: Data([0x06]),
        instanceType: .standalone
    )
    precondition(make() != other)
}

func testInstanceInfoInequality() {
    let a = CredentialSession.Credential.InstanceInfo(
        instanceAID: Data([0x01]),
        packageAID: Data([0x02]),
        moduleAID: Data([0x03]),
        securityDomainAID: Data([0x04]),
        securityDomainKeyInfo: Data([0x05]),
        lifeCycleState: Data([0x06]),
        instanceType: .standalone
    )
    let b = CredentialSession.Credential.InstanceInfo(
        instanceAID: Data([0x01]),
        packageAID: Data([0x02]),
        moduleAID: Data([0x03]),
        securityDomainAID: Data([0x04]),
        securityDomainKeyInfo: Data([0x05]),
        lifeCycleState: Data([0x06]),
        instanceType: .headApplication
    )
    precondition(a != b)
    precondition(!(a != a))
}

func testInstanceTypeInequality() {
    precondition(
        CredentialSession.Credential.InstanceInfo.InstanceType.standalone
            != .groupApplication
    )
    precondition(
        !(CredentialSession.Credential.InstanceInfo.InstanceType.headApplication
            != .headApplication)
    )
}
