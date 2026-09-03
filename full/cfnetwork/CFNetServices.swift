import CoreFoundation
import Foundation

public func CFNetServiceGetTypeID() -> CFTypeID {
    CFNetworkTypeID.netService
}

public func CFNetServiceBrowserGetTypeID() -> CFTypeID {
    CFNetworkTypeID.netServiceBrowser
}

public func CFNetServiceMonitorGetTypeID() -> CFTypeID {
    CFNetworkTypeID.netServiceMonitor
}

public func CFNetServiceCreate(
    _ alloc: CFAllocator?,
    _ domain: CFString,
    _ serviceType: CFString,
    _ name: CFString,
    _ port: Int32
) -> Unmanaged<CFNetService> {
    _ = alloc
    return cfRetain(
        CFNetService(
            domain: swiftString(domain),
            serviceType: swiftString(serviceType),
            name: swiftString(name),
            port: port
        )
    )
}

public func CFNetServiceCreateCopy(
    _ alloc: CFAllocator?,
    _ service: CFNetService
) -> Unmanaged<CFNetService> {
    _ = alloc
    service.lock.lock()
    defer { service.lock.unlock() }
    let copy = CFNetService(
        domain: service.domain,
        serviceType: service.serviceType,
        name: service.name,
        port: service.port
    )
    copy.txtRecord = service.txtRecord.map(cfDataCopy)
    copy.targetHost = service.targetHost
    copy.addresses = service.addresses.map(cfDataCopy)
    return cfRetain(copy)
}

public func CFNetServiceGetDomain(_ theService: CFNetService) -> Unmanaged<CFString> {
    theService.lock.lock()
    defer { theService.lock.unlock() }
    return cfRetain(cfString(theService.domain))
}

public func CFNetServiceGetType(_ theService: CFNetService) -> Unmanaged<CFString> {
    theService.lock.lock()
    defer { theService.lock.unlock() }
    return cfRetain(cfString(theService.serviceType))
}

public func CFNetServiceGetName(_ theService: CFNetService) -> Unmanaged<CFString> {
    theService.lock.lock()
    defer { theService.lock.unlock() }
    return cfRetain(cfString(theService.name))
}

public func CFNetServiceGetPortNumber(_ theService: CFNetService) -> Int32 {
    theService.lock.lock()
    defer { theService.lock.unlock() }
    return theService.port
}

public func CFNetServiceGetTargetHost(_ theService: CFNetService) -> Unmanaged<CFString>? {
    theService.lock.lock()
    defer { theService.lock.unlock() }
    guard let targetHost = theService.targetHost else { return nil }
    return cfRetain(cfString(targetHost))
}

public func CFNetServiceGetAddressing(_ theService: CFNetService) -> Unmanaged<CFArray>? {
    theService.lock.lock()
    defer { theService.lock.unlock() }
    guard !theService.addresses.isEmpty else { return nil }
    return cfRetain(cfDataArray(theService.addresses))
}

public func CFNetServiceGetTXTData(_ theService: CFNetService) -> Unmanaged<CFData>? {
    theService.lock.lock()
    defer { theService.lock.unlock() }
    guard let txtRecord = theService.txtRecord else { return nil }
    return cfRetain(cfDataCopy(txtRecord))
}

public func CFNetServiceSetTXTData(_ theService: CFNetService, _ txtRecord: CFData) -> Bool {
    theService.lock.lock()
    defer { theService.lock.unlock() }
    theService.txtRecord = cfDataCopy(txtRecord)
    return true
}

public func CFNetServiceCreateDictionaryWithTXTData(
    _ alloc: CFAllocator?,
    _ txtRecord: CFData
) -> Unmanaged<CFDictionary>? {
    _ = alloc
    let bytes = cfDataBytes(txtRecord)
    var index = 0
    let dictionary = cfMutableDictionary()
    while index < bytes.count {
        let length = Int(bytes[index])
        index += 1
        guard index + length <= bytes.count else { return nil }
        let chunk = bytes[index..<(index + length)]
        index += length
        guard let text = String(bytes: chunk, encoding: .utf8) else { return nil }
        if let separator = text.firstIndex(of: "=") {
            let key = String(text[..<separator])
            let value = String(text[text.index(after: separator)...])
            cfDictionarySet(
                dictionary,
                key: cfString(key),
                value: cfDataFromBytes(Array(value.utf8))
            )
        } else {
            cfDictionarySet(dictionary, key: cfString(text), value: cfDataFromBytes([]))
        }
    }
    return cfRetain(dictionary)
}

public func CFNetServiceCreateTXTDataWithDictionary(
    _ alloc: CFAllocator?,
    _ keyValuePairs: CFDictionary
) -> Unmanaged<CFData>? {
    _ = alloc
    let count = Int(CFDictionaryGetCount(keyValuePairs))
    var keys = Array<UnsafeRawPointer?>(repeating: nil, count: count)
    var values = Array<UnsafeRawPointer?>(repeating: nil, count: count)
    keys.withUnsafeMutableBufferPointer { keyBuffer in
        values.withUnsafeMutableBufferPointer { valueBuffer in
            CFDictionaryGetKeysAndValues(keyValuePairs, keyBuffer.baseAddress, valueBuffer.baseAddress)
        }
    }
    var record: [UInt8] = []
    for offset in 0..<count {
        guard let keyPointer = keys[offset], let valuePointer = values[offset] else { return nil }
        let key = swiftString(Unmanaged<CFString>.fromOpaque(keyPointer).takeUnretainedValue())
        let valueData = Unmanaged<CFData>.fromOpaque(valuePointer).takeUnretainedValue()
        let valueBytes = cfDataBytes(valueData)
        var chunk = Array(key.utf8)
        if !valueBytes.isEmpty {
            chunk.append(UInt8(ascii: "="))
            chunk.append(contentsOf: valueBytes)
        }
        guard chunk.count <= 255 else { return nil }
        record.append(UInt8(chunk.count))
        record.append(contentsOf: chunk)
    }
    return cfRetain(cfDataFromBytes(record))
}

public func CFNetServiceRegisterWithOptions(
    _ theService: CFNetService,
    _ options: CFOptionFlags,
    _ error: UnsafeMutablePointer<CFStreamError>?
) -> Bool {
    _ = theService
    _ = options
    cfWriteStreamError(
        error,
        domain: kCFStreamErrorDomainNetServices,
        code: CFNetServicesError.unknown.rawValue
    )
    return false
}

public func CFNetServiceResolveWithTimeout(
    _ theService: CFNetService,
    _ timeout: CFTimeInterval,
    _ error: UnsafeMutablePointer<CFStreamError>?
) -> Bool {
    _ = theService
    _ = timeout
    cfWriteStreamError(
        error,
        domain: kCFStreamErrorDomainNetServices,
        code: CFNetServicesError.unknown.rawValue
    )
    return false
}

public func CFNetServiceCancel(_ theService: CFNetService) {
    theService.lock.lock()
    theService.invalidated = true
    theService.lock.unlock()
}

public func CFNetServiceSetClient(
    _ theService: CFNetService,
    _ clientCB: CFNetServiceClientCallBack?,
    _ clientContext: UnsafeMutablePointer<CFNetServiceClientContext>?
) -> Bool {
    theService.lock.lock()
    defer { theService.lock.unlock() }
    cfReleaseContextInfo(theService.clientRelease, info: theService.clientInfo)
    theService.client = clientCB
    if let clientContext {
        theService.clientInfo = clientContext.pointee.info
        theService.clientRelease = clientContext.pointee.release
        cfRetainContextInfo(clientContext.pointee.retain, info: clientContext.pointee.info)
    } else {
        theService.clientInfo = nil
        theService.clientRelease = nil
    }
    return true
}

public func CFNetServiceScheduleWithRunLoop(
    _ theService: CFNetService,
    _ runLoop: CFRunLoop,
    _ runLoopMode: CFString
) {
    _ = runLoop
    _ = runLoopMode
    theService.lock.lock()
    theService.scheduled = true
    theService.lock.unlock()
}

public func CFNetServiceUnscheduleFromRunLoop(
    _ theService: CFNetService,
    _ runLoop: CFRunLoop,
    _ runLoopMode: CFString
) {
    _ = runLoop
    _ = runLoopMode
    theService.lock.lock()
    theService.scheduled = false
    theService.lock.unlock()
}

public func CFNetServiceBrowserCreate(
    _ alloc: CFAllocator?,
    _ clientCB: @escaping CFNetServiceBrowserClientCallBack,
    _ clientContext: UnsafeMutablePointer<CFNetServiceClientContext>
) -> Unmanaged<CFNetServiceBrowser> {
    _ = alloc
    cfRetainContextInfo(clientContext.pointee.retain, info: clientContext.pointee.info)
    return cfRetain(
        CFNetServiceBrowser(
            client: clientCB,
            info: clientContext.pointee.info,
            release: clientContext.pointee.release
        )
    )
}

public func CFNetServiceBrowserInvalidate(_ browser: CFNetServiceBrowser) {
    browser.lock.lock()
    browser.invalidated = true
    browser.searching = false
    browser.lock.unlock()
}

public func CFNetServiceBrowserScheduleWithRunLoop(
    _ browser: CFNetServiceBrowser,
    _ runLoop: CFRunLoop,
    _ runLoopMode: CFString
) {
    _ = runLoop
    _ = runLoopMode
    browser.lock.lock()
    browser.scheduled = true
    browser.lock.unlock()
}

public func CFNetServiceBrowserUnscheduleFromRunLoop(
    _ browser: CFNetServiceBrowser,
    _ runLoop: CFRunLoop,
    _ runLoopMode: CFString
) {
    _ = runLoop
    _ = runLoopMode
    browser.lock.lock()
    browser.scheduled = false
    browser.lock.unlock()
}

public func CFNetServiceBrowserSearchForDomains(
    _ browser: CFNetServiceBrowser,
    _ registrationDomains: Bool,
    _ error: UnsafeMutablePointer<CFStreamError>?
) -> Bool {
    _ = registrationDomains
    browser.lock.lock()
    let invalidated = browser.invalidated
    browser.lock.unlock()
    if invalidated {
        cfWriteStreamError(
            error,
            domain: kCFStreamErrorDomainNetServices,
            code: CFNetServicesError.invalid.rawValue
        )
        return false
    }
    cfWriteStreamError(
        error,
        domain: kCFStreamErrorDomainNetServices,
        code: CFNetServicesError.unknown.rawValue
    )
    return false
}

public func CFNetServiceBrowserSearchForServices(
    _ browser: CFNetServiceBrowser,
    _ domain: CFString,
    _ serviceType: CFString,
    _ error: UnsafeMutablePointer<CFStreamError>?
) -> Bool {
    _ = domain
    _ = serviceType
    browser.lock.lock()
    let invalidated = browser.invalidated
    browser.lock.unlock()
    if invalidated {
        cfWriteStreamError(
            error,
            domain: kCFStreamErrorDomainNetServices,
            code: CFNetServicesError.invalid.rawValue
        )
        return false
    }
    cfWriteStreamError(
        error,
        domain: kCFStreamErrorDomainNetServices,
        code: CFNetServicesError.unknown.rawValue
    )
    return false
}

public func CFNetServiceBrowserStopSearch(
    _ browser: CFNetServiceBrowser,
    _ error: UnsafeMutablePointer<CFStreamError>?
) {
    _ = error
    browser.lock.lock()
    browser.searching = false
    browser.lock.unlock()
}

public func CFNetServiceMonitorCreate(
    _ alloc: CFAllocator?,
    _ theService: CFNetService,
    _ clientCB: @escaping CFNetServiceMonitorClientCallBack,
    _ clientContext: UnsafeMutablePointer<CFNetServiceClientContext>
) -> Unmanaged<CFNetServiceMonitor> {
    _ = alloc
    cfRetainContextInfo(clientContext.pointee.retain, info: clientContext.pointee.info)
    return cfRetain(
        CFNetServiceMonitor(
            service: theService,
            client: clientCB,
            info: clientContext.pointee.info,
            release: clientContext.pointee.release
        )
    )
}

public func CFNetServiceMonitorInvalidate(_ monitor: CFNetServiceMonitor) {
    monitor.lock.lock()
    monitor.invalidated = true
    monitor.running = false
    monitor.lock.unlock()
}

public func CFNetServiceMonitorScheduleWithRunLoop(
    _ monitor: CFNetServiceMonitor,
    _ runLoop: CFRunLoop,
    _ runLoopMode: CFString
) {
    _ = runLoop
    _ = runLoopMode
    monitor.lock.lock()
    monitor.scheduled = true
    monitor.lock.unlock()
}

public func CFNetServiceMonitorUnscheduleFromRunLoop(
    _ monitor: CFNetServiceMonitor,
    _ runLoop: CFRunLoop,
    _ runLoopMode: CFString
) {
    _ = runLoop
    _ = runLoopMode
    monitor.lock.lock()
    monitor.scheduled = false
    monitor.lock.unlock()
}

public func CFNetServiceMonitorStart(
    _ monitor: CFNetServiceMonitor,
    _ recordType: CFNetServiceMonitorType,
    _ error: UnsafeMutablePointer<CFStreamError>?
) -> Bool {
    _ = recordType
    monitor.lock.lock()
    let invalidated = monitor.invalidated
    monitor.lock.unlock()
    if invalidated {
        cfWriteStreamError(
            error,
            domain: kCFStreamErrorDomainNetServices,
            code: CFNetServicesError.invalid.rawValue
        )
        return false
    }
    cfWriteStreamError(
        error,
        domain: kCFStreamErrorDomainNetServices,
        code: CFNetServicesError.unknown.rawValue
    )
    return false
}

public func CFNetServiceMonitorStop(
    _ monitor: CFNetServiceMonitor,
    _ error: UnsafeMutablePointer<CFStreamError>?
) {
    _ = error
    monitor.lock.lock()
    monitor.running = false
    monitor.lock.unlock()
}
