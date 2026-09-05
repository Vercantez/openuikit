import CoreFoundation
import Foundation

public func CFNetworkCopySystemProxySettings() -> Unmanaged<CFDictionary>? {
    cfRetain(cfMutableDictionary())
}

public func CFNetworkCopyProxiesForURL(
    _ url: CFURL,
    _ proxySettings: CFDictionary
) -> Unmanaged<CFArray> {
    _ = url
    _ = proxySettings
    return cfRetain(cfProxyArray(type: kCFProxyTypeNone, host: nil, port: nil))
}

public func CFNetworkCopyProxiesForAutoConfigurationScript(
    _ proxyAutoConfigurationScript: CFString,
    _ targetURL: CFURL,
    _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?
) -> Unmanaged<CFArray>? {
    _ = proxyAutoConfigurationScript
    _ = targetURL
    error?.pointee = cfRetain(cfNetworkError(.cfErrorPACFileError))
    return nil
}

public func CFNetworkExecuteProxyAutoConfigurationScript(
    _ proxyAutoConfigurationScript: CFString,
    _ targetURL: CFURL,
    _ cb: CFProxyAutoConfigurationResultCallback,
    _ clientContext: UnsafeMutablePointer<CFStreamClientContext>
) -> CFRunLoopSource {
    _ = proxyAutoConfigurationScript
    _ = targetURL
    if let retain = clientContext.pointee.retain, let info = clientContext.pointee.info {
        _ = retain(info)
    }
    cb(
        cfClientInfoPointer(clientContext.pointee.info),
        cfEmptyArray(),
        cfNetworkError(.cfErrorPACFileError)
    )
    if let release = clientContext.pointee.release, let info = clientContext.pointee.info {
        release(info)
    }
    return cfInertRunLoopSource()
}

public func CFNetworkExecuteProxyAutoConfigurationURL(
    _ proxyAutoConfigURL: CFURL,
    _ targetURL: CFURL,
    _ cb: CFProxyAutoConfigurationResultCallback,
    _ clientContext: UnsafeMutablePointer<CFStreamClientContext>
) -> CFRunLoopSource {
    _ = proxyAutoConfigURL
    _ = targetURL
    if let retain = clientContext.pointee.retain, let info = clientContext.pointee.info {
        _ = retain(info)
    }
    cb(
        cfClientInfoPointer(clientContext.pointee.info),
        cfEmptyArray(),
        cfNetworkError(.cfErrorPACFileError)
    )
    if let release = clientContext.pointee.release, let info = clientContext.pointee.info {
        release(info)
    }
    return cfInertRunLoopSource()
}

func cfProxyArray(type: CFString, host: CFString?, port: Int?) -> CFArray {
    let entry = cfMutableDictionary()
    cfDictionarySet(entry, key: kCFProxyTypeKey, value: type)
    if let host {
        cfDictionarySet(entry, key: kCFProxyHostNameKey, value: host)
    }
    if let port {
        cfDictionarySet(entry, key: kCFProxyPortNumberKey, value: cfNumber(port))
    }
    let array = cfMutableArray()
    cfArrayAppend(array, entry)
    return array
}
