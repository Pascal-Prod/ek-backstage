import AppKit
import Carbon

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let quickReplies = ["Oui", "Non", "Ok 👍"]

    private var config: Config!
    private var client: NtfyClient!
    private var popup: PopupController!
    private let historyStore = HistoryStore()
    private var hotKey: HotKey?
    private var statusItem: NSStatusItem!
    private var statusLine: NSMenuItem!
    private var menu: NSMenu!

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            config = try Config.load()
        } catch {
            let alert = NSAlert()
            alert.messageText = "EK Backstage : configuration introuvable"
            alert.informativeText = "Lance d'abord ./configure.sh (voir le README).\n\(Config.fileURL.path)"
            alert.runModal()
            NSApp.terminate(nil)
            return
        }

        popup = PopupController(
            store: historyStore,
            placeholder: "Message…",
            quickReplies: quickReplies
        )
        client = NtfyClient(config: config)
        popup.onSend = { [weak self] text in self?.send(text) }
        client.onMessage = { [weak self] message in
            guard let self else { return }
            historyStore.add([message])
            if !message.mine {
                popup.receive(message)
                playSound()
            }
        }
        client.onStatus = { [weak self] connected in
            self?.statusLine.title = connected ? "● Connecté" : "○ Reconnexion…"
        }

        setupMenu()
        hotKey = HotKey(keyCode: UInt32(kVK_ANSI_M), modifiers: UInt32(controlKey | optionKey)) { [weak self] in
            self?.popup.toggleForWriting()
        }

        // On remplit l'historique avec les dernières heures, puis on écoute en continu.
        Task {
            let recent = await client.fetchRecent()
            historyStore.add(recent)
            client.start()
        }
    }

    private func send(_ text: String) {
        Task {
            do {
                try await client.send(text)
            } catch {
                await MainActor.run {
                    popup.receive(IncomingMessage(
                        id: UUID().uuidString,
                        sender: "EK Backstage",
                        text: "⚠️ Message non envoyé : « \(text) »",
                        date: Date()
                    ))
                }
            }
        }
    }

    private func setupMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(
            systemSymbolName: "bubble.left.and.bubble.right",
            accessibilityDescription: "EK Backstage"
        )
        // Clic gauche : écrire. Clic droit (ou Ctrl-clic) : menu.
        statusItem.button?.target = self
        statusItem.button?.action = #selector(statusItemClicked)
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

        menu = NSMenu()
        statusLine = NSMenuItem(title: "○ Connexion…", action: nil, keyEquivalent: "")
        statusLine.isEnabled = false
        menu.addItem(statusLine)
        menu.addItem(.separator())

        let write = NSMenuItem(title: "Écrire au salon…", action: #selector(openCompose), keyEquivalent: "m")
        write.keyEquivalentModifierMask = [.control, .option]
        write.target = self
        menu.addItem(write)

        let soundItem = NSMenuItem(title: "Son à l'arrivée d'un message", action: #selector(toggleSound(_:)), keyEquivalent: "")
        soundItem.target = self
        soundItem.state = soundEnabled ? .on : .off
        menu.addItem(soundItem)

        let photosItem = NSMenuItem(title: "Photos de profil…", action: #selector(openAvatarFolder), keyEquivalent: "")
        photosItem.target = self
        menu.addItem(photosItem)

        let updateItem = NSMenuItem(title: "Mettre à jour EK Backstage…", action: #selector(runUpdate), keyEquivalent: "")
        updateItem.target = self
        menu.addItem(updateItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quitter EK Backstage", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    @objc private func statusItemClicked() {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            // Afficher le menu sans qu'il remplace le clic gauche.
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            openCompose()
        }
    }

    @objc private func openCompose() {
        popup.openForWriting()
    }

    /// Ouvre le dossier des photos dans le Finder (créé au besoin).
    @objc private func openAvatarFolder() {
        try? FileManager.default.createDirectory(at: AvatarStore.folder, withIntermediateDirectories: true)
        NSWorkspace.shared.open(AvatarStore.folder)
    }

    /// Lance la mise à jour dans le Terminal (télécharge, recompile, relance l'app).
    @objc private func runUpdate() {
        let script = Config.fileURL.deletingLastPathComponent()
            .appendingPathComponent("Mettre à jour EK Backstage.command")
        NSWorkspace.shared.open(script)
    }

    // MARK: - Son

    private var soundEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "soundOn") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "soundOn") }
    }

    @objc private func toggleSound(_ item: NSMenuItem) {
        soundEnabled.toggle()
        item.state = soundEnabled ? .on : .off
        playSound() // aperçu
    }

    /// Son « Glass » de macOS, volume bas.
    private func playSound() {
        guard soundEnabled, let sound = NSSound(named: NSSound.Name("Glass")) else { return }
        sound.volume = 0.25
        sound.play()
    }
}
