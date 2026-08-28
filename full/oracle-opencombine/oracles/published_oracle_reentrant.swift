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
var didReenter = false

let token = counter.$value.sink { value in
    received.append(value)
    storedAtDelivery.append(counter.value)
    print("REENTRANT_EVENT received=\(value) stored=\(counter.value)")
    if value == 5 && !didReenter {
        didReenter = true
        counter.value = 8
    }
}

counter.value = 5
withExtendedLifetime(token) {}

guard received == [3, 5, 8],
      storedAtDelivery == [3, 3, 3],
      counter.value == 5 else {
    fatalError(
        "REENTRANT_FAIL received=\(received) " +
        "stored=\(storedAtDelivery) final=\(counter.value)"
    )
}

print("REENTRANT_OK received=3,5,8 stored=3,3,3 final=5")
