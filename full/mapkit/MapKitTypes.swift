import Foundation

public struct MKDirectionsTransportType: OptionSet, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let automobile = MKDirectionsTransportType(rawValue: 1 << 0)
    public static let walking = MKDirectionsTransportType(rawValue: 1 << 1)
    public static let transit = MKDirectionsTransportType(rawValue: 1 << 2)
    public static let cycling = MKDirectionsTransportType(rawValue: 1 << 3)
    public static let any = MKDirectionsTransportType(rawValue: 0x0FFF_FFFF)
}

public struct MKMapFeatureOptions: OptionSet, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let pointsOfInterest = MKMapFeatureOptions(rawValue: 1 << 0)
    public static let territories = MKMapFeatureOptions(rawValue: 1 << 1)
    public static let physicalFeatures = MKMapFeatureOptions(rawValue: 1 << 2)
}

public enum MKMapType: UInt, Hashable, Sendable {
    case standard = 0
    case satellite = 1
    case hybrid = 2
    case satelliteFlyover = 3
    case hybridFlyover = 4
    case mutedStandard = 5
}

public enum MKOverlayLevel: Int, Hashable, Sendable {
    case aboveRoads = 0
    case aboveLabels = 1
}

public enum MKFeatureVisibility: Int, Hashable, Sendable {
    case adaptive = 0
    case hidden = 1
    case visible = 2
}

public enum MKPinAnnotationColor: UInt, Hashable, Sendable {
    case red = 0
    case green = 1
    case purple = 2
}

public enum MKUserTrackingMode: Int, Hashable, Sendable {
    case none = 0
    case follow = 1
    case followWithHeading = 2
}

public enum MKLocalSearchRegionPriority: Int, Hashable, Sendable {
    case `default` = 0
    case required = 1
}

public enum MKLookAroundBadgePosition: Int, Hashable, Sendable {
    case topLeading = 0
    case topTrailing = 1
    case bottomTrailing = 2
}

public struct MKPointOfInterestCategory: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let airport = MKPointOfInterestCategory(rawValue: "MKPOICategoryAirport")
    public static let amusementPark = MKPointOfInterestCategory(rawValue: "MKPOICategoryAmusementPark")
    public static let aquarium = MKPointOfInterestCategory(rawValue: "MKPOICategoryAquarium")
    public static let atm = MKPointOfInterestCategory(rawValue: "MKPOICategoryATM")
    public static let bakery = MKPointOfInterestCategory(rawValue: "MKPOICategoryBakery")
    public static let bank = MKPointOfInterestCategory(rawValue: "MKPOICategoryBank")
    public static let beach = MKPointOfInterestCategory(rawValue: "MKPOICategoryBeach")
    public static let brewery = MKPointOfInterestCategory(rawValue: "MKPOICategoryBrewery")
    public static let cafe = MKPointOfInterestCategory(rawValue: "MKPOICategoryCafe")
    public static let campground = MKPointOfInterestCategory(rawValue: "MKPOICategoryCampground")
    public static let carRental = MKPointOfInterestCategory(rawValue: "MKPOICategoryCarRental")
    public static let evCharger = MKPointOfInterestCategory(rawValue: "MKPOICategoryEVCharger")
    public static let fireStation = MKPointOfInterestCategory(rawValue: "MKPOICategoryFireStation")
    public static let fitnessCenter = MKPointOfInterestCategory(rawValue: "MKPOICategoryFitnessCenter")
    public static let foodMarket = MKPointOfInterestCategory(rawValue: "MKPOICategoryFoodMarket")
    public static let gasStation = MKPointOfInterestCategory(rawValue: "MKPOICategoryGasStation")
    public static let hospital = MKPointOfInterestCategory(rawValue: "MKPOICategoryHospital")
    public static let hotel = MKPointOfInterestCategory(rawValue: "MKPOICategoryHotel")
    public static let laundry = MKPointOfInterestCategory(rawValue: "MKPOICategoryLaundry")
    public static let library = MKPointOfInterestCategory(rawValue: "MKPOICategoryLibrary")
    public static let marina = MKPointOfInterestCategory(rawValue: "MKPOICategoryMarina")
    public static let movieTheater = MKPointOfInterestCategory(rawValue: "MKPOICategoryMovieTheater")
    public static let museum = MKPointOfInterestCategory(rawValue: "MKPOICategoryMuseum")
    public static let nationalPark = MKPointOfInterestCategory(rawValue: "MKPOICategoryNationalPark")
    public static let nightlife = MKPointOfInterestCategory(rawValue: "MKPOICategoryNightlife")
    public static let park = MKPointOfInterestCategory(rawValue: "MKPOICategoryPark")
    public static let parking = MKPointOfInterestCategory(rawValue: "MKPOICategoryParking")
    public static let pharmacy = MKPointOfInterestCategory(rawValue: "MKPOICategoryPharmacy")
    public static let police = MKPointOfInterestCategory(rawValue: "MKPOICategoryPolice")
    public static let postOffice = MKPointOfInterestCategory(rawValue: "MKPOICategoryPostOffice")
    public static let publicTransport = MKPointOfInterestCategory(rawValue: "MKPOICategoryPublicTransport")
    public static let restaurant = MKPointOfInterestCategory(rawValue: "MKPOICategoryRestaurant")
    public static let restroom = MKPointOfInterestCategory(rawValue: "MKPOICategoryRestroom")
    public static let school = MKPointOfInterestCategory(rawValue: "MKPOICategorySchool")
    public static let stadium = MKPointOfInterestCategory(rawValue: "MKPOICategoryStadium")
    public static let store = MKPointOfInterestCategory(rawValue: "MKPOICategoryStore")
    public static let theater = MKPointOfInterestCategory(rawValue: "MKPOICategoryTheater")
    public static let university = MKPointOfInterestCategory(rawValue: "MKPOICategoryUniversity")
    public static let winery = MKPointOfInterestCategory(rawValue: "MKPOICategoryWinery")
    public static let zoo = MKPointOfInterestCategory(rawValue: "MKPOICategoryZoo")
    public static let animalService = MKPointOfInterestCategory(rawValue: "MKPOICategoryAnimalService")
    public static let automotiveRepair = MKPointOfInterestCategory(rawValue: "MKPOICategoryAutomotiveRepair")
    public static let baseball = MKPointOfInterestCategory(rawValue: "MKPOICategoryBaseball")
    public static let basketball = MKPointOfInterestCategory(rawValue: "MKPOICategoryBasketball")
    public static let beauty = MKPointOfInterestCategory(rawValue: "MKPOICategoryBeauty")
    public static let bowling = MKPointOfInterestCategory(rawValue: "MKPOICategoryBowling")
    public static let castle = MKPointOfInterestCategory(rawValue: "MKPOICategoryCastle")
    public static let conventionCenter = MKPointOfInterestCategory(rawValue: "MKPOICategoryConventionCenter")
    public static let distillery = MKPointOfInterestCategory(rawValue: "MKPOICategoryDistillery")
    public static let fairground = MKPointOfInterestCategory(rawValue: "MKPOICategoryFairground")
    public static let fishing = MKPointOfInterestCategory(rawValue: "MKPOICategoryFishing")
    public static let fortress = MKPointOfInterestCategory(rawValue: "MKPOICategoryFortress")
    public static let golf = MKPointOfInterestCategory(rawValue: "MKPOICategoryGolf")
    public static let goKart = MKPointOfInterestCategory(rawValue: "MKPOICategoryGoKart")
    public static let hiking = MKPointOfInterestCategory(rawValue: "MKPOICategoryHiking")
    public static let kayaking = MKPointOfInterestCategory(rawValue: "MKPOICategoryKayaking")
    public static let landmark = MKPointOfInterestCategory(rawValue: "MKPOICategoryLandmark")
    public static let mailbox = MKPointOfInterestCategory(rawValue: "MKPOICategoryMailbox")
    public static let miniGolf = MKPointOfInterestCategory(rawValue: "MKPOICategoryMiniGolf")
    public static let musicVenue = MKPointOfInterestCategory(rawValue: "MKPOICategoryMusicVenue")
    public static let nationalMonument = MKPointOfInterestCategory(rawValue: "MKPOICategoryNationalMonument")
    public static let planetarium = MKPointOfInterestCategory(rawValue: "MKPOICategoryPlanetarium")
    public static let rockClimbing = MKPointOfInterestCategory(rawValue: "MKPOICategoryRockClimbing")
    public static let rvPark = MKPointOfInterestCategory(rawValue: "MKPOICategoryRVPark")
    public static let skatePark = MKPointOfInterestCategory(rawValue: "MKPOICategorySkatePark")
    public static let skating = MKPointOfInterestCategory(rawValue: "MKPOICategorySkating")
    public static let skiing = MKPointOfInterestCategory(rawValue: "MKPOICategorySkiing")
    public static let soccer = MKPointOfInterestCategory(rawValue: "MKPOICategorySoccer")
    public static let spa = MKPointOfInterestCategory(rawValue: "MKPOICategorySpa")
    public static let surfing = MKPointOfInterestCategory(rawValue: "MKPOICategorySurfing")
    public static let swimming = MKPointOfInterestCategory(rawValue: "MKPOICategorySwimming")
    public static let tennis = MKPointOfInterestCategory(rawValue: "MKPOICategoryTennis")
    public static let volleyball = MKPointOfInterestCategory(rawValue: "MKPOICategoryVolleyball")
}

public struct MKFeatureDisplayPriority: RawRepresentable, Hashable, Sendable {
    public var rawValue: Float

    public init(rawValue: Float) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: Float) {
        self.rawValue = rawValue
    }

    public static let required = MKFeatureDisplayPriority(rawValue: 1000)
    public static let defaultHigh = MKFeatureDisplayPriority(rawValue: 750)
    public static let defaultLow = MKFeatureDisplayPriority(rawValue: 250)
}

public struct MKAnnotationViewZPriority: RawRepresentable, Hashable, Sendable {
    public var rawValue: Float

    public init(rawValue: Float) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: Float) {
        self.rawValue = rawValue
    }

    public static let min = MKAnnotationViewZPriority(rawValue: 0)
    public static let max = MKAnnotationViewZPriority(rawValue: 1000)
    public static let defaultUnselected = MKAnnotationViewZPriority(rawValue: 250)
    public static let defaultSelected = MKAnnotationViewZPriority(rawValue: 1000)
}
