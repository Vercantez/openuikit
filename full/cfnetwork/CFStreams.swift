import CoreFoundation
import Foundation

public func CFReadStreamCreateForHTTPRequest(
    _ alloc: CFAllocator?,
    _ request: CFHTTPMessage
) -> Unmanaged<CFReadStream> {
    _ = alloc
    _ = request
    return cfRetain(cfInertReadStream())
}

public func CFReadStreamCreateForStreamedHTTPRequest(
    _ alloc: CFAllocator?,
    _ requestHeaders: CFHTTPMessage,
    _ requestBody: CFReadStream
) -> Unmanaged<CFReadStream> {
    _ = alloc
    _ = requestHeaders
    _ = requestBody
    return cfRetain(cfInertReadStream())
}

public func CFReadStreamCreateWithFTPURL(
    _ alloc: CFAllocator?,
    _ ftpURL: CFURL
) -> Unmanaged<CFReadStream> {
    _ = alloc
    _ = ftpURL
    return cfRetain(cfInertReadStream())
}

public func CFWriteStreamCreateWithFTPURL(
    _ alloc: CFAllocator?,
    _ ftpURL: CFURL
) -> Unmanaged<CFWriteStream> {
    _ = alloc
    _ = ftpURL
    return cfRetain(cfInertWriteStream())
}

public func CFStreamCreatePairWithSocketToCFHost(
    _ alloc: CFAllocator?,
    _ host: CFHost,
    _ port: Int32,
    _ readStream: UnsafeMutablePointer<Unmanaged<CFReadStream>?>?,
    _ writeStream: UnsafeMutablePointer<Unmanaged<CFWriteStream>?>?
) {
    _ = alloc
    _ = host
    _ = port
    readStream?.pointee = cfRetain(cfInertReadStream())
    writeStream?.pointee = cfRetain(cfInertWriteStream())
}

public func CFStreamCreatePairWithSocketToNetService(
    _ alloc: CFAllocator?,
    _ service: CFNetService,
    _ readStream: UnsafeMutablePointer<Unmanaged<CFReadStream>?>?,
    _ writeStream: UnsafeMutablePointer<Unmanaged<CFWriteStream>?>?
) {
    _ = alloc
    _ = service
    readStream?.pointee = cfRetain(cfInertReadStream())
    writeStream?.pointee = cfRetain(cfInertWriteStream())
}

public func CFSocketStreamSOCKSGetError(_ error: UnsafePointer<CFStreamError>) -> Int32 {
    error.pointee.error
}

public func CFSocketStreamSOCKSGetErrorSubdomain(_ error: UnsafePointer<CFStreamError>) -> Int32 {
    if error.pointee.domain == CFIndex(kCFStreamErrorDomainSOCKSFallback) {
        return Int32(kCFStreamErrorSOCKSSubDomainNone)
    }
    return Int32(kCFStreamErrorSOCKSSubDomainNone)
}

let kCFStreamErrorDomainSOCKSFallback: Int32 = 5
