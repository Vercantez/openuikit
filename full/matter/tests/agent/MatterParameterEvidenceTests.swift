import Foundation
import Matter

// Local evidence repair: exercise parameter storage directly. These tests
// establish host behavior, not Apple defaults, certificate validation, or
// radio/service success. All inputs are local and every test returns inline.
func testAbstractParametersSuspensionStorage() {
    let parameters = MTRDeviceControllerAbstractParameters()
    parameters.startSuspended = true
    mtrRequire(parameters.startSuspended, "suspension flag stores true")
    parameters.startSuspended = false
    mtrRequire(!parameters.startSuspended, "suspension flag stores false")
}

func testControllerParameterCertificateStorage() {
    let parameters = MTRDeviceControllerParameters()
    let other = MTRDeviceControllerParameters()
    let declaration = [Data([0x01, 0x02]), Data([0x03])]
    let authorities = [Data([0x04, 0x05])]
    other.certificationDeclarationCertificates = []
    other.productAttestationAuthorityCertificates = []
    parameters.certificationDeclarationCertificates = declaration
    parameters.productAttestationAuthorityCertificates = authorities
    mtrRequire(parameters.certificationDeclarationCertificates == declaration, "declaration bytes round trip")
    mtrRequire(parameters.productAttestationAuthorityCertificates == authorities, "authority bytes round trip")
    mtrRequire(other.certificationDeclarationCertificates == [], "declarations are instance local")
    mtrRequire(other.productAttestationAuthorityCertificates == [], "authorities are instance local")
    parameters.certificationDeclarationCertificates = nil
    parameters.productAttestationAuthorityCertificates = nil
    mtrRequire(parameters.certificationDeclarationCertificates == nil, "clear declarations")
    mtrRequire(parameters.productAttestationAuthorityCertificates == nil, "clear authorities")
}

func testFactoryParameterCertificateStorage() {
    let parameters = MTRDeviceControllerFactoryParams()
    let declaration = [Data([0x11, 0x12])]
    let authorities = [Data([0x13]), Data([0x14, 0x15])]
    parameters.certificationDeclarationCertificates = declaration
    parameters.productAttestationAuthorityCertificates = authorities
    mtrRequire(parameters.certificationDeclarationCertificates == declaration, "factory declaration bytes round trip")
    mtrRequire(parameters.productAttestationAuthorityCertificates == authorities, "factory authority bytes round trip")
    parameters.certificationDeclarationCertificates = []
    parameters.productAttestationAuthorityCertificates = nil
    mtrRequire(parameters.certificationDeclarationCertificates == [], "empty declarations remain distinct from nil")
    mtrRequire(parameters.productAttestationAuthorityCertificates == nil, "clear factory authorities")
}

func testFactoryParameterOTADelegateStorage() {
    final class Delegate: NSObject, MTROTAProviderDelegate {}
    let parameters = MTRDeviceControllerFactoryParams()
    let delegate = Delegate()
    parameters.otaProviderDelegate = delegate
    mtrRequire((parameters.otaProviderDelegate as AnyObject?) === delegate, "factory stores supplied delegate")
    parameters.otaProviderDelegate = nil
    mtrRequire(parameters.otaProviderDelegate == nil, "factory clears supplied delegate")
}

func testControllerParameterOperationalFlags() {
    let parameters = MTRDeviceControllerParameters()
    parameters.shouldAdvertiseOperational = true
    parameters.concurrentSubscriptionEstablishmentsAllowedOnThread = 3
    mtrRequire(parameters.shouldAdvertiseOperational, "store advertisement flag")
    mtrRequire(parameters.concurrentSubscriptionEstablishmentsAllowedOnThread == 3, "store subscription limit")
    parameters.shouldAdvertiseOperational = false
    parameters.concurrentSubscriptionEstablishmentsAllowedOnThread = 1
    mtrRequire(!parameters.shouldAdvertiseOperational, "clear advertisement flag")
    mtrRequire(parameters.concurrentSubscriptionEstablishmentsAllowedOnThread == 1, "replace subscription limit")
}

func testControllerParameterStorageConfiguration() {
    let parameters = MTRDeviceControllerParameters()
    let configuration = MTRDeviceStorageBehaviorConfiguration()
    configuration.disableStorageBehaviorOptimization = true
    parameters.storageBehaviorConfiguration = configuration
    mtrRequire(parameters.storageBehaviorConfiguration?.disableStorageBehaviorOptimization == true, "store configuration value")
    parameters.storageBehaviorConfiguration = nil
    mtrRequire(parameters.storageBehaviorConfiguration == nil, "clear configuration")
}
