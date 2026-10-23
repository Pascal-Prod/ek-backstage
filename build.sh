#!/bin/bash
# Compile EK Backstage et l'installe dans ~/Applications.
set -euo pipefail
cd "$(dirname "$0")"

APP="build/EK Backstage.app"
rm -rf build
mkdir -p "$APP/Contents/MacOS"

xcrun --sdk macosx swiftc -O \
    -target "$(uname -m)-apple-macos13.0" \
    -o "$APP/Contents/MacOS/EKBackstage" \
    Sources/*.swift
cp Info.plist "$APP/Contents/Info.plist"
mkdir -p "$APP/Contents/Resources"
cp Resources/* "$APP/Contents/Resources/"
codesign --force --sign - "$APP"

# Ancien nom de l'app (« Souffleur ») : on la retire et on reprend ses réglages.
OLD_SUPPORT="$HOME/Library/Application Support/Souffleur"
NEW_SUPPORT="$HOME/Library/Application Support/EK Backstage"
if pkill -x Souffleur 2>/dev/null; then
    while pgrep -x Souffleur >/dev/null; do sleep 0.2; done
fi
rm -rf "$HOME/Applications/Souffleur.app"
if [ -d "$OLD_SUPPORT" ] && [ ! -d "$NEW_SUPPORT" ]; then
    mv "$OLD_SUPPORT" "$NEW_SUPPORT"
fi
rm -f "$NEW_SUPPORT/Mettre à jour Souffleur.command"

# Fermer l'ancienne version et attendre qu'elle soit vraiment arrêtée,
# sinon macOS refuse de relancer l'app (erreur -600).
if pkill -x EKBackstage 2>/dev/null; then
    while pgrep -x EKBackstage >/dev/null; do sleep 0.2; done
    sleep 0.5
fi
# Raccourci de mise à jour, ouvert depuis le menu de l'app (s'exécute dans le Terminal).
SUPPORT="$HOME/Library/Application Support/EK Backstage"
mkdir -p "$SUPPORT"
cat > "$SUPPORT/Mettre à jour EK Backstage.command" <<'CMD'
#!/bin/bash
curl -fsSL https://raw.githubusercontent.com/Pascal-Prod/ek-backstage/main/install.sh | bash
echo
read -n 1 -s -r -p "Appuie sur une touche pour fermer cette fenêtre."
CMD
chmod +x "$SUPPORT/Mettre à jour EK Backstage.command"

mkdir -p "$HOME/Applications"
rm -rf "$HOME/Applications/EK Backstage.app"
cp -R "$APP" "$HOME/Applications/"
open "$HOME/Applications/EK Backstage.app"
echo "✅ EK Backstage installé et lancé (~/Applications/EK Backstage.app)"
