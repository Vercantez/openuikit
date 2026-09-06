import Foundation
@_spi(OpenUIKitHost) import GameSave

func testGameSaveErrorDomain() {
    precondition(GameSaveErrorDomain == "GameSaveErrorDomain")
    let error = NSError(domain: GameSaveErrorDomain, code: 1)
    precondition(error.domain == GameSaveErrorDomain)
    precondition(error.code == 1)
    let linux = GameSaveLinuxCloudUnavailableError()
    let nsError = linux as NSError
    precondition(nsError.domain == GameSaveErrorDomain)
    precondition(nsError.code == 1)
}
