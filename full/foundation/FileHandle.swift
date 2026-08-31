// A descriptor-backed Foundation.FileHandle slice. The API is intentionally
// synchronous: every successful operation is performed by libSystem. Modern
// throwing entry points surface descriptor errors; legacy nonthrowing entry
// points retain their historical empty-data/precondition behavior.

import Darwin
import FoundationEssentials

#if canImport(ObjectiveC)
import class ObjectiveC.NSObject
#else
#error("Foundation.FileHandle requires the ObjectiveC NSObject substrate")
#endif

public struct FileHandleError: Error, Equatable, Sendable {
    public let operation: String
    public let code: Int32

    public init(operation: String, code: Int32) {
        self.operation = operation
        self.code = code
    }
}

public final class FileHandle: NSObject, @unchecked Sendable {
    private let stateLock = NSLock()
    private var descriptor: Int32
    private let closeOnDealloc: Bool

    public init(fileDescriptor: Int32, closeOnDealloc: Bool = false) {
        descriptor = fileDescriptor
        self.closeOnDealloc = closeOnDealloc
        super.init()
    }

    public convenience init?(forReadingAtPath path: String) {
        let descriptor = path.withCString { Darwin.open($0, O_RDONLY) }
        guard descriptor >= 0 else { return nil }
        self.init(fileDescriptor: descriptor, closeOnDealloc: true)
    }

    public convenience init?(forWritingAtPath path: String) {
        let descriptor = path.withCString { Darwin.open($0, O_WRONLY) }
        guard descriptor >= 0 else { return nil }
        self.init(fileDescriptor: descriptor, closeOnDealloc: true)
    }

    deinit {
        if closeOnDealloc {
            closeFile()
        }
    }

    public static let standardInput = FileHandle(fileDescriptor: STDIN_FILENO)
    public static let standardOutput = FileHandle(fileDescriptor: STDOUT_FILENO)
    public static let standardError = FileHandle(fileDescriptor: STDERR_FILENO)
    public static let nullDevice: FileHandle = {
        let descriptor = "/dev/null".withCString {
            Darwin.open($0, O_RDWR)
        }
        return FileHandle(
            fileDescriptor: descriptor,
            closeOnDealloc: descriptor >= 0
        )
    }()

    public var fileDescriptor: Int32 {
        stateLock.withLock { descriptor }
    }

    public var offsetInFile: UInt64 {
        stateLock.withLock {
            guard descriptor >= 0 else { return 0 }
            let offset = Darwin.lseek(descriptor, 0, SEEK_CUR)
            return offset >= 0 ? UInt64(offset) : 0
        }
    }

    public func readData(ofLength length: Int) -> Data {
        do {
            return try read(upToCount: length) ?? Data()
        } catch {
            return Data()
        }
    }

    public func read(upToCount count: Int) throws -> Data? {
        guard count > 0 else { return nil }
        return try stateLock.withLock {
            guard descriptor >= 0 else {
                throw FileHandleError(operation: "read", code: EBADF)
            }
            var bytes = [UInt8](repeating: 0, count: count)
            var result: Int
            repeat {
                result = Darwin.read(descriptor, &bytes, count)
            } while result < 0 && errno == EINTR
            guard result >= 0 else {
                throw FileHandleError(operation: "read", code: errno)
            }
            guard result > 0 else { return nil }
            return Data(bytes.prefix(result))
        }
    }

    public var availableData: Data {
        readData(ofLength: 4096)
    }

    public func readDataToEndOfFile() -> Data {
        do {
            return try readToEnd() ?? Data()
        } catch {
            return Data()
        }
    }

    public func readToEnd() throws -> Data? {
        var result = Data()
        while true {
            guard let chunk = try read(upToCount: 64 * 1024) else {
                return result.isEmpty ? nil : result
            }
            result.append(chunk)
        }
    }

    public func write(_ data: Data) {
        do {
            try write(contentsOf: data)
        } catch {
            preconditionFailure("FileHandle.write failed: \(error)")
        }
    }

    public func write(contentsOf data: Data) throws {
        try stateLock.withLock {
            guard descriptor >= 0 else {
                throw FileHandleError(operation: "write", code: EBADF)
            }
            let bytes = Array(data)
            try bytes.withUnsafeBufferPointer { buffer in
                var offset = 0
                while offset < buffer.count {
                    let count = Darwin.write(
                        descriptor,
                        buffer.baseAddress! + offset,
                        buffer.count - offset
                    )
                    if count < 0 && errno == EINTR { continue }
                    guard count > 0 else {
                        throw FileHandleError(operation: "write", code: errno)
                    }
                    offset += count
                }
            }
        }
    }

    public func seek(toFileOffset offset: UInt64) {
        do {
            try seek(toOffset: offset)
        } catch {
            preconditionFailure("FileHandle.seek failed: \(error)")
        }
    }

    public func seek(toOffset offset: UInt64) throws {
        try stateLock.withLock {
            guard descriptor >= 0 else {
                throw FileHandleError(operation: "seek", code: EBADF)
            }
            guard Darwin.lseek(descriptor, off_t(offset), SEEK_SET) >= 0 else {
                throw FileHandleError(operation: "seek", code: errno)
            }
        }
    }

    @discardableResult
    public func seekToEndOfFile() -> UInt64 {
        stateLock.withLock {
            guard descriptor >= 0 else { return 0 }
            let offset = Darwin.lseek(descriptor, 0, SEEK_END)
            return offset >= 0 ? UInt64(offset) : 0
        }
    }

    public func truncateFile(atOffset offset: UInt64) {
        stateLock.withLock {
            guard descriptor >= 0 else { return }
            precondition(Darwin.ftruncate(descriptor, off_t(offset)) == 0)
        }
    }

    public func synchronizeFile() {
        stateLock.withLock {
            guard descriptor >= 0 else { return }
            precondition(Darwin.fsync(descriptor) == 0)
        }
    }

    public func closeFile() {
        _ = closeDescriptor()
    }

    public func close() throws {
        if let error = closeDescriptor() {
            throw error
        }
    }

    /// POSIX leaves an interrupted close's descriptor state unspecified, and
    /// Linux may already have released it. Never retry: another thread could
    /// reuse the numeric descriptor and a second close would target unrelated
    /// state. Mark this handle closed first, issue exactly one close, and let
    /// the throwing API report the observed errno.
    private func closeDescriptor() -> FileHandleError? {
        stateLock.withLock {
            guard descriptor >= 0 else { return nil }
            let closing = descriptor
            descriptor = -1
            guard Darwin.close(closing) == 0 else {
                return FileHandleError(operation: "close", code: errno)
            }
            return nil
        }
    }
}
