import Foundation
import CoreData
func testQueueIdentity() {
    do {
            let mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            var mainWaitOnMain = false
            mainContext.performAndWait {
                mainWaitOnMain = true
            }
            guard mainWaitOnMain,
                  mainContext.concurrencyType == .mainQueueConcurrencyType else {
                throw ProbeFailure.message("mainQueueConcurrencyType performAndWait must run synchronously")
            }

            let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            var privateRan = false
            privateContext.performAndWait {
                privateRan = true
            }
            guard privateRan,
                  privateContext.concurrencyType == .privateQueueConcurrencyType else {
                throw ProbeFailure.message("privateQueueConcurrencyType performAndWait must run synchronously")
            }
    } catch {
        fatalError("testQueueIdentity failed: \(error)")
    }
}

func testQueueSerialization() {
    do {
            let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            context.lock()
            context.unlock()
            var overlapping = 0
            var maxOverlap = 0
            for _ in 0..<6 {
                context.performAndWait {
                    overlapping += 1
                    maxOverlap = max(maxOverlap, overlapping)
                    overlapping -= 1
                }
            }
            guard maxOverlap == 1 else {
                throw ProbeFailure.message("private-queue work must be serialized, maxOverlap=\(maxOverlap)")
            }
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: makeNoteModel())
            coordinator.lock()
            coordinator.unlock()
    } catch {
        fatalError("testQueueSerialization failed: \(error)")
    }
}

func testQueueReentrancy() {
    do {
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
            var order: [String] = []
            context.performAndWait {
                order.append("outer-start")
                context.performAndWait {
                    order.append("immediate")
                }
                order.append("outer-end")
            }
            guard order == ["outer-start", "immediate", "outer-end"] else {
                throw ProbeFailure.message("performAndWait nested ordering mismatch: \(order)")
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
    } catch {
        fatalError("testGenericPerformOverloads failed: \(error)")
    }
}
