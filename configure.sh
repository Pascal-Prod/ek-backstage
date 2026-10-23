#!/bin/bash
# Usage : ./configure.sh <ton prénom> <code secret du salon>
# Exemple : ./configure.sh Ema <code secret>
# Tout le monde utilise le même code secret, chacun avec son prénom.
set -euo pipefail

if [ $# -ne 2 ]; then
    echo "Usage : ./configure.sh <ton prénom> <code secret du salon>"
    exit 1
fi

ME="$1"
SECRET="$2"

if ! [[ "$ME" =~ ^[[:alnum:]\ \'-]+$ ]]; then
    echo "❌ Prénom invalide."
    exit 1
fi
if ! [[ "$SECRET" =~ ^[A-Za-z0-9_-]{20,64}$ ]]; then
    echo "❌ Code secret invalide : 20 à 64 caractères, uniquement lettres sans accents, chiffres, - et _."
    exit 1
fi

DIR="$HOME/Library/Application Support/EK Backstage"
mkdir -p "$DIR"
cat > "$DIR/config.json" <<JSON
{
  "me": "$ME",
  "secret": "$SECRET"
}
JSON

echo "✅ Configuration enregistrée pour $ME."
