import Foundation

struct IncomingMessage: Identifiable {
    let id: String
    let sender: String
    let text: String
    let date: Date
    /// Message envoyé par soi-même (affiché dans l'historique, jamais dans la bulle).
    var mine: Bool = false
}

/// Écoute le salon ntfy en continu et y publie.
final class NtfyClient {
    private let config: Config
    private var lastID: String?
    private var task: Task<Void, Never>?

    var onMessage: ((IncomingMessage) -> Void)?
    var onStatus: ((Bool) -> Void)?

    init(config: Config) {
        self.config = config
    }

    func start() {
        task = Task { [self] in
            var delay: UInt64 = 1
            while !Task.isCancelled {
                do {
                    try await listen()
                    delay = 1
                } catch {
                    // Coupure réseau, veille du Mac… on se reconnecte.
                }
                await MainActor.run { onStatus?(false) }
                try? await Task.sleep(nanoseconds: delay * 1_000_000_000)
                delay = min(delay * 2, 30)
            }
        }
    }

    private func listen() async throws {
        let url = config.serverURL
            .appendingPathComponent(config.topic)
            .appendingPathComponent("json")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        // Après une coupure, on récupère les messages arrivés entre-temps.
        if let lastID {
            components.queryItems = [URLQueryItem(name: "since", value: lastID)]
        }
        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 90 // ntfy envoie un keepalive toutes les ~45 s

        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        await MainActor.run { onStatus?(true) }

        for try await line in bytes.lines {
            guard let message = parse(line) else { continue }
            lastID = message.id
            await MainActor.run { onMessage?(message) }
        }
    }

    /// Messages des 12 dernières heures (durée de conservation de ntfy.sh),
    /// pour remplir l'historique au lancement.
    func fetchRecent() async -> [IncomingMessage] {
        let url = config.serverURL
            .appendingPathComponent(config.topic)
            .appendingPathComponent("json")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "poll", value: "1"),
            URLQueryItem(name: "since", value: "12h"),
        ]
        guard let result = try? await URLSession.shared.data(from: components.url!) else { return [] }
        let messages = String(decoding: result.0, as: UTF8.self)
            .split(separator: "\n")
            .compactMap { parse(String($0)) }
        // L'écoute en continu reprendra juste après le dernier message récupéré.
        if let last = messages.last { lastID = last.id }
        return messages
    }

    private func parse(_ line: String) -> IncomingMessage? {
        guard let data = line.data(using: .utf8),
              let event = try? JSONDecoder().decode(Event.self, from: data),
              event.event == "message"
        else { return nil }
        return IncomingMessage(
            id: event.id,
            sender: event.title ?? "?",
            text: event.message ?? "",
            date: Date(timeIntervalSince1970: TimeInterval(event.time)),
            mine: event.title == config.me
        )
    }

    func send(_ text: String) async throws {
        var request = URLRequest(url: config.serverURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "topic": config.topic,
            "message": text,
            "title": config.me,
        ])
        let (_, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }

    private struct Event: Decodable {
        let id: String
        let time: Int
        let event: String
        let message: String?
        let title: String?
    }
}
