import AppKit
import SwiftUI

/// Photos de profil, lues dans ~/Library/Application Support/EK Backstage/avatars/<prénom>.jpg
/// (ou .jpeg, .png, .heic). Sans photo : un rond avec l'initiale.
enum AvatarStore {
    static var folder: URL {
        Config.fileURL.deletingLastPathComponent().appendingPathComponent("avatars")
    }

    private static var cache: [String: NSImage] = [:]

    static func image(for name: String) -> NSImage? {
        let key = slug(name)
        if let cached = cache[key] { return cached }
        for ext in ["jpg", "jpeg", "png", "heic"] {
            let url = folder.appendingPathComponent("\(key).\(ext)")
            if let image = NSImage(contentsOf: url) {
                cache[key] = image
                return image
            }
        }
        return nil
    }

    /// « Éma » → « ema », pour retrouver le fichier quel que soit l'accent ou la casse.
    static func slug(_ name: String) -> String {
        name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
            .lowercased()
            .filter { $0.isASCII && $0.isLetter }
    }
}

struct Avatar: View {
    let name: String
    var size: CGFloat = 28

    var body: some View {
        Group {
            if let image = AvatarStore.image(for: name) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Theme.saumon.opacity(0.35)
                    Text(String(name.prefix(1)).uppercased())
                        .font(.system(size: size * 0.45, weight: .semibold))
                        .foregroundColor(Theme.creme)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(Theme.creme.opacity(0.25), lineWidth: 1))
    }
}
