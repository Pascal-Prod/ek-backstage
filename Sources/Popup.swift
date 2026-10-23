import AppKit
import SwiftUI

/// Messages du salon (reçus et envoyés), dans l'ordre d'arrivée.
final class HistoryStore: ObservableObject {
    @Published private(set) var entries: [IncomingMessage] = []

    func add(_ messages: [IncomingMessage]) {
        let known = Set(entries.map(\.id))
        entries.append(contentsOf: messages.filter { !known.contains($0.id) })
        if entries.count > 200 {
            entries.removeFirst(entries.count - 200)
        }
    }
}

final class PopupModel: ObservableObject {
    /// Consignes reçues, affichées en haut jusqu'au clic ou à la réponse.
    @Published var incoming: [IncomingMessage] = []
    @Published var flash = false
    @Published var draft = ""
    /// Incrémenté pour donner le focus au champ de saisie.
    @Published var focusRequest = 0
}

/// Le panneau unique : consignes reçues + réponses rapides, champ de saisie, historique.
struct PopupView: View {
    @ObservedObject var model: PopupModel
    @ObservedObject var store: HistoryStore
    let placeholder: String
    let quickReplies: [String]
    let onReply: (String) -> Void
    let onDismiss: () -> Void
    let onCancel: () -> Void
    let onTyping: () -> Void
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            if !model.incoming.isEmpty {
                incomingSection
                Rectangle().fill(Theme.creme.opacity(0.15)).frame(height: 1)
            }
            inputField.padding(10)
            Rectangle().fill(Theme.creme.opacity(0.15)).frame(height: 1)
            history
        }
        .frame(width: 360)
        .background(Theme.brunChocolat.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .onChange(of: model.focusRequest) { _ in focused = true }
        .onChange(of: model.draft) { text in
            if !text.isEmpty { onTyping() }
        }
    }

    // MARK: Consignes reçues

    private var incomingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(model.incoming) { message in
                HStack(alignment: .top, spacing: 10) {
                    Avatar(name: message.sender, size: 34)
                    VStack(alignment: .leading, spacing: 2) {
                        header(sender: message.sender, date: message.date, color: Theme.saumon)
                        Text(message.text)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Theme.creme)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            HStack(spacing: 6) {
                ForEach(quickReplies, id: \.self) { reply in
                    Button(reply) { onReply(reply) }
                        .buttonStyle(QuickReplyStyle())
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(Theme.ivoire.opacity(model.flash ? 0.9 : 0).allowsHitTesting(false))
        .contentShape(Rectangle())
        .onTapGesture(perform: onDismiss) // clic sur la consigne : on ferme
    }

    // MARK: Saisie

    private var canSend: Bool {
        !model.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func submit() {
        guard canSend else { return }
        onReply(model.draft.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private var inputField: some View {
        HStack(spacing: 8) {
            TextField("", text: $model.draft, prompt: Text(placeholder).foregroundColor(Theme.creme.opacity(0.45)))
                .textFieldStyle(.plain)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Theme.creme)
                .focused($focused)
                .onSubmit(submit)
                .onExitCommand(perform: onCancel)
            Button(action: submit) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(canSend ? Theme.saumon : Theme.creme.opacity(0.25))
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Capsule().fill(Theme.creme.opacity(0.12)))
    }

    // MARK: Historique

    /// Plus récent en premier, sans les consignes déjà affichées en haut.
    private var historyEntries: [IncomingMessage] {
        let shown = Set(model.incoming.map(\.id))
        return store.entries.filter { !shown.contains($0.id) }.reversed()
    }

    private var history: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                if historyEntries.isEmpty {
                    Text("Aucun autre message ces 12 dernières heures.")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.creme.opacity(0.5))
                }
                ForEach(historyEntries) { entry in
                    HistoryRow(entry: entry)
                }
            }
            .padding(12)
        }
        .frame(height: 240)
        .background(watermark)
    }

    /// Monogramme EK en filigrane, centré derrière l'historique.
    @ViewBuilder private var watermark: some View {
        if let image = Theme.monogramme {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 170)
                .opacity(0.07)
                .allowsHitTesting(false)
        }
    }

    private func header(sender: String, date: Date, color: Color) -> some View {
        (Text(sender).foregroundColor(color)
            + Text(" · \(date.formatted(date: .omitted, time: .shortened))")
                .foregroundColor(Theme.creme.opacity(0.55)))
            .font(.system(size: 11, weight: .medium))
    }
}

struct HistoryRow: View {
    let entry: IncomingMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !entry.mine { Avatar(name: entry.sender) }
            bubble
            if entry.mine { Avatar(name: entry.sender) }
        }
        .frame(maxWidth: .infinity, alignment: entry.mine ? .trailing : .leading)
    }

    private var bubble: some View {
        VStack(alignment: entry.mine ? .trailing : .leading, spacing: 3) {
            (Text(entry.mine ? "Moi" : entry.sender)
                .foregroundColor(entry.mine ? Theme.creme.opacity(0.55) : Theme.saumon)
                + Text(" · \(entry.date.formatted(date: .omitted, time: .shortened))")
                    .foregroundColor(Theme.creme.opacity(0.55)))
                .font(.system(size: 11, weight: .medium))
            Text(entry.text)
                .font(.system(size: 14, weight: entry.mine ? .regular : .semibold))
                .foregroundColor(Theme.creme)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(entry.mine ? Theme.saumon.opacity(0.22) : Theme.creme.opacity(0.08))
                )
        }
    }
}

struct QuickReplyStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(Theme.creme)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Capsule().fill(Theme.creme.opacity(configuration.isPressed ? 0.3 : 0.14)))
    }
}

/// Accepte le clic même quand EK Backstage n'est pas l'app active (Ema reste sur son PDF).
final class FirstClickHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

/// Panneau qui peut recevoir le clavier sans activer l'app (comme Spotlight) :
/// l'app d'Ema (son PDF) reste au premier plan.
final class KeyablePanel: NSPanel {
    var onCancel: (() -> Void)?
    override var canBecomeKey: Bool { true }
    override func cancelOperation(_ sender: Any?) { onCancel?() }
}

final class PopupController {
    private let panel: KeyablePanel
    private let model = PopupModel()
    private var fadeWork: DispatchWorkItem?
    /// Change à chaque annulation, pour ignorer la fin d'un fondu interrompu.
    private var fadeGeneration = 0
    var onSend: ((String) -> Void)?

    init(store: HistoryStore, placeholder: String, quickReplies: [String]) {
        panel = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 400),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .statusBar
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.appearance = NSAppearance(named: .darkAqua)
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        let view = PopupView(
            model: model,
            store: store,
            placeholder: placeholder,
            quickReplies: quickReplies,
            onReply: { [weak self] text in self?.reply(text) },
            onDismiss: { [weak self] in self?.close() },
            onCancel: { [weak self] in self?.close() },
            onTyping: { [weak self] in self?.cancelFade() }
        )
        panel.contentView = FirstClickHostingView(rootView: view)
        panel.onCancel = { [weak self] in self?.close() }

        NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in self?.lostFocus() }
    }

    /// Nouvelle consigne : affichée en haut, avec l'historique dessous, sans voler le focus.
    func receive(_ message: IncomingMessage) {
        cancelFade()
        model.incoming.append(message)
        present(focus: false)
        flash()
    }

    /// Ouvert depuis l'icône ou le raccourci : prêt à écrire.
    func openForWriting() {
        cancelFade()
        present(focus: true)
    }

    func toggleForWriting() {
        panel.isVisible && panel.isKeyWindow ? close() : openForWriting()
    }

    func close() {
        cancelFade()
        panel.orderOut(nil)
        model.incoming.removeAll()
        model.draft = ""
    }

    private func present(focus: Bool) {
        // SwiftUI met la vue à jour au tour de boucle suivant : on mesure après.
        DispatchQueue.main.async { [self] in
            reposition()
            if focus {
                panel.makeKeyAndOrderFront(nil)
                model.focusRequest += 1
            } else {
                panel.orderFrontRegardless()
            }
        }
    }

    private func reposition() {
        guard let content = panel.contentView,
              let screen = NSScreen.main ?? NSScreen.screens.first
        else { return }
        content.layoutSubtreeIfNeeded()
        let size = content.fittingSize
        let visible = screen.visibleFrame
        let origin = NSPoint(x: visible.maxX - size.width - 16, y: visible.maxY - size.height - 16)
        panel.setFrame(NSRect(origin: origin, size: size), display: true)
    }

    /// Réponse (rapide ou écrite) : envoyée, puis le panneau reste 3 s et disparaît en fondu.
    private func reply(_ text: String) {
        onSend?(text)
        model.draft = ""
        cancelFade()
        let generation = fadeGeneration
        let work = DispatchWorkItem { [weak self] in self?.fadeOut(generation: generation) }
        fadeWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: work)
    }

    private func fadeOut(generation: Int) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.8
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            guard let self, generation == fadeGeneration else { return }
            close()
        })
    }

    /// Annule un fondu prévu ou en cours (nouvelle consigne, on se remet à écrire…).
    private func cancelFade() {
        fadeWork?.cancel()
        fadeWork = nil
        fadeGeneration += 1
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0
            panel.animator().alphaValue = 1
        }
    }

    /// Ouvert juste pour écrire, sans consigne en attente : un clic ailleurs referme.
    private func lostFocus() {
        if model.incoming.isEmpty && fadeWork == nil && panel.isVisible {
            close()
        }
    }

    /// Léger flash ivoire sur la consigne (pas tout l'écran, pour ne pas éclairer le visage en live).
    private func flash() {
        DispatchQueue.main.async { [self] in
            model.flash = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [self] in
                withAnimation(.easeOut(duration: 0.7)) { model.flash = false }
            }
        }
    }
}
