// EnergyKit — Linux starting point for Apple's public EnergyKit module.
// Isolated host compilation imports Foundation only. Home energy venues,
// electricity-guidance daemons, and insight services are absent; lookups and
// submissions fail closed with EnergyKitError. Do not treat a successful
// compile as an Apple EnergyKit runtime.

import Foundation

/// A type that can represent an electrical load event.
///
/// Do not declare new conformances. Only `ElectricHVACLoadEvent` and
/// `ElectricVehicleLoadEvent` are the documented adopters.
public protocol ElectricalLoadEventProtocol: Codable, Identifiable, Sendable {}

/// Marker protocol for values that can appear in an electricity insight record.
/// `Duration` and Foundation `Measurement` are the documented adopters.
public protocol ElectricityInsightMeasure {}

extension Duration: ElectricityInsightMeasure {}

extension Measurement: ElectricityInsightMeasure {}

/// Fail-closed async sequence used when Apple electricity guidance is absent.
struct EnergyKitFailClosedSequence<Element: Sendable>: AsyncSequence, Sendable {
    let error: EnergyKitError

    func makeAsyncIterator() -> Iterator {
        Iterator(error: error)
    }

    struct Iterator: AsyncIteratorProtocol, Sendable {
        let error: EnergyKitError

        mutating func next() async throws -> Element? {
            throw error
        }
    }
}

extension UnitEnergy {
    /// Nested EnergyKit energy units. Linux `UnitEnergy` is final, so this
    /// nested type subclasses `Dimension`. `milliwattHours` uses the SI
    /// identity `1 mWh = 3.6 J`.
    public class EnergyKit: Dimension, @unchecked Sendable {
        /// One milliwatt-hour. Linear converter coefficient is 3.6 (joules).
        public static let milliwattHours: UnitEnergy = UnitEnergy(
            symbol: "mWh",
            converter: UnitConverterLinear(coefficient: 3.6)
        )

        public required init(symbol: String, converter: UnitConverter) {
            super.init(symbol: symbol, converter: converter)
        }

        public required init(symbol: String) {
            super.init(symbol: symbol, converter: UnitConverterLinear(coefficient: 1.0))
        }

        public required init?(coder: NSCoder) {
            super.init(coder: coder)
        }
    }
}
