import CoreFoundation
import GSS

func gssDependencyIdentityProbe() {
    let cfName = "identity@EXAMPLE.COM".withCString { pointer in
        CFStringCreateWithCString(
            kCFAllocatorDefault,
            pointer,
            CFStringBuiltInEncodings.UTF8.rawValue
        )!
    }
    gssWithConstOID(gssNTUserNameOID) { oid in
        var error: Unmanaged<CFError>? = nil
        let name = GSSCreateName(cfName, oid, &error)
        gssRequire(name != nil, "CFString through GSSCreateName")
        let display = GSSNameCreateDisplayString(name!)
        gssRequire(display != nil, "CFString display")
        _ = display!.takeRetainedValue()
        let created = GSSCreateError(oid, OM_uint32(truncatingIfNeeded: GSS_S_NO_CRED), 0)
        gssRequire(created != nil, "CFError")
        gssRequire(CFErrorGetCode(created!.takeRetainedValue()) == CFIndex(GSS_S_NO_CRED), "code")
        var minor: OM_uint32 = 0
        var handle = name
        _ = gss_release_name(&minor, &handle)
    }
    _ = CFTimeInterval(0)
}

func testGSSDependencyIdentity() {
    gssDependencyIdentityProbe()
}

#if GSS_IDENTITY_MAIN
gssDependencyIdentityProbe()
print("GSS_DEPENDENCY_IDENTITY_OK")
#endif
