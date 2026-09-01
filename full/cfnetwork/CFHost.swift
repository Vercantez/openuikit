import CoreFoundation
import Foundation
#if canImport(Glibc)
import Glibc
#endif

public func CFHostGetTypeID() -> CFTypeID {
    CFNetworkTypeID.host
}

public func CFHostCreateWithName(
    _ allocator: CFAllocator?,
    _ hostname: CFString
) -> Unmanaged<CFHost> {
    _ = allocator
    let name = swiftString(hostname)
    return cfRetain(
        CFHost(
            names: [name],
            addresses: [],
            namesResolved: true,
            addressesResolved: false
        )
    )
}

public func CFHostCreateWithAddress(
    _ allocator: CFAllocator?,
    _ addr: CFData
) -> Unmanaged<CFHost> {
    _ = allocator
    return cfRetain(
        CFHost(
            names: [],
            addresses: [cfDataCopy(addr)],
            namesResolved: false,
            addressesResolved: true
        )
    )
}

public func CFHostCreateCopy(
    _ alloc: CFAllocator?,
    _ host: CFHost
) -> Unmanaged<CFHost> {
    _ = alloc
    host.lock.lock()
    defer { host.lock.unlock() }
    return cfRetain(
        CFHost(
            names: host.names,
            addresses: host.addresses.map(cfDataCopy),
            namesResolved: host.namesResolved,
            addressesResolved: host.addressesResolved
        )
    )
}

public func CFHostStartInfoResolution(
    _ theHost: CFHost,
    _ info: CFHostInfoType,
    _ error: UnsafeMutablePointer<CFStreamError>?
) -> Bool {
    theHost.lock.lock()
    if theHost.cancelled.contains(info) {
        theHost.cancelled.remove(info)
    }
    switch info {
    case .names:
        if theHost.namesResolved && !theHost.names.isEmpty {
            theHost.lock.unlock()
            cfInvokeHostClient(theHost, info: info, error: nil)
            return true
        }
        let addresses = theHost.addresses
        theHost.lock.unlock()
        let resolved = cfReverseLookup(addresses)
        theHost.lock.lock()
        if resolved.isEmpty {
            theHost.lock.unlock()
            cfWriteStreamError(
                error,
                domain: kCFStreamErrorDomainNetDB,
                code: CFNetworkErrors.cfHostErrorHostNotFound.rawValue
            )
            cfInvokeHostClient(theHost, info: info, error: error)
            return false
        }
        theHost.names = resolved
        theHost.namesResolved = true
        theHost.lock.unlock()
        cfInvokeHostClient(theHost, info: info, error: nil)
        return true
    case .addresses:
        if theHost.addressesResolved && !theHost.addresses.isEmpty {
            theHost.lock.unlock()
            cfInvokeHostClient(theHost, info: info, error: nil)
            return true
        }
        let names = theHost.names
        theHost.lock.unlock()
        let resolved = names.flatMap(cfLookupAddresses)
        theHost.lock.lock()
        if resolved.isEmpty {
            theHost.lock.unlock()
            cfWriteStreamError(
                error,
                domain: kCFStreamErrorDomainNetDB,
                code: CFNetworkErrors.cfHostErrorHostNotFound.rawValue
            )
            cfInvokeHostClient(theHost, info: info, error: error)
            return false
        }
        theHost.addresses = resolved
        theHost.addressesResolved = true
        theHost.lock.unlock()
        cfInvokeHostClient(theHost, info: info, error: nil)
        return true
    case .reachability:
        theHost.lock.unlock()
        cfWriteStreamError(
            error,
            domain: kCFStreamErrorDomainSystemConfiguration,
            code: CFNetworkErrors.cfHostErrorUnknown.rawValue
        )
        cfInvokeHostClient(theHost, info: info, error: error)
        return false
    }
}

public func CFHostCancelInfoResolution(_ theHost: CFHost, _ info: CFHostInfoType) {
    theHost.lock.lock()
    theHost.cancelled.insert(info)
    theHost.lock.unlock()
}

public func CFHostGetAddressing(
    _ theHost: CFHost,
    _ hasBeenResolved: UnsafeMutablePointer<DarwinBoolean>?
) -> Unmanaged<CFArray>? {
    theHost.lock.lock()
    defer { theHost.lock.unlock() }
    hasBeenResolved?.pointee = DarwinBoolean(theHost.addressesResolved)
    guard theHost.addressesResolved else { return nil }
    return cfRetain(cfDataArray(theHost.addresses))
}

public func CFHostGetNames(
    _ theHost: CFHost,
    _ hasBeenResolved: UnsafeMutablePointer<DarwinBoolean>?
) -> Unmanaged<CFArray>? {
    theHost.lock.lock()
    defer { theHost.lock.unlock() }
    hasBeenResolved?.pointee = DarwinBoolean(theHost.namesResolved)
    guard theHost.namesResolved else { return nil }
    return cfRetain(cfStringArray(theHost.names))
}

public func CFHostGetReachability(
    _ theHost: CFHost,
    _ hasBeenResolved: UnsafeMutablePointer<DarwinBoolean>?
) -> Unmanaged<CFData>? {
    theHost.lock.lock()
    defer { theHost.lock.unlock() }
    hasBeenResolved?.pointee = DarwinBoolean(theHost.reachabilityResolved)
    return nil
}

public func CFHostSetClient(
    _ theHost: CFHost,
    _ clientCB: CFHostClientCallBack?,
    _ clientContext: UnsafeMutablePointer<CFHostClientContext>?
) -> Bool {
    theHost.lock.lock()
    defer { theHost.lock.unlock() }
    cfReleaseContextInfo(theHost.clientRelease, info: theHost.clientInfo)
    theHost.client = clientCB
    if let clientContext {
        theHost.clientInfo = clientContext.pointee.info
        theHost.clientRelease = clientContext.pointee.release
        cfRetainContextInfo(clientContext.pointee.retain, info: clientContext.pointee.info)
    } else {
        theHost.clientInfo = nil
        theHost.clientRelease = nil
    }
    return true
}

public func CFHostScheduleWithRunLoop(
    _ theHost: CFHost,
    _ runLoop: CFRunLoop,
    _ runLoopMode: CFString
) {
    _ = runLoop
    _ = runLoopMode
    theHost.lock.lock()
    theHost.scheduled = true
    theHost.lock.unlock()
}

public func CFHostUnscheduleFromRunLoop(
    _ theHost: CFHost,
    _ runLoop: CFRunLoop,
    _ runLoopMode: CFString
) {
    _ = runLoop
    _ = runLoopMode
    theHost.lock.lock()
    theHost.scheduled = false
    theHost.lock.unlock()
}

private func cfInvokeHostClient(
    _ host: CFHost,
    info: CFHostInfoType,
    error: UnsafeMutablePointer<CFStreamError>?
) {
    host.lock.lock()
    let callback = host.client
    let callbackInfo = host.clientInfo
    host.lock.unlock()
    guard let callback else { return }
    if let error {
        callback(host, info, error, callbackInfo)
    } else {
        var none = CFStreamError(domain: 0, error: 0)
        callback(host, info, &none, callbackInfo)
    }
}

private func cfLookupAddresses(_ hostname: String) -> [CFData] {
    var hints = addrinfo()
    hints.ai_family = AF_UNSPEC
    hints.ai_socktype = Int32(SOCK_STREAM.rawValue)
    var result: UnsafeMutablePointer<addrinfo>?
    let status = hostname.withCString { cHost in
        getaddrinfo(cHost, nil, &hints, &result)
    }
    defer { if let result { freeaddrinfo(result) } }
    guard status == 0, let first = result else { return [] }
    var addresses: [CFData] = []
    var cursor: UnsafeMutablePointer<addrinfo>? = first
    while let info = cursor {
        if let addr = info.pointee.ai_addr {
            let length = Int(info.pointee.ai_addrlen)
            let bytes = UnsafeRawPointer(addr).bindMemory(to: UInt8.self, capacity: length)
            addresses.append(cfDataFromBytes(Array(UnsafeBufferPointer(start: bytes, count: length))))
        }
        cursor = info.pointee.ai_next
    }
    return addresses
}

private func cfReverseLookup(_ addresses: [CFData]) -> [String] {
    var names: [String] = []
    for address in addresses {
        let bytes = cfDataBytes(address)
        guard !bytes.isEmpty else { continue }
        let resolved: String? = bytes.withUnsafeBytes { raw in
            guard let base = raw.baseAddress else { return nil }
            var hostBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let status = getnameinfo(
                base.assumingMemoryBound(to: sockaddr.self),
                socklen_t(bytes.count),
                &hostBuffer,
                socklen_t(hostBuffer.count),
                nil,
                0,
                NI_NAMEREQD
            )
            guard status == 0 else { return nil }
            return String(cString: hostBuffer)
        }
        if let resolved {
            names.append(resolved)
        }
    }
    return names
}
