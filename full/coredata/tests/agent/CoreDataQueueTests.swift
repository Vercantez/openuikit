import Foundation
import CoreData
func testQueueIdentity() {
    do {
            let mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            var mainWaitOnMain = false
            mainContext.performAndWait {
                mainWaitOnMain = Thread.isMainThread
            }
            guard mainWaitOnMain else {
                throw ProbeFailure.message("mainQueueConcurrencyType performAndWait must run on the main executor")
            }

            var mainAsyncOnMain = false
            var mainAsyncRan = false
            mainContext.perform {
                mainAsyncOnMain = Thread.isMainThread
                mainAsyncRan = true
            }
            guard waitUntil(2, { mainAsyncRan }), mainAsyncOnMain else {
                throw ProbeFailure.message("mainQueueConcurrencyType perform must run on the main executor")
            }

            let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            var privateAsyncOnMain = true
            let signal = DispatchSemaphore(value: 0)
            privateContext.perform {
                privateAsyncOnMain = Thread.isMainThread
                signal.signal()
            }
            guard signal.wait(timeout: .now() + 5) == .success, privateAsyncOnMain == false else {
                throw ProbeFailure.message("privateQueueConcurrencyType perform must use a dedicated serial executor")
            }
    } catch {
        fatalError("testQueueIdentity failed: \(error)")
    }
}

func testQueueSerialization() {
    do {
            let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            var overlapping = 0
            var maxOverlap = 0
            let spin = NSLock()
            let group = DispatchGroup()
            for _ in 0..<6 {
                group.enter()
                context.perform {
                    spin.lock()
                    overlapping += 1
                    maxOverlap = max(maxOverlap, overlapping)
                    spin.unlock()
                    Thread.sleep(forTimeInterval: 0.02)
                    spin.lock()
                    overlapping -= 1
                    spin.unlock()
                    group.leave()
                }
            }
            guard group.wait(timeout: .now() + 5) == .success, maxOverlap == 1 else {
                throw ProbeFailure.message("private-queue work must be serialized, maxOverlap=\(maxOverlap)")
            }
    } catch {
        fatalError("testQueueSerialization failed: \(error)")
    }
}

func testQueueReentrancy() {
    do {
            let mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            var mainNested = false
            mainContext.performAndWait {
                mainContext.performAndWait {
                    mainNested = Thread.isMainThread
                }
            }
            guard mainNested else {
                throw ProbeFailure.message("main-queue performAndWait must be reentrant")
            }

            let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            var privateNested = false
            privateContext.performAndWait {
                privateContext.performAndWait {
                    privateNested = true
                }
            }
            guard privateNested else {
                throw ProbeFailure.message("private-queue performAndWait must be reentrant and must not deadlock")
            }
    } catch {
        fatalError("testQueueReentrancy failed: \(error)")
    }
}

func testPerformOrdering() {
    do {
            let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            let lock = NSLock()
            var order: [String] = []
            func append(_ value: String) {
                lock.lock()
                order.append(value)
                lock.unlock()
            }
            let outerDone = DispatchSemaphore(value: 0)
            let enqueuedDone = DispatchSemaphore(value: 0)
            context.perform {
                append("outer-start")
                context.performAndWait {
                    append("immediate")
                }
                context.perform {
                    append("enqueued")
                    enqueuedDone.signal()
                }
                append("outer-end")
                outerDone.signal()
            }
            guard outerDone.wait(timeout: .now() + 5) == .success,
                  enqueuedDone.wait(timeout: .now() + 5) == .success,
                  order == ["outer-start", "immediate", "outer-end", "enqueued"] else {
                throw ProbeFailure.message("perform immediate versus enqueued ordering mismatch: \(order)")
            }

            var scheduled: [String] = []
            let scheduleDone = DispatchSemaphore(value: 0)
            var scheduleError: String?
            Task {
                do {
                    _ = try await context.perform(schedule: .enqueued) { () -> Int in
                        scheduled.append("enqueued")
                        return 1
                    }
                    _ = try await context.perform(schedule: .immediate) { () -> Int in
                        scheduled.append("immediate")
                        return 2
                    }
                } catch {
                    scheduleError = String(describing: error)
                }
                scheduleDone.signal()
            }
            guard scheduleDone.wait(timeout: .now() + 5) == .success else {
                throw ProbeFailure.message("async perform(schedule:) timed out")
            }
            if let scheduleError {
                throw ProbeFailure.message("async perform(schedule:) failed: \(scheduleError)")
            }
            guard scheduled == ["enqueued", "immediate"] else {
                throw ProbeFailure.message("async perform(schedule:) ordering mismatch: \(scheduled)")
            }
    } catch {
        fatalError("testPerformOrdering failed: \(error)")
    }
}

func testGenericPerformOverloads() {
    do {
            let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            let value: Int = context.performAndWait { 7 }
            guard value == 7 else {
                throw ProbeFailure.message("generic performAndWait did not return the block result")
            }

            enum Token: Error { case boom }
            do {
                _ = try context.performAndWait { () throws -> Int in
                    throw Token.boom
                }
                throw ProbeFailure.message("generic performAndWait must rethrow")
            } catch is Token {
                // expected
            } catch {
                throw ProbeFailure.message("generic performAndWait threw an unexpected error: \(error)")
            }

            let asyncDone = DispatchSemaphore(value: 0)
            var asyncValue = 0
            Task {
                asyncValue = (try? await context.perform(schedule: .immediate) { 11 }) ?? 0
                asyncDone.signal()
            }
            guard asyncDone.wait(timeout: .now() + 5) == .success, asyncValue == 11 else {
                throw ProbeFailure.message("generic perform(schedule:) did not return the block result")
            }
    } catch {
        fatalError("testGenericPerformOverloads failed: \(error)")
    }
}

