# 📚 Organisation des Pages de Méditation

## 🎯 **RECOMMANDATION PRINCIPALE**
**Utilisez TOUJOURS `/meditation/chooser` comme point d'entrée principal**

## 📋 **Structure Actuelle**

### ✅ **Pages Principales (À UTILISER)**
```
/meditation/chooser → Chooser principal avec 3 options
├── /meditation/free → Méditation libre avec tags
├── /meditation/qcm → QCM classique  
└── /meditation/auto_qcm → QCM automatique
```

### 🔄 **Pages de Support**
```
/prayer_subjects → Sélection des sujets de prière
/passage_analysis_demo → Démonstration d'analyse
```

### 📦 **Pages Anciennes (POUR RÉFÉRENCE UNIQUEMENT)**
```
/meditation → Ancienne page simple (obsolète)
/meditation/start → Flow complexe avec Riverpod (référence)
```

## 🚀 **Navigation Recommandée**

### Depuis la Page de Test :
1. Cliquez sur **"Nouveau Chooser"**
2. Choisissez votre option de méditation
3. Suivez le flow naturel

### Depuis le Code :
```dart
// ✅ CORRECT - Toujours utiliser le chooser
Navigator.pushNamed(context, '/meditation/chooser');

// ❌ ÉVITER - Routes directes (sauf cas spéciaux)
Navigator.pushNamed(context, '/meditation/free');
```

## 🔧 **Modèles et Services**

### Fichiers Principaux :
- `passage_analysis.dart` - Extraction de faits et QCM automatique
- `meditation_models.dart` - Modèles de données (anciens)

### Services :
- `ReaderSettingsService` - Paramètres de lecture
- `MeditationRepository` - Sauvegarde des méditations

## ⚠️ **Points d'Attention**

1. **Ne pas mélanger** les anciennes et nouvelles pages
2. **Toujours passer par le chooser** pour une expérience cohérente
3. **Les pages anciennes** sont conservées pour référence mais ne doivent pas être utilisées
4. **Tester** chaque option depuis le chooser principal

## 📱 **Flux d'Utilisation Typique**

```
Utilisateur → Page de Test → Nouveau Chooser → 
├── Option 1: Méditation Libre → Tags → Sujets de Prière
├── Option 2: QCM Classique → Questions prédéfinies
└── Option 3: QCM Automatique → Analyse → Correction
```

Cette organisation évite la confusion et assure une expérience utilisateur cohérente ! 🎉
