import Foundation
import MusicKit

let _: Foundation.Data.Type = Data.self
let _: Foundation.URL.Type = URL.self
let _: Foundation.Date.Type = Date.self
let _: Foundation.UUID.Type = UUID.self
let _: Foundation.JSONDecoder.Type = JSONDecoder.self

let id = MusicItemID("identity")
precondition(id.rawValue == "identity")
let song = Song(id: id, title: "Identity", artistName: "Foundation")
precondition(song.title == "Identity")
let encoded = try! JSONEncoder().encode(id)
precondition(!encoded.isEmpty)
precondition(MusicAuthorization.currentStatus == MusicAuthorization.currentStatus)
precondition(URL(string: "https://api.music.apple.com") != nil)
