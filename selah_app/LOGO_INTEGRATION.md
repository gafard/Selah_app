# 🌿 Intégration du Logo Selah dans Flutter

## ✅ Ce qui a été fait

### 1. Fichiers de Logo Créés
- **5 variantes d'icônes** : fond bleu, fond blanc, monochrome, transparent, mono-transparent
- **3 variantes de lockups** : horizontal, empilé, horizontal-transparent
- **Guide de style complet** avec règles d'usage
- **Tokens CSS** pour les couleurs de marque

### 2. Widget Flutter Créé
- **`SelahLogo`** : Widget principal avec toutes les variantes
- **`SelahAppIcon`** : Widget spécialisé pour les icônes d'app
- **`SelahHeaderLogo`** : Widget pour les headers
- **`SelahSplashLogo`** : Widget pour les splash screens
- **`SelahFavicon`** : Widget pour les petites icônes

### 3. Intégration dans l'App
- **pubspec.yaml** : Ajout des assets et dépendance `flutter_svg`
- **home_page.dart** : Logo intégré dans l'en-tête
- **Exemple d'utilisation** : Fichier de démonstration

## 🚀 Comment utiliser

### Import du widget
```dart
import '../widgets/selah_logo.dart';
```

### Utilisation basique
```dart
// Icône simple
SelahLogo(
  variant: SelahLogoVariant.blueBg,
  size: 48,
)

// Widget spécialisé
SelahAppIcon(
  size: 64,
  useBlueBackground: true,
)

// Header avec logo
SelahHeaderLogo(
  height: 40,
  useTransparent: true,
)
```

### Variantes disponibles
```dart
enum SelahLogoVariant {
  blueBg,                    // Fond bleu (app stores)
  whiteBg,                   // Fond blanc
  monochrome,                // Monochrome marine
  transparent,               // Transparent avec couleurs
  monoTransparent,           // Transparent monochrome
  horizontal,                // Lockup horizontal avec fond
  stacked,                   // Lockup empilé avec fond
  horizontalTransparent,     // Lockup horizontal transparent
}
```

## 📱 Prochaines étapes recommandées

### 1. Mettre à jour l'icône de l'app
```bash
# Générer les PNG à partir des SVG
# Placer dans :
# - android/app/src/main/res/mipmap-*/ (différentes tailles)
# - ios/Runner/Assets.xcassets/AppIcon.appiconset/
```

### 2. Intégrer dans d'autres pages
```dart
// Dans les autres pages de l'app
AppBar(
  title: SelahHeaderLogo(height: 32),
  // ...
)
```

### 3. Créer un splash screen
```dart
// Page de splash screen
Scaffold(
  body: Center(
    child: SelahSplashLogo(size: 200),
  ),
)
```

### 4. Utiliser les couleurs de marque
```dart
// Importer les couleurs
import 'assets/logos/brand-colors.css';

// Utiliser dans le thème
ThemeData(
  primaryColor: Color(0xFF1553FF), // Bleu Selah
  // ...
)
```

## 🎨 Couleurs de marque

```dart
// Couleurs principales
const Color selahBlue = Color(0xFF1553FF);      // Bleu Selah
const Color selahMarine = Color(0xFF0B2B7E);    // Marine
const Color selahSage = Color(0xFF49C98D);      // Sauge
const Color selahWhite = Color(0xFFFFFFFF);     // Blanc
```

## 📏 Tailles recommandées

- **Icône app** : 48-64px
- **Header** : 32-40px
- **Splash screen** : 120-200px
- **Favicon** : 16-32px
- **Boutons** : 24-32px

## ⚠️ Règles d'usage

1. **Respecter la zone de protection** (1× la hauteur du « s »)
2. **Utiliser les bonnes variantes** selon le contexte
3. **Maintenir la lisibilité** et l'accessibilité
4. **Ne pas modifier** les proportions ou couleurs
5. **Tester le contraste** sur différents fonds

## 🔧 Dépannage

### Erreur "Asset not found"
```bash
flutter clean
flutter pub get
```

### Logo ne s'affiche pas
- Vérifier que `flutter_svg` est installé
- Vérifier le chemin des assets dans `pubspec.yaml`
- Redémarrer l'app après modification des assets

### Problème de taille
- Utiliser `width` et `height` plutôt que `size` pour les lockups
- Ajuster `BoxFit` si nécessaire

## 📚 Ressources

- **Guide de style** : `assets/logos/STYLE_GUIDE.md`
- **Exemple d'usage** : `lib/widgets/logo_usage_example.dart`
- **Tokens CSS** : `assets/logos/brand-colors.css`
- **Fichiers SVG** : `assets/logos/`

---

*Intégration réalisée pour l'application Selah — Méditation & Lecture Biblique*
