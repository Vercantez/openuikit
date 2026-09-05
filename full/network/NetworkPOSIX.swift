import Foundation
#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

/// POSIX sockets, `getifaddrs`, and `/proc/net/route` for the Linux Network overlay.
/// Isolated host compile imports Glibc; Darwin is the other supported libc.
enum NWPOSIX {
    /// SecureTransport `errSSLProtocol`. Linux has no TLS stack; TLS parameters
    /// fail closed with `NWError.tls` carrying this code.
    static let tlsUnsupportedStatus: OSStatus = -9800

    static func interfaceForZone(_ zone: String) -> NWInterface {
        let index = Int(if_nametoindex(zone))
        return NWInterface(name: zone, type: .other, index: index)
    }

    static var streamSocketType: Int32 {
        #if canImport(Glibc)
        return Int32(SOCK_STREAM.rawValue)
        #else
        return SOCK_STREAM
        #endif
    }

    static var datagramSocketType: Int32 {
        #if canImport(Glibc)
        return Int32(SOCK_DGRAM.rawValue)
        #else
        return SOCK_DGRAM
        #endif
    }

    static let queueKey = DispatchSpecificKey<UInt8>()

    static func tag(_ queue: DispatchQueue) {
        queue.setSpecific(key: queueKey, value: 1)
    }

    static func run(_ queue: DispatchQueue?, _ body: () -> Void) {
        guard let queue else {
            body()
            return
        }
        if DispatchQueue.getSpecific(key: queueKey) != nil {
            body()
        } else {
            queue.sync(execute: body)
        }
    }

    static var cancelledError: NWError {
        if let code = POSIXErrorCode(rawValue: ECANCELED) {
            return .posix(code)
        }
        return .posix(.EINTR)
    }

    static var notConnectedError: NWError {
        if let code = POSIXErrorCode(rawValue: ENOTCONN) {
            return .posix(code)
        }
        return .posix(.EPIPE)
    }

    static func closeFD(_ fd: Int32) {
        if fd >= 0 {
            _ = close(fd)
        }
    }

    static func lastPOSIXError() -> NWError {
        let code = POSIXErrorCode(rawValue: errno) ?? .EIO
        return .posix(code)
    }

    static func lastDNSError(_ status: Int32) -> NWError {
        .dns(status)
    }

    struct InterfaceRecord: Sendable {
        var interface: NWInterface
        var hasIPv4: Bool
        var hasIPv6: Bool
        var hasAddress: Bool { hasIPv4 || hasIPv6 }
    }

    /// Classify from `getifaddrs` name + `IFF_LOOPBACK`. Wi-Fi versus ethernet is a
    /// name-prefix heuristic (Linux `wlan*`/`eth*`); Apple's SCNetwork type for
    /// macOS `en0` is unobserved and recorded as an oracle question.
    static func classifyInterface(name: String, flags: UInt32) -> NWInterface.InterfaceType {
        if (flags & UInt32(IFF_LOOPBACK)) != 0 {
            return .loopback
        }
        if name.hasPrefix("lo") {
            return .loopback
        }
        if name.hasPrefix("wlan") || name.hasPrefix("wl") || name.hasPrefix("awdl") {
            return .wifi
        }
        if name.hasPrefix("eth") || name.hasPrefix("en") || name.hasPrefix("em") {
            return .wiredEthernet
        }
        return .other
    }

    static func snapshotInterfaces() -> [InterfaceRecord] {
        var head: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&head) == 0, let first = head else { return [] }
        defer { freeifaddrs(first) }

        var ordered: [String] = []
        var byName: [String: InterfaceRecord] = [:]
        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let current = cursor {
            let name = String(cString: current.pointee.ifa_name)
            let flags = UInt32(current.pointee.ifa_flags)
            let index = Int(if_nametoindex(name))
            let type = classifyInterface(name: name, flags: flags)
            if byName[name] == nil {
                ordered.append(name)
                byName[name] = InterfaceRecord(
                    interface: NWInterface(name: name, type: type, index: index),
                    hasIPv4: false,
                    hasIPv6: false
                )
            }
            if let addr = current.pointee.ifa_addr {
                let family = Int32(addr.pointee.sa_family)
                if family == Int32(AF_INET) {
                    byName[name]?.hasIPv4 = true
                } else if family == Int32(AF_INET6) {
                    byName[name]?.hasIPv6 = true
                }
            }
            cursor = current.pointee.ifa_next
        }
        return ordered.compactMap { byName[$0] }
    }

    /// Default IPv4 gateway from `/proc/net/route` when that file is readable.
    /// Destination `00000000` with `RTF_GATEWAY` (0x2) is the default route;
    /// the Gateway column is little-endian hex (Linux `rtentry`).
    static func procNetRouteGateways() -> [NWEndpoint] {
        let path = "/proc/net/route"
        guard let contents = try? String(contentsOfFile: path, encoding: .utf8) else {
            return []
        }
        var gateways: [NWEndpoint] = []
        var isHeader = true
        for line in contents.split(whereSeparator: { $0 == "\n" }) {
            if isHeader {
                isHeader = false
                continue
            }
            let columns = line.split(whereSeparator: { $0 == " " || $0 == "\t" })
            guard columns.count >= 4 else { continue }
            let destination = String(columns[1])
            let gatewayHex = String(columns[2])
            guard destination == "00000000" else { continue }
            guard let flags = UInt32(String(columns[3]), radix: 16), (flags & 0x2) != 0 else {
                continue
            }
            guard let address = ipv4FromLittleEndianHex(gatewayHex) else { continue }
            gateways.append(.hostPort(host: .ipv4(address), port: .any))
        }
        return gateways
    }

    static func ipv4FromLittleEndianHex(_ hex: String) -> IPv4Address? {
        guard let value = UInt32(hex, radix: 16) else { return nil }
        let bytes = [
            UInt8(truncatingIfNeeded: value),
            UInt8(truncatingIfNeeded: value >> 8),
            UInt8(truncatingIfNeeded: value >> 16),
            UInt8(truncatingIfNeeded: value >> 24)
        ]
        return IPv4Address(Data(bytes))
    }

    static func makePath(
        required: NWInterface.InterfaceType?,
        prohibited: [NWInterface.InterfaceType]
    ) -> NWPath {
        let records = snapshotInterfaces()
        let filtered = records.filter { record in
            if let required, record.interface.type != required {
                return false
            }
            if prohibited.contains(record.interface.type) {
                return false
            }
            return true
        }
        let interfaces = filtered.map(\.interface)
        let supportsIPv4 = filtered.contains { $0.hasIPv4 }
        let supportsIPv6 = filtered.contains { $0.hasIPv6 }
        let satisfied = filtered.contains { record in
            record.interface.type != .loopback && record.hasAddress
        }
        return NWPath(
            status: satisfied ? .satisfied : .unsatisfied,
            availableInterfaces: interfaces,
            isExpensive: false,
            isConstrained: false,
            supportsIPv4: supportsIPv4,
            supportsIPv6: supportsIPv6,
            supportsDNS: satisfied,
            unsatisfiedReason: satisfied ? .notAvailable : .notAvailable,
            localEndpoint: nil,
            remoteEndpoint: nil,
            gateways: procNetRouteGateways()
        )
    }

    static func isUDP(_ parameters: NWParameters) -> Bool {
        parameters.defaultProtocolStack.transportProtocol is NWProtocolUDP.Options
    }

    static func wantsTLS(_ parameters: NWParameters) -> Bool {
        if parameters.tlsOptions != nil { return true }
        return parameters.defaultProtocolStack.applicationProtocols.contains { $0 is NWProtocolTLS.Options }
    }

    static func makeSocket(udp: Bool) -> Int32? {
        let fd = socket(Int32(AF_INET), udp ? datagramSocketType : streamSocketType, 0)
        return fd >= 0 ? fd : nil
    }

    static func makeUnixSocket(udp: Bool) -> Int32? {
        let fd = socket(Int32(AF_UNIX), udp ? datagramSocketType : streamSocketType, 0)
        return fd >= 0 ? fd : nil
    }

    static func setReuseAddr(_ fd: Int32) {
        var yes: Int32 = 1
        _ = setsockopt(fd, Int32(SOL_SOCKET), Int32(SO_REUSEADDR), &yes, socklen_t(MemoryLayout<Int32>.size))
    }

    static func applyTCPOptions(_ fd: Int32, _ options: NWProtocolTCP.Options) {
        if options.noDelay {
            var yes: Int32 = 1
            _ = setsockopt(fd, Int32(IPPROTO_TCP), Int32(TCP_NODELAY), &yes, socklen_t(MemoryLayout<Int32>.size))
        }
    }

    static func bindLoopback(fd: Int32, port: UInt16) -> UInt16? {
        var addr = sockaddr_in()
        #if canImport(Darwin)
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        #endif
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = port.bigEndian
        let loopback = IPv4Address.loopback.rawValue
        addr.sin_addr = in_addr(s_addr: ipv4SAddr(loopback))
        let bound = withUnsafePointer(to: &addr) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                bind(fd, sa, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard bound == 0 else { return nil }
        return assignedPort(fd: fd)
    }

    static func assignedPort(fd: Int32) -> UInt16? {
        var addr = sockaddr_in()
        var length = socklen_t(MemoryLayout<sockaddr_in>.size)
        let rc = withUnsafeMutablePointer(to: &addr) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                getsockname(fd, sa, &length)
            }
        }
        guard rc == 0 else { return nil }
        return UInt16(bigEndian: addr.sin_port)
    }

    static func listenTCP(_ fd: Int32) -> Bool {
        listen(fd, Int32(16)) == 0
    }

    static func ipv4SAddr(_ raw: Data) -> in_addr_t {
        raw.withUnsafeBytes { buffer in
            buffer.load(as: UInt32.self)
        }
    }

    static func connectIPv4(fd: Int32, address: IPv4Address, port: UInt16) -> NWError? {
        var addr = sockaddr_in()
        #if canImport(Darwin)
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        #endif
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = port.bigEndian
        addr.sin_addr = in_addr(s_addr: ipv4SAddr(address.rawValue))
        let rc = withUnsafePointer(to: &addr) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                connect(fd, sa, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        return rc == 0 ? nil : lastPOSIXError()
    }

    /// IPv6 connect that replaces `fd` via the inout parameter when AF_INET6 is required.
    static func connectIPv6Replacing(fd: inout Int32, address: IPv6Address, port: UInt16, udp: Bool) -> NWError? {
        let replacement = socket(Int32(AF_INET6), udp ? datagramSocketType : streamSocketType, 0)
        guard replacement >= 0 else { return lastPOSIXError() }
        closeFD(fd)
        fd = replacement
        var addr = sockaddr_in6()
        #if canImport(Darwin)
        addr.sin6_len = UInt8(MemoryLayout<sockaddr_in6>.size)
        #endif
        addr.sin6_family = sa_family_t(AF_INET6)
        addr.sin6_port = port.bigEndian
        if let index = address.interface?.index {
            addr.sin6_scope_id = UInt32(index)
        }
        _ = withUnsafeMutableBytes(of: &addr.sin6_addr) { dest in
            address.rawValue.copyBytes(to: dest)
        }
        let rc = withUnsafePointer(to: &addr) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                connect(fd, sa, socklen_t(MemoryLayout<sockaddr_in6>.size))
            }
        }
        return rc == 0 ? nil : lastPOSIXError()
    }

    static func connectUnix(fd: Int32, path: String) -> NWError? {
        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let utf8 = Array(path.utf8)
        let maxPath = MemoryLayout.size(ofValue: addr.sun_path) - 1
        guard utf8.count <= maxPath else { return .posix(.ENAMETOOLONG) }
        withUnsafeMutableBytes(of: &addr.sun_path) { dest in
            for (index, byte) in utf8.enumerated() {
                dest[index] = byte
            }
            dest[utf8.count] = 0
        }
        let rc = withUnsafePointer(to: &addr) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                connect(fd, sa, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        return rc == 0 ? nil : lastPOSIXError()
    }

    static func resolveHost(_ host: NWEndpoint.Host) -> (IPv4Address?, IPv6Address?, NWError?) {
        switch host {
        case .ipv4(let address):
            return (address, nil, nil)
        case .ipv6(let address):
            return (nil, address, nil)
        case .name(let name, _):
            return resolveName(name)
        }
    }

    static func resolveName(_ name: String) -> (IPv4Address?, IPv6Address?, NWError?) {
        var hints = addrinfo()
        hints.ai_family = Int32(AF_UNSPEC)
        hints.ai_socktype = streamSocketType
        var result: UnsafeMutablePointer<addrinfo>?
        let status = name.withCString { cName in
            getaddrinfo(cName, nil, &hints, &result)
        }
        defer { if let result { freeaddrinfo(result) } }
        guard status == 0, let first = result else {
            return (nil, nil, lastDNSError(status))
        }
        var v4: IPv4Address?
        var v6: IPv6Address?
        var cursor: UnsafeMutablePointer<addrinfo>? = first
        while let info = cursor {
            if let addr = info.pointee.ai_addr {
                let family = Int32(addr.pointee.sa_family)
                if family == Int32(AF_INET), v4 == nil {
                    addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { sin in
                        var bytes = Data(count: 4)
                        bytes.withUnsafeMutableBytes { dest in
                            var saddr = sin.pointee.sin_addr.s_addr
                            withUnsafeBytes(of: &saddr) { src in
                                dest.copyBytes(from: src)
                            }
                        }
                        v4 = IPv4Address(bytes)
                    }
                } else if family == Int32(AF_INET6), v6 == nil {
                    addr.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) { sin6 in
                        var bytes = Data(count: 16)
                        bytes.withUnsafeMutableBytes { dest in
                            withUnsafeBytes(of: sin6.pointee.sin6_addr) { src in
                                dest.copyBytes(from: src)
                            }
                        }
                        v6 = IPv6Address(bytes)
                    }
                }
            }
            cursor = info.pointee.ai_next
        }
        if v4 == nil && v6 == nil {
            return (nil, nil, .dns(Int32(EAI_NONAME)))
        }
        return (v4, v6, nil)
    }

    static func sendBytes(fd: Int32, data: Data) -> NWError? {
        if data.isEmpty { return nil }
        let sent: Int = data.withUnsafeBytes { buffer in
            guard let base = buffer.baseAddress else { return 0 }
            #if canImport(Glibc)
            return send(fd, base, buffer.count, Int32(MSG_NOSIGNAL))
            #else
            return send(fd, base, buffer.count, 0)
            #endif
        }
        if sent < 0 { return lastPOSIXError() }
        return nil
    }

    static func recvBytes(fd: Int32, maximumLength: Int) -> (Data?, Bool, NWError?) {
        if maximumLength <= 0 {
            return (Data(), false, nil)
        }
        var buffer = [UInt8](repeating: 0, count: maximumLength)
        let received = recv(fd, &buffer, maximumLength, 0)
        if received < 0 {
            return (nil, false, lastPOSIXError())
        }
        if received == 0 {
            return (Data(), true, nil)
        }
        return (Data(buffer.prefix(received)), false, nil)
    }

    struct Accepted {
        var fd: Int32
        var endpoint: NWEndpoint
        var firstDatagram: Data?
    }

    static func acceptTCP(listenFD: Int32) -> Accepted? {
        var addr = sockaddr_in()
        var length = socklen_t(MemoryLayout<sockaddr_in>.size)
        let client = withUnsafeMutablePointer(to: &addr) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                accept(listenFD, sa, &length)
            }
        }
        guard client >= 0 else { return nil }
        var bytes = Data(count: 4)
        bytes.withUnsafeMutableBytes { dest in
            var saddr = addr.sin_addr.s_addr
            withUnsafeBytes(of: &saddr) { src in
                dest.copyBytes(from: src)
            }
        }
        let host: NWEndpoint.Host
        if let address = IPv4Address(bytes) {
            host = .ipv4(address)
        } else {
            host = .name("127.0.0.1", nil)
        }
        let port = NWEndpoint.Port(integerLiteral: UInt16(bigEndian: addr.sin_port))
        return Accepted(fd: client, endpoint: .hostPort(host: host, port: port), firstDatagram: nil)
    }

    static func recvFromUDP(listenFD: Int32) -> Accepted? {
        var addr = sockaddr_in()
        var length = socklen_t(MemoryLayout<sockaddr_in>.size)
        var buffer = [UInt8](repeating: 0, count: 65535)
        let received = withUnsafeMutablePointer(to: &addr) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                recvfrom(listenFD, &buffer, buffer.count, 0, sa, &length)
            }
        }
        guard received >= 0 else { return nil }
        guard let fd = makeSocket(udp: true) else { return nil }
        let error = withUnsafePointer(to: &addr) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                connect(fd, sa, length) == 0 ? nil : lastPOSIXError()
            }
        }
        if error != nil {
            closeFD(fd)
            return nil
        }
        var bytes = Data(count: 4)
        bytes.withUnsafeMutableBytes { dest in
            var saddr = addr.sin_addr.s_addr
            withUnsafeBytes(of: &saddr) { src in
                dest.copyBytes(from: src)
            }
        }
        let host: NWEndpoint.Host = IPv4Address(bytes).map { .ipv4($0) } ?? .name("127.0.0.1", nil)
        let port = NWEndpoint.Port(integerLiteral: UInt16(bigEndian: addr.sin_port))
        return Accepted(
            fd: fd,
            endpoint: .hostPort(host: host, port: port),
            firstDatagram: Data(buffer.prefix(received))
        )
    }

    static func peerEndpoint(fd: Int32) -> NWEndpoint? {
        var addr = sockaddr_in()
        var length = socklen_t(MemoryLayout<sockaddr_in>.size)
        let rc = withUnsafeMutablePointer(to: &addr) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                getpeername(fd, sa, &length)
            }
        }
        guard rc == 0 else { return nil }
        var bytes = Data(count: 4)
        bytes.withUnsafeMutableBytes { dest in
            var saddr = addr.sin_addr.s_addr
            withUnsafeBytes(of: &saddr) { src in
                dest.copyBytes(from: src)
            }
        }
        let host: NWEndpoint.Host = IPv4Address(bytes).map { .ipv4($0) } ?? .name("127.0.0.1", nil)
        let port = NWEndpoint.Port(integerLiteral: UInt16(bigEndian: addr.sin_port))
        return .hostPort(host: host, port: port)
    }

    static func localEndpoint(fd: Int32) -> NWEndpoint? {
        var addr = sockaddr_in()
        var length = socklen_t(MemoryLayout<sockaddr_in>.size)
        let rc = withUnsafeMutablePointer(to: &addr) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                getsockname(fd, sa, &length)
            }
        }
        guard rc == 0 else { return nil }
        var bytes = Data(count: 4)
        bytes.withUnsafeMutableBytes { dest in
            var saddr = addr.sin_addr.s_addr
            withUnsafeBytes(of: &saddr) { src in
                dest.copyBytes(from: src)
            }
        }
        let host: NWEndpoint.Host = IPv4Address(bytes).map { .ipv4($0) } ?? .ipv4(.loopback)
        let port = NWEndpoint.Port(integerLiteral: UInt16(bigEndian: addr.sin_port))
        return .hostPort(host: host, port: port)
    }
}

func nwContainsDot(_ text: Substring) -> Bool {
    for character in text where character == "." {
        return true
    }
    return false
}

func nwSplitZone(_ string: String) -> (String, String?) {
    var zoneStart: String.Index?
    var index = string.startIndex
    while index < string.endIndex {
        if string[index] == "%" {
            zoneStart = index
        }
        index = string.index(after: index)
    }
    guard let zoneStart else { return (string, nil) }
    let address = String(string[string.startIndex..<zoneStart])
    let zone = String(string[string.index(after: zoneStart)...])
    return (address, zone.isEmpty ? nil : zone)
}

func nwStripBrackets(_ string: String) -> String {
    if string.hasPrefix("[") && string.hasSuffix("]") {
        return String(string.dropFirst().dropLast())
    }
    return string
}
