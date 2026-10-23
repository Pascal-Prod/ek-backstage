#!/bin/bash
# Installe ou met à jour EK Backstage avec la dernière version publiée.
#
# Première installation :
#   curl -fsSL https://raw.githubusercontent.com/Pascal-Prod/ek-backstage/main/install.sh | bash -s -- <Prénom> <code secret>
# Mise à jour (ou clic droit sur l'icône → « Mettre à jour EK Backstage… ») :
#   curl -fsSL https://raw.githubusercontent.com/Pascal-Prod/ek-backstage/main/install.sh | bash
set -euo pipefail

REPO="Pascal-Prod/ek-backstage"

if ! xcode-select -p >/dev/null 2>&1; then
    echo "Les outils de développement Apple sont nécessaires. Une fenêtre va s'ouvrir :"
    echo "clique sur « Installer », attends la fin, puis relance cette commande."
    xcode-select --install || true
    exit 1
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "⬇️  Téléchargement de la dernière version…"
curl -fsSL "https://github.com/$REPO/archive/refs/heads/main.zip" -o "$TMP/ek-backstage.zip"
unzip -q "$TMP/ek-backstage.zip" -d "$TMP"
SRC="$TMP/ek-backstage-main"

if [ $# -ge 2 ]; then
    bash "$SRC/configure.sh" "$1" "$2"
elif [ ! -f "$HOME/Library/Application Support/EK Backstage/config.json" ]; then
    echo "❌ Première installation : indique ton prénom et le code secret, par exemple :"
    echo "   curl -fsSL https://raw.githubusercontent.com/$REPO/main/install.sh | bash -s -- Ema <code secret>"
    exit 1
fi

echo "🔨 Compilation…"
bash "$SRC/build.sh"
