// Ledger store — formatters, JSON persistence, regex search, loopback HTTP.
//
// Same bytes live in Sources/RealAppProbe/LedgerStore.swift so the guest
// `render_full` glob (RealAppProbe/*.swift) compiles them without editing
// full/scripts/build_full.sh (outside uikit/). Keep the two copies identical.
//
// Guest Foundation (docs/agent_reports/foundation-oracles.md) has
// NumberFormatter / DateFormatter / ISO8601DateFormatter /
// DateComponentsFormatter / JSONSerialization / NSRegularExpression /
// URLSession.data(for:). It does NOT have URLSessionDataTask — Apple and
// corelibs do. This file uses async `data(for:)` so the same source
// compiles on the guest; a semaphore wait fills the row before first
// layout because openrender has no run loop.
//
// MEASURED arm64 verify 22320ade, guest libSystem.tbd: undefined
// `_socket` `_bind` `_listen` `_accept` `_setsockopt` `_getsockname`
// referenced by LedgerLoopbackServer.start (realappprobe.o). Direct
// Darwin socket() does not link on the guest. Linux corelibs still
// call Glibc. Darwin (Apple Mac + guest) looks the six up with dlsym
// so Apple keeps the loopback row and the guest still links.
import UIKit
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(Dispatch)
import Dispatch
#endif
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

/// One ledger row. Display strings are produced by the formatters below,
/// not by interpolating Doubles, so a capture shows the Foundation the
/// host actually linked (Apple / corelibs / FoundationGuest).
nonisolated struct LedgerItem {
    let merchant: String
    let usd: String
    let eur: String
    let date: String
    let duration: String
    let iso8601: String
    let source: String
}

nonisolated enum LedgerStore {
    static let persistKey = "Ledger.payload"
    static let loopbackPath = "/quote"

    /// Pinned UTC instants so the strings do not depend on the host clock.
    static func pinnedDate(year: Int, month: Int, day: Int,
                           hour: Int, minute: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: DateComponents(
            calendar: calendar, timeZone: calendar.timeZone,
            year: year, month: month, day: day,
            hour: hour, minute: minute))!
    }

    /// NumberFormatter.currency, locale en_US.
    /// Guest golden (full/foundation/tests/foundation-number-formatter-apple-2026-09-05.txt):
    /// `num.en_US.currency.1234.5` → `$1,234.50`.
    static func usdString(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSNumber(value: amount)) ?? "—"
    }

    /// NumberFormatter.currency, locale de_DE.
    /// Guest golden: `num.de_DE.currency.1234.5` → `1.234,50` + NBSP + `€`.
    static func eurString(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: NSNumber(value: amount)) ?? "—"
    }

    /// DateFormatter.dateStyle `.medium`, locale en_US, GMT.
    /// Guest golden `style.en_US.2.0` → `Feb 29, 2024` for that instant;
    /// 2026-09-04 is therefore `Sep 4, 2026` on the guest tables.
    static func mediumDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    /// ISO8601DateFormatter default `.withInternetDateTime`, GMT.
    static func iso8601String(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.formatOptions = .withInternetDateTime
        return formatter.string(from: date)
    }

    /// DateComponentsFormatter abbreviated hours+minutes.
    /// Guest golden `dcf.abbr.en_US` → `1h 2m 3s` for 1:02:03; 2h15m is
    /// `2h 15m`.
    static func durationString(_ seconds: TimeInterval) -> String {
        #if canImport(Darwin)
        // Darwin and the guest's core-package Foundation have the formatter.
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
        formatter.zeroFormattingBehavior = .dropLeading
        return formatter.string(from: seconds) ?? "—"
        #else
        // swift-corelibs-foundation's DateComponentsFormatter traps in init()
        // (Docker verify 66b: "init() is not supported on this platform").
        // Same shape as the guest golden dcf.abbr.en_US: hours+minutes,
        // leading zero unit dropped ("2h 15m", "15m").
        let total = Int(seconds.rounded(.down))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
        #endif
    }

    /// JSONSerialization round trip through UserDefaults. Returns true when
    /// the loaded object is still a valid JSON container. Guest
    /// UserDefaults stores Data (full/foundation/UserDefaults.swift
    /// `_UDStored.data`).
    static func persistRoundTrip(_ items: [LedgerItem]) -> Bool {
        var payload: [[String: Any]] = []
        for item in items {
            payload.append([
                "merchant": item.merchant,
                "usd": item.usd,
                "iso8601": item.iso8601,
            ])
        }
        guard JSONSerialization.isValidJSONObject(payload),
              let data = try? JSONSerialization.data(withJSONObject: payload,
                                                     options: [.sortedKeys]) else {
            return false
        }
        UserDefaults.standard.set(data, forKey: persistKey)
        guard let loaded = UserDefaults.standard.data(forKey: persistKey),
              let obj = try? JSONSerialization.jsonObject(with: loaded) else {
            return false
        }
        return JSONSerialization.isValidJSONObject(obj)
    }

    /// NSRegularExpression filter over merchant. Empty query is identity.
    /// Invalid pattern keeps every row (the field is a search box, not a
    /// compiler). Range is UTF-16, matching Foundation's NSRange.
    static func matching(_ items: [LedgerItem], query: String) -> [LedgerItem] {
        if query.isEmpty { return items }
        let regex: NSRegularExpression
        do {
            regex = try NSRegularExpression(pattern: query, options: [.caseInsensitive])
        } catch {
            return items
        }
        var out: [LedgerItem] = []
        for item in items {
            let range = NSRange(location: 0, length: item.merchant.utf16.count)
            if regex.firstMatch(in: item.merchant, options: [], range: range) != nil {
                out.append(item)
            }
        }
        return out
    }

    static func seeded() -> [LedgerItem] {
        let coffee = pinnedDate(year: 2026, month: 9, day: 4, hour: 10, minute: 30)
        let payroll = pinnedDate(year: 2026, month: 9, day: 1, hour: 8, minute: 0)
        let rent = pinnedDate(year: 2026, month: 8, day: 28, hour: 12, minute: 0)
        let books = pinnedDate(year: 2026, month: 8, day: 22, hour: 16, minute: 45)
        let fare = pinnedDate(year: 2026, month: 8, day: 18, hour: 7, minute: 40)
        return [
            item(merchant: "Coffee Lab", amount: 4.5, date: coffee, seconds: 0),
            item(merchant: "Payroll", amount: 1234.5, date: payroll, seconds: 2 * 3600 + 15 * 60),
            item(merchant: "Rent", amount: 1850, date: rent, seconds: 0),
            item(merchant: "Bookshop", amount: 32.1, date: books, seconds: 45 * 60),
            item(merchant: "Transit fare", amount: 2.75, date: fare, seconds: 12 * 60),
        ]
    }

    static func item(merchant: String, amount: Double, date: Date,
                     seconds: TimeInterval, source: String = "seed") -> LedgerItem {
        LedgerItem(
            merchant: merchant,
            usd: usdString(amount),
            eur: eurString(amount),
            date: mediumDate(date),
            duration: seconds > 0 ? durationString(seconds) : "",
            iso8601: iso8601String(date),
            source: source)
    }

    /// Start a 127.0.0.1 HTTP server, GET /quote with URLSession, parse the
    /// JSON body. Returns nil when the socket, the session, or the JSON
    /// fails — the list still renders, with no loopback row.
    static func loopbackItem() -> LedgerItem? {
        let server = LedgerLoopbackServer()
        guard server.start() else {
            // POSIX listen is missing on the guest tbd (22320ade). Still
            // call URLSession.data(for:) so the trial records whether the
            // session itself runs; 127.0.0.1:1 refuses fast.
            if let url = URL(string: "http://127.0.0.1:1" + loopbackPath) {
                _ = fetchSync(url: url)
            }
            return nil
        }
        let urlString = "http://127.0.0.1:\(server.port)" + loopbackPath
        guard let url = URL(string: urlString) else {
            server.stop()
            return nil
        }
        let data = fetchSync(url: url)
        server.stop()
        guard let data,
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        let merchant = obj["merchant"] as? String ?? "Loopback FX"
        let amount: Double
        if let n = obj["amount"] as? Double {
            amount = n
        } else if let n = obj["amount"] as? Int {
            amount = Double(n)
        } else if let n = obj["amount"] as? NSNumber {
            amount = n.doubleValue
        } else {
            amount = 12.5
        }
        let date = pinnedDate(year: 2026, month: 9, day: 5, hour: 14, minute: 0)
        return item(merchant: merchant, amount: amount, date: date,
                    seconds: 0, source: "loopback")
    }

    /// Guest URLSession has `data(for:)` (async) and no `dataTask`. Wait on
    /// a semaphore so openrender's first layout already has the body.
    static func fetchSync(url: URL) -> Data? {
        var box: Data?
        let sem = DispatchSemaphore(value: 0)
        Task.detached {
            do {
                var request = URLRequest(url: url)
                request.timeoutInterval = 1.5
                let (data, _) = try await URLSession.shared.data(for: request)
                box = data
            } catch {
                box = nil
            }
            sem.signal()
        }
        _ = sem.wait(timeout: .now() + 2)
        return box
    }
}

#if !os(Linux)
/// Guest libSystem.tbd does not export BSD sockets (arm64 verify 22320ade).
/// `@_silgen_name("dlsym")` + RTLD_DEFAULT (−2) matches
/// full/foundation/tests/FoundationExtensionHostOracle.swift; looking the
/// six names up does not create `_socket` etc. undefineds.
@_silgen_name("dlsym")
private func _ledger_dlsym(_ handle: UnsafeMutableRawPointer?,
                           _ name: UnsafePointer<CChar>?) -> UnsafeMutableRawPointer?

private nonisolated enum LedgerBSD {
    static let rtldDefault = UnsafeMutableRawPointer(bitPattern: -2)
    typealias SocketFn = @convention(c) (Int32, Int32, Int32) -> Int32
    typealias SetSockOptFn = @convention(c) (Int32, Int32, Int32, UnsafeRawPointer?, socklen_t) -> Int32
    typealias BindFn = @convention(c) (Int32, UnsafePointer<sockaddr>?, socklen_t) -> Int32
    typealias ListenFn = @convention(c) (Int32, Int32) -> Int32
    typealias GetSockNameFn = @convention(c) (Int32, UnsafeMutablePointer<sockaddr>?, UnsafeMutablePointer<socklen_t>?) -> Int32
    typealias AcceptFn = @convention(c) (Int32, UnsafeMutablePointer<sockaddr>?, UnsafeMutablePointer<socklen_t>?) -> Int32

    static func load<T>(_ cName: UnsafePointer<CChar>) -> T? {
        guard let raw = _ledger_dlsym(rtldDefault, cName) else { return nil }
        return unsafeBitCast(raw, to: T.self)
    }

    static let socket: SocketFn? = load("socket")
    static let setsockopt: SetSockOptFn? = load("setsockopt")
    static let bind: BindFn? = load("bind")
    static let listen: ListenFn? = load("listen")
    static let getsockname: GetSockNameFn? = load("getsockname")
    static let accept: AcceptFn? = load("accept")
}
#endif

/// Tiny HTTP/1.1 listener on 127.0.0.1. POSIX sockets — guest Stream.swift
/// has no socket destination. Port 0, then getsockname.
nonisolated final class LedgerLoopbackServer: @unchecked Sendable {
    private var listenFD: Int32 = -1
    private(set) var port: Int = 0

    func start() -> Bool {
        #if os(Linux)
        let sockType = Int32(SOCK_STREAM.rawValue)
        let fd = socket(AF_INET, sockType, 0)
        guard fd >= 0 else { return false }
        var yes: Int32 = 1
        _ = setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &yes,
                       socklen_t(MemoryLayout<Int32>.size))
        #else
        guard let socketFn = LedgerBSD.socket,
              let setsockoptFn = LedgerBSD.setsockopt,
              let bindFn = LedgerBSD.bind,
              let listenFn = LedgerBSD.listen,
              let getsocknameFn = LedgerBSD.getsockname else {
            return false
        }
        let sockType = SOCK_STREAM
        let fd = socketFn(AF_INET, sockType, 0)
        guard fd >= 0 else { return false }
        var yes: Int32 = 1
        _ = setsockoptFn(fd, SOL_SOCKET, SO_REUSEADDR, &yes,
                         socklen_t(MemoryLayout<Int32>.size))
        #endif
        var addr = sockaddr_in()
        #if canImport(Darwin)
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.stride)
        #endif
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = 0
        addr.sin_addr.s_addr = UInt32(0x7F000001).bigEndian
        let bindRC = withUnsafePointer(to: &addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                #if os(Linux)
                bind(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
                #else
                bindFn(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
                #endif
            }
        }
        if bindRC != 0 {
            close(fd)
            return false
        }
        #if os(Linux)
        let listenRC = listen(fd, 4)
        #else
        let listenRC = listenFn(fd, 4)
        #endif
        if listenRC != 0 {
            close(fd)
            return false
        }
        var got = sockaddr_in()
        var len = socklen_t(MemoryLayout<sockaddr_in>.size)
        let nameRC = withUnsafeMutablePointer(to: &got) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                #if os(Linux)
                getsockname(fd, $0, &len)
                #else
                getsocknameFn(fd, $0, &len)
                #endif
            }
        }
        if nameRC != 0 {
            close(fd)
            return false
        }
        port = Int(UInt16(bigEndian: got.sin_port))
        listenFD = fd
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.acceptOnce()
        }
        return true
    }

    func stop() {
        if listenFD >= 0 {
            close(listenFD)
            listenFD = -1
        }
    }

    private func acceptOnce() {
        let fd = listenFD
        if fd < 0 { return }
        var clientAddr = sockaddr_in()
        var addrLen = socklen_t(MemoryLayout<sockaddr_in>.size)
        let client = withUnsafeMutablePointer(to: &clientAddr) { ptr -> Int32 in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                #if os(Linux)
                accept(fd, $0, &addrLen)
                #else
                guard let acceptFn = LedgerBSD.accept else { return -1 }
                return acceptFn(fd, $0, &addrLen)
                #endif
            }
        }
        if client < 0 { return }
        var buf = [UInt8](repeating: 0, count: 1024)
        _ = buf.withUnsafeMutableBufferPointer { read(client, $0.baseAddress, $0.count) }
        let body = "{\"merchant\":\"Loopback FX\",\"amount\":12.5}"
        let payload = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: "
            + String(body.utf8.count) + "\r\nConnection: close\r\n\r\n" + body
        let bytes = Array(payload.utf8)
        _ = bytes.withUnsafeBufferPointer { write(client, $0.baseAddress, $0.count) }
        close(client)
    }
}
