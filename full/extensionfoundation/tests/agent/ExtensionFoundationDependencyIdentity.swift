import ExtensionFoundation
import Foundation

// Isolated host-gate success against toolchain Foundation is not integrated
// guest-Foundation success. This probe is for a future clean EC2 run that
// builds guest Foundation first, then ExtensionFoundation with that `-I` / `-L`.
// The host gate does not compile this file.

func extensionFoundationDependencyIdentityProbe() {
    let tag = UUID()
    let label = tag.uuidString
    precondition(type(of: tag) == UUID.self)
    precondition(type(of: label) == String.self)
    precondition(!String(reflecting: type(of: tag)).hasPrefix("ExtensionFoundation."))
    precondition(!String(reflecting: type(of: label)).hasPrefix("ExtensionFoundation."))

    let point = AppExtensionPoint.Definition.buildBlock(
        AppExtensionPoint.Name("ef-dep-identity"),
        AppExtensionPoint.UserInterface(false)
    )
    precondition(point.id == "ef-dep-identity")
    precondition(type(of: point.id) == String.self)

    let handler = ConnectionHandler(onConnection: { connection in
        _ = connection.serviceName
        return true
    })
    precondition(handler.accept(connection: NSXPCConnection(serviceName: label)) == true)
}

#if EXTENSIONFOUNDATION_IDENTITY_MAIN
extensionFoundationDependencyIdentityProbe()
print("EXTENSIONFOUNDATION_DEPENDENCY_IDENTITY_OK")
#endif
