# 🌿 Selah — Guide d'Identité Visuelle

## 🎨 Palette de Couleurs

### Couleurs Principales
- **Indigo Selah** : `#2B1E75` - Couleur primaire approuvée
- **Marine** : `#0B2B7E` - Couleur secondaire
- **Sauge** : `#49C98D` - Couleur d'accent
- **Blanc** : `#FFFFFF` - Couleur neutre

### Utilisation dans Flutter
```dart
import '../widgets/selah_logo.dart';

// Couleurs
SelahColors.primary    // #2B1E75
SelahColors.marine     // #0B2B7E
SelahColors.sage       // #49C98D
SelahColors.white      // #FFFFFF

// Dégradés
SelahGradients.primary // Dégradé principal
SelahGradients.sage    // Dégradé sauge
```

## 🏷️ Logos Disponibles

### 1. Badge Rond (Recommandé)
```dart
SelahLogo.round(size: 80)
```
- **Usage** : Icône d'application, favicon, boutons
- **Format** : SVG vectoriel
- **Fond** : Indigo Selah avec "s" blanc et accent sauge

### 2. Badge Carré Arrondi
```dart
SelahLogo.squircle(size: 80)
```
- **Usage** : Alternative moderne, interfaces mobiles
- **Format** : SVG vectoriel
- **Style** : Squircle avec coins arrondis

### 3. Icône Transparente
```dart
SelahLogo.transparent(size: 60)
```
- **Usage** : Fond clair, navigation, éléments UI
- **Format** : SVG vectoriel
- **Style** : S fluide + feuille, sans fond

### 4. Wordmark
```dart
SelahLogo.wordmark(width: 200, height: 50)
```
- **Usage** : En-têtes, signatures, documents
- **Format** : SVG vectoriel
- **Police** : Outfit, Manrope, Nunito Sans

### 5. Lockup Horizontal
```dart
SelahLogo.lockupHorizontal(width: 300, height: 80)
```
- **Usage** : En-têtes de page, bannières
- **Composition** : Logo rond + wordmark

### 6. Lockup Empilé
```dart
SelahLogo.lockupStacked(width: 200, height: 250)
```
- **Usage** : Centré, cartes, présentations
- **Composition** : Logo rond au-dessus du wordmark

## 📱 Intégration dans l'Application

### Page d'Accueil
```dart
// Logo principal avec ombre
Container(
  width: 80,
  height: 80,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: SelahColors.primary.withOpacity(0.3),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  ),
  child: SelahLogo.round(size: 80),
)
```

### Navigation
```dart
// Boutons avec couleurs Selah
_buildNavButton(
  context,
  title: 'Fonctionnalité',
  subtitle: 'Description',
  route: '/route',
  icon: Icons.icon,
  color: SelahColors.sage, // ou primary, marine
)
```

### Dégradés de Fond
```dart
Container(
  decoration: const BoxDecoration(
    gradient: SelahGradients.primary,
  ),
  child: // Contenu
)
```

## 🎯 Règles d'Usage

### ✅ À Faire
- Utiliser le badge rond comme icône principale
- Respecter les proportions (minimum 16px)
- Maintenir le contraste sur fond clair
- Utiliser les couleurs dans l'ordre d'importance

### ❌ À Éviter
- Déformer les logos
- Changer les couleurs sans autorisation
- Utiliser sur fond de couleur similaire
- Réduire en dessous de 16px

## 📐 Tailles Recommandées

### Icônes d'Application
- **iOS/App Store** : 1024×1024px
- **Android/Play** : 512×512px
- **Favicon Web** : 16, 32, 48, 180px

### Interface Utilisateur
- **Navigation** : 24-32px
- **Boutons** : 40-56px
- **En-têtes** : 80-120px
- **Bannières** : 200-400px

## 🔧 Fichiers Assets

### SVG (Vectoriels)
- `assets/svg/logo_round.svg`
- `assets/svg/logo_squircle.svg`
- `assets/svg/icon_transparent.svg`
- `assets/svg/wordmark.svg`
- `assets/svg/lockup_horizontal.svg`
- `assets/svg/lockup_stacked.svg`

### CSS Tokens
- `assets/css/selah_tokens.css`

### Widget Flutter
- `lib/widgets/selah_logo.dart`

## 🚀 Exemples d'Utilisation

### Page de Bienvenue
```dart
Column(
  children: [
    SelahLogo.round(size: 120),
    const SizedBox(height: 24),
    SelahLogo.wordmark(width: 200, height: 50),
  ],
)
```

### Navigation
```dart
AppBar(
  title: SelahLogo.wordmark(width: 120, height: 30),
  backgroundColor: SelahColors.primary,
)
```

### Boutons
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: SelahColors.sage,
    foregroundColor: SelahColors.white,
  ),
  child: Text('Action'),
)
```

---

**🎨 L'identité visuelle Selah est maintenant intégrée et prête à l'emploi !**
