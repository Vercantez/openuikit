@_cdecl("swift_hello")
public func swiftHello() -> Int32 {
    var acc: Int32 = 0
    for i in 1...10 { acc += Int32(i) }
    let s = "hello-from-swift acc=\(acc)"
    print(s)
    let arr = [1, 2, 3, 4].map { $0 * $0 }
    print("squares=\(arr) sum=\(arr.reduce(0,+))")
    return acc
}
