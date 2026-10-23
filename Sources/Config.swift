import Foundation

/// Réglages lus dans ~/Library/Application Support/EK Backstage/config.json
struct Config: Codable {
    var me: String
    var secret: String
    var server: String?

    var serverURL: URL { URL(string: server ?? "https://ntfy.sh")! }

    /// Salon commun : tout le monde écrit et écoute sur le même canal.
    var topic: String { secret }

    static var fileURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/EK Backstage/config.json")
    }

    static func load() throws -> Config {
        try JSONDecoder().decode(Config.self, from: Data(contentsOf: fileURL))
    }
}
