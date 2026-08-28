import Combine

final class Counter {
    @Published var value: Int

    init(_ value: Int) {
        self.value = value
    }
}

let counter = Counter(3)
var received: [Int] = []
var storedAtDelivery: [Int] = []

let token = counter.$value.sink { value in
    received.append(value)
    storedAtDelivery.append(counter.value)
    print("EVENT received=\(value) stored=\(counter.value)")
}

counter.value = 5
counter.value = 8
withExtendedLifetime(token) {}

guard received == [3, 5, 8], storedAtDelivery == [3, 3, 5] else {
    fatalError("ORACLE_FAIL received=\(received) stored=\(storedAtDelivery)")
}

print("ORACLE_OK received=3,5,8 stored=3,3,5")
