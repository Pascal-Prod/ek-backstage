# EK Backstage

Salon de consignes pour les lives d'Ema : Pascal et Charlotte envoient, Ema reçoit et répond en un clic.
Chacun reçoit tous les messages du salon, sauf les siens.

- À chaque consigne, un panneau apparaît **en haut à droite**, au-dessus de tout, avec un léger flash et un petit son (« Glass ») : la consigne, les réponses rapides **Oui / Non / Ok 👍**, un champ pour écrire, et dessous l'**historique** des 12 dernières heures (le plus récent en premier).
- Le panneau ne prend pas le focus : Ema reste sur son PDF. Les nouvelles consignes s'ajoutent en dessous.
- Il reste affiché **jusqu'au clic** sur la consigne. Après une réponse (rapide ou écrite), il reste **3 secondes** puis disparaît en fondu.
- **Clic sur l'icône** de la barre de menus ou **⌃⌥M** : ouvre le panneau pour écrire. Entrée envoie, Échap ou un clic ailleurs referme.
- **Clic droit sur l'icône** : état de la connexion, activer/couper le son, **Photos de profil…**, **Mettre à jour EK Backstage…**, Quitter.
- Chaque message s'affiche avec la photo de son auteur, comme dans WhatsApp (sinon, son initiale).
- Aux couleurs de la charte Ema Krusi 2026 (brun chocolat, crème, saumon), monogramme EK en filigrane de l'historique.

Les messages passent par [ntfy.sh](https://ntfy.sh), un service de notifications gratuit, sur un canal dont le nom est un code secret commun.

**Code secret** : 20 à 64 caractères (lettres sans accents, chiffres, `-`, `_`), impossible à deviner. Exemple de forme : 4–5 mots sans rapport + un nombre, reliés par des tirets. Le serveur étant public, quiconque connaît le code peut lire et écrire dans le salon : ne le mets jamais dans ce dépôt.

## Installation (sur chaque Mac)

Dans le Terminal, avec son prénom et le code secret commun :

```bash
curl -fsSL https://raw.githubusercontent.com/Pascal-Prod/ek-backstage/main/install.sh | bash -s -- Ema <code secret>
```

(`Pascal`, `Ema` ou `Charlotte`.) Le script télécharge la dernière version, l'installe dans `~/Applications` et la lance. S'il manque les outils de développement Apple, une fenêtre propose de les installer : relancer la commande ensuite.

Puis :
- **Photos de profil** : celles d'Ema, Pascal et Charlotte sont incluses dans l'app. Pour en remplacer une sur un Mac : clic droit sur l'icône → **Photos de profil…**, déposer une photo nommée avec le prénom (`ema.jpg`, `pascal.jpg`, `charlotte.jpg`).
- **Lancement automatique** : Réglages Système → Général → Ouverture → ajouter `EK Backstage` (dossier Applications du dossier personnel).

## Mise à jour

Clic droit sur l'icône → **Mettre à jour EK Backstage…** (ou la même commande que l'installation, sans prénom ni code).

## Recevoir sur iPhone (facultatif)

Dans l'app **ntfy** (App Store), s'abonner au canal `<code secret>`. On y verra aussi ses propres messages.
