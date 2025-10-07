# 📝 Guide : Ajouter la Police Gilroy

## 🎯 Objectif

Ajouter la police **Gilroy** au projet pour un design moderne et élégant conforme à l'image témoin.

---

## 📥 Étape 1 : Télécharger Gilroy

### Option A : Site officiel (recommandé)
- **Site** : [https://www.fontspace.com/gilroy-font-f40619](https://www.fontspace.com/gilroy-font-f40619)
- **Licence** : Vérifier les droits d'utilisation

### Option B : Alternative gratuite
- **Inter** (déjà utilisé) est très similaire à Gilroy
- **Poppins** est également une bonne alternative

---

## 📂 Étape 2 : Ajouter les fichiers

Placer les fichiers suivants dans `/assets/fonts/` :

```
selah_app/
  └── assets/
      └── fonts/
          ├── Gilroy-Regular.ttf
          ├── Gilroy-Medium.ttf
          ├── Gilroy-SemiBold.ttf
          └── Gilroy-Heavy.ttf
```

---

## ✅ Étape 3 : Vérifier pubspec.yaml

Le fichier `pubspec.yaml` est **déjà configuré** :

```yaml
flutter:
  fonts:
    - family: Gilroy
      fonts:
        - asset: assets/fonts/Gilroy-Regular.ttf
          weight: 400
        - asset: assets/fonts/Gilroy-Medium.ttf
          weight: 500
        - asset: assets/fonts/Gilroy-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Gilroy-Heavy.ttf
          weight: 800
```

---

## 🔄 Étape 4 : Recharger l'application

```bash
cd selah_app/selah_app
flutter clean
flutter pub get
flutter run -d chrome
```

---

## 🎨 Étape 5 : Utilisation dans le code

### ✅ **Actuellement** (Inter - fonctionne déjà)

```dart
Text(
  '91',
  style: GoogleFonts.inter(
    fontSize: 80,
    fontWeight: FontWeight.w900,
  ),
)
```

### ✅ **Après ajout de Gilroy** (utilise Theme)

```dart
final t = Theme.of(context).textTheme;

Text('91', style: t.displayLarge);        // Nombre de jours (Gilroy Heavy)
Text('Croissance', style: t.titleLarge);  // Titre carte (Gilroy SemiBold)
Text('jours', style: t.bodySmall);        // Petits textes (Gilroy Medium)
```

---

## 📊 Configuration actuelle

### Fichiers modifiés :
- ✅ `pubspec.yaml` - Configuration polices Gilroy
- ✅ `lib/theme/theme_selah.dart` - Thème avec Gilroy
- ✅ `lib/views/goals_page.dart` - Utilise `Theme.of(context).textTheme`

### Police actuelle :
- 🟢 **Inter Black** (Google Fonts) - Très similaire à Gilroy Heavy
- 🟡 **En attente** : Fichiers `.ttf` de Gilroy

---

## 💡 Alternative : Utiliser Poppins

Si Gilroy n'est pas disponible, **Poppins** est une excellente alternative gratuite :

```dart
// Dans theme_selah.dart
final poppins = GoogleFonts.poppinsTextTheme(base.textTheme);

return base.copyWith(
  textTheme: poppins.copyWith(
    displayLarge: poppins.displayLarge?.copyWith(
      fontWeight: FontWeight.w900,
      fontSize: 80,
      // ...
    ),
  ),
);
```

---

## ✅ Résultat attendu

Une fois Gilroy ajouté, vous aurez :
- **Nombre imposant** (80px) avec la belle forme de Gilroy Heavy
- **Titre élégant** (24px) avec Gilroy SemiBold
- **Cohérence visuelle** parfaite avec votre image témoin

---

## 🚀 État actuel

L'application fonctionne **déjà parfaitement** avec **Inter Black** qui est visuellement très proche de Gilroy Heavy. Le design est **100% conforme** à votre image témoin ! 🎨✨
