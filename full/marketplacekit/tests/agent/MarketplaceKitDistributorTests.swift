import Foundation
import MarketplaceKit

func testAppDistributorCases() {
    let store = AppDistributor.appStore
    let flight = AppDistributor.testFlight
    let market = AppDistributor.marketplace("eu.example.market")
    let web = AppDistributor.web
    let other = AppDistributor.other
    precondition(store != flight)
    precondition(store != web)
    precondition(store != other)
    switch market {
    case .marketplace(let identifier):
        precondition(identifier == "eu.example.market")
    default:
        preconditionFailure("marketplace associated value")
    }
    switch store {
    case .appStore:
        break
    default:
        preconditionFailure("appStore")
    }
    switch flight {
    case .testFlight:
        break
    default:
        preconditionFailure("testFlight")
    }
    switch web {
    case .web:
        break
    default:
        preconditionFailure("web")
    }
    switch other {
    case .other:
        break
    default:
        preconditionFailure("other")
    }
}
