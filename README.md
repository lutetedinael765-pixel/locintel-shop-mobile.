# LOCINTEL Shop — Flutter V0.2 (GitHub / source)

Ce dépôt est une **application Flutter catalogue multi-boutiques** utilisant l'API publique LOCINTEL Shop Odoo 18 V0.1.

## Démarrage

1. Créer un dépôt GitHub **vide** `locintel-shop-mobile` (sans README GitHub).
2. Ajouter à la racine **tout le contenu de cette archive**, y compris `.github/workflows`.
3. Dans GitHub → Settings → Secrets and variables → Actions → **Variables**, créer `SHOP_API_BASE` = l'URL HTTPS de votre instance Odoo, sans slash final.
4. GitHub → Actions → `LOCINTEL Shop - Android Test APK` → `Run workflow`.
5. Une fois le workflow réussi, télécharger l'artifact `LOCINTEL-Shop-Android-debug`.

Les workflows génèrent `android/` et `ios/` avec `flutter create`, car le SDK Flutter n'est pas installé dans l'environnement qui a produit cette archive. Ce code source n'est **pas encore compilé ni validé par flutter analyze**.

Pour développer localement : `flutter create --project-name locintel_shop --platforms=android,ios .`, puis `flutter pub get` et `flutter run --dart-define=SHOP_API_BASE=https://votre-site-odoo`.

## iOS

Le workflow iOS vérifie seulement la compilation **simulateur non signée**. Une IPA installable sur iPhone nécessite le bundle ID, le certificat Apple Distribution, un profil de provisioning et la signature adaptés au compte Apple Developer.

## Fonctionnalités

- Catalogue de boutiques, recherche locale de boutiques
- Logo, bannière, couleur configurée dans Odoo (les couleurs personnalisées sont exposées via API, thème dédié à finaliser)
- Grille produits, images, fiche produit, recherche serveur
- État d'erreur et réessai

**Non inclus :** panier transactionnel, commandes WhatsApp, statut stock en temps réel, paiement WonyaPay, authentification client et publication Store. Aucun bouton de paiement fictif n'est exposé.

## Limites / sécurité

Les APIs Odoo de V0.1 exposent des prix catalogue. Le prix final et les stocks devront être contrôlés par Odoo avant commande. Les images sont fournies par Odoo; pour les réseaux mobiles, prévoir cache/CDN et permissions CORS selon cible. N'exposez jamais de token WonyaPay dans Flutter.

**Note :** le workflow debug n'est pas une publication production; le package id généré doit être personnalisé avant signature ou diffusion.
