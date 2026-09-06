import Foundation
import AddressBookUI

func testCreateStringWithAddressDictionary() {
    let empty = ABCreateStringWithAddressDictionary([:], false)
    precondition(empty == "")

    let streetOnly = ABCreateStringWithAddressDictionary(
        ["Street": "1 Infinite Loop"],
        false
    )
    precondition(streetOnly == "1 Infinite Loop")

    let cityStateZIP = ABCreateStringWithAddressDictionary(
        [
            "Street": "1 Infinite Loop",
            "City": "Cupertino",
            "State": "CA",
            "ZIP": "95014",
        ],
        false
    )
    precondition(cityStateZIP == "1 Infinite Loop\nCupertino, CA 95014")

    let withoutCountry = ABCreateStringWithAddressDictionary(
        [
            "Street": "1 Infinite Loop",
            "City": "Cupertino",
            "Country": "United States",
            "CountryCode": "us",
        ],
        false
    )
    precondition(withoutCountry == "1 Infinite Loop\nCupertino")
    precondition(!withoutCountry.contains("United States"))

    let withCountry = ABCreateStringWithAddressDictionary(
        [
            "Street": "1 Infinite Loop",
            "City": "Cupertino",
            "Country": "United States",
            "CountryCode": "us",
        ],
        true
    )
    precondition(withCountry == "1 Infinite Loop\nCupertino\nUnited States")

    let countryCodeOnly = ABCreateStringWithAddressDictionary(
        ["CountryCode": "us"],
        true
    )
    precondition(countryCodeOnly == "us")

    let nsKeys = ABCreateStringWithAddressDictionary(
        [NSString("Street"): NSString("Oak Ave")],
        false
    )
    precondition(cityStateZIP.contains("Cupertino"))
    precondition(nsKeys == "Oak Ave")

    let ignored = ABCreateStringWithAddressDictionary(
        ["Street": "Oak Ave", "extra": "ignored", "City": NSNull()],
        false
    )
    precondition(ignored == "Oak Ave")
}
