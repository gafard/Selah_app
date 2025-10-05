# 🌿 Selah — Fichiers de Logo

Ce répertoire contient tous les fichiers de logo pour l'application Selah, organisés selon les meilleures pratiques de design.

## 📁 Structure des Fichiers

### Icônes
- `icon-blue-bg.svg` — Icône avec fond bleu (app stores)
- `icon-white-bg.svg` — Icône avec fond blanc
- `icon-monochrome.svg` — Version monochrome marine
- `icon-transparent.svg` — Version transparente (couleurs)
- `icon-mono-transparent.svg` — Version transparente (monochrome)

### Lockups (Icône + Texte)
- `lockup-horizontal.svg` — Lockup horizontal avec fond
- `lockup-stacked.svg` — Lockup empilé avec fond
- `lockup-horizontal-transparent.svg` — Lockup horizontal transparent

### Documentation
- `STYLE_GUIDE.md` — Guide complet de style et d'usage
- `brand-colors.css` — Tokens CSS pour les couleurs de marque
- `README.md` — Ce fichier

## 🎨 Concept du Logo

**Leaf-S** — Un S fluide qui se termine en feuille, symbolisant :
- **S** : Initiale de Selah (pause, méditation)
- **Feuille** : Croissance spirituelle, nature, apaisement
- **Formes douces** : Bien-être, accessibilité, modernité

## 🎯 Usage Recommandé

### Application Mobile
- **Icône app** : `icon-blue-bg.svg`
- **Splash screen** : `lockup-stacked.svg`
- **Header** : `lockup-horizontal-transparent.svg`

### Web
- **Favicon** : `icon-blue-bg.svg`
- **Header** : `lockup-horizontal-transparent.svg`
- **Footer** : `icon-mono-transparent.svg`

### Print & Marketing
- **En-tête** : `lockup-horizontal.svg`
- **Monochrome** : `icon-monochrome.svg`

## 📏 Tailles Minimales

- **Icône** : 16 px (favicon) / 48 px (UI)
- **Lockup horizontal** : 120 px de large
- **Lockup empilé** : 80 px de large

## 🎨 Couleurs Principales

- **Bleu Selah** : `#1553FF` (couleur principale)
- **Marine** : `#0B2B7E` (texte, contraste)
- **Sauge** : `#49C98D` (accent, apaisant)
- **Blanc** : `#FFFFFF` (fond, contraste)

## 📱 Exports Nécessaires

Pour une utilisation complète, générer également :

### PNG (différentes tailles)
- 16×16, 32×32, 48×48 px (favicons)
- 512×512 px (Google Play)
- 1024×1024 px (App Store)
- 400×400 px (réseaux sociaux)

### PDF
- Version vectorielle pour l'impression

## ⚠️ Règles d'Usage

1. **Respecter la zone de protection** (1× la hauteur du « s »)
2. **Utiliser les bonnes variantes** selon le contexte
3. **Maintenir la lisibilité** et l'accessibilité
4. **Ne pas modifier** les proportions ou couleurs
5. **Tester le contraste** sur différents fonds

## 🔗 Intégration

### Flutter
```dart
// Dans pubspec.yaml
assets:
  - assets/logos/

// Usage
Image.asset('assets/logos/icon-blue-bg.svg')
```

### CSS
```css
/* Importer les couleurs */
@import 'brand-colors.css';

/* Usage */
.logo { 
  background-image: url('icon-transparent.svg');
  vector-effect: non-scaling-stroke;
}
```

## 📞 Support

Pour toute question sur l'usage des logos ou demandes de nouvelles variantes, consulter le `STYLE_GUIDE.md` ou contacter l'équipe design.

---

*Fichiers créés pour l'application Selah — Méditation & Lecture Biblique*
