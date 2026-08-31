import Dispatch
import Foundation

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() { fatalError("DispatchMachORuntime: \(message)") }
}

@main
private enum DispatchMachORuntime {
    static func main() async {
        let values = await withTaskGroup(of: Int.self) { group in
            for value in 1 ... 8 {
                group.addTask { value * value }
            }
            var result: [Int] = []
            for await value in group { result.append(value) }
            return result
        }
        require(values.count == 8, "task-group result count")
        require(values.reduce(0, +) == 204, "task-group result values")

        let detached = await Task.detached { 41 + 1 }.value
        require(detached == 42, "detached task result")

        let globalValue = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                continuation.resume(returning: 17)
            }
        }
        require(globalValue == 17, "portable Dispatch global callback")

        let mainValue = await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                continuation.resume(returning: 23)
            }
        }
        require(mainValue == 23, "portable Dispatch main callback")

        let timerStarted = DispatchTime.now().uptimeNanoseconds
        let timerValue = await withCheckedContinuation { continuation in
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(2)) {
                continuation.resume(returning: 29)
            }
        }
        require(timerValue == 29, "portable Dispatch delayed callback")
        require(DispatchTime.now().uptimeNanoseconds >= timerStarted, "monotonic time")

        print("OPEN_DISPATCH_MACHO_OK async-main=drained taskgroup=8 detached=42 global=17 main=23 after=29 vouchers=null")
    }
}
