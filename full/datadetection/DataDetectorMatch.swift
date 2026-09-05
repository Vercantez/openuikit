import Foundation

extension DataDetector {
    /// One detected span plus its semantic payload.
    public struct Match: Sendable {
        public let preferredHighlightStyle: HighlightStyle
        public let range: Range<String.Index>?
        public let details: SemanticDetails

        public init(
            preferredHighlightStyle: HighlightStyle,
            range: Range<String.Index>?,
            details: SemanticDetails
        ) {
            self.preferredHighlightStyle = preferredHighlightStyle
            self.range = range
            self.details = details
        }

        /// Visual treatment for a match. Digester child order: hidden, url, regular.
        public enum HighlightStyle: Hashable, Sendable {
            case hidden
            case url
            case regular
        }

        /// Typed payload for a match. Associated-value order follows the public surface.
        public enum SemanticDetails: Sendable {
            case measurement(Measurement)
            case moneyAmount(MoneyAmount)
            case phoneNumber(PhoneNumber)
            case emailAddress(EmailAddress)
            case flightNumber(FlightNumber)
            case calendarEvent(CalendarEvent)
            case postalAddress(PostalAddress)
            case paymentIdentifier(PaymentIdentifier)
            case shipmentTrackingNumber(ShipmentTrackingNumber)
            case link(Link)

            public struct Measurement: Sendable {
                public let possibleDimensions: [Dimension]
                public let value: Double

                public init(value: Double, possibleDimensions: [Dimension]) {
                    self.value = value
                    self.possibleDimensions = possibleDimensions
                }

                /// Converts `value` from the first stored unit of type `D` into
                /// `dimension`. If no source unit of that class is stored, the
                /// value is treated as already expressed in `dimension`.
                public func measurement<D: Dimension>(in dimension: D) -> Foundation.Measurement<D> {
                    if let source = possibleDimensions.compactMap({ $0 as? D }).first {
                        return Foundation.Measurement(value: value, unit: source).converted(to: dimension)
                    }
                    return Foundation.Measurement(value: value, unit: dimension)
                }
            }

            public struct MoneyAmount: Sendable {
                public let amount: Decimal
                public let currency: Locale.Currency

                public init(amount: Decimal, currency: Locale.Currency) {
                    self.amount = amount
                    self.currency = currency
                }
            }

            public struct PhoneNumber: Sendable {
                public let phoneNumber: String
                public let label: String?

                public init(phoneNumber: String, label: String?) {
                    self.phoneNumber = phoneNumber
                    self.label = label
                }
            }

            public struct EmailAddress: Sendable {
                public let emailAddress: String
                public let label: String?

                public init(emailAddress: String, label: String?) {
                    self.emailAddress = emailAddress
                    self.label = label
                }
            }

            public struct FlightNumber: Sendable {
                public let flightNumber: Int
                public let airlineCode: String

                public init(airlineCode: String, flightNumber: Int) {
                    self.airlineCode = airlineCode
                    self.flightNumber = flightNumber
                }
            }

            public struct CalendarEvent: Sendable {
                public let endTimeZone: TimeZone?
                public let startTimeZone: TimeZone?
                public let allDay: Bool
                public let endDate: Date?
                public let startDate: Date?

                public init(
                    allDay: Bool,
                    startDate: Date?,
                    startTimeZone: TimeZone?,
                    endDate: Date?,
                    endTimeZone: TimeZone?
                ) {
                    self.allDay = allDay
                    self.startDate = startDate
                    self.startTimeZone = startTimeZone
                    self.endDate = endDate
                    self.endTimeZone = endTimeZone
                }
            }

            public struct PostalAddress: Sendable {
                public let fullAddress: String
                public let postalCode: String?
                public let regionCode: Locale.Region?
                public let city: String?
                public let label: String?
                public let state: String?
                public let region: String?
                public let street: String?

                public init(
                    fullAddress: String,
                    street: String?,
                    city: String?,
                    state: String?,
                    postalCode: String?,
                    region: String?,
                    regionCode: Locale.Region?,
                    label: String?
                ) {
                    self.fullAddress = fullAddress
                    self.street = street
                    self.city = city
                    self.state = state
                    self.postalCode = postalCode
                    self.region = region
                    self.regionCode = regionCode
                    self.label = label
                }
            }

            public struct PaymentIdentifier: Sendable {
                public let identifier: String
                public let type: PaymentSystem

                public init(identifier: String, type: PaymentSystem) {
                    self.identifier = identifier
                    self.type = type
                }

                public enum PaymentSystem: Hashable, Sendable {
                    case unifiedPaymentsInterface
                }
            }

            public struct ShipmentTrackingNumber: Sendable {
                public let trackingNumber: String
                public let trackingURL: URL?
                public let carrier: String

                public init(carrier: String, trackingNumber: String, trackingURL: URL?) {
                    self.carrier = carrier
                    self.trackingNumber = trackingNumber
                    self.trackingURL = trackingURL
                }
            }

            public struct Link: Sendable {
                public let url: URL

                public init(url: URL) {
                    self.url = url
                }
            }
        }
    }
}
