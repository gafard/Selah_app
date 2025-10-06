# Structure des Pages de Méditation

## 📁 Organisation

### Pages Principales
- **`meditation_chooser_page.dart`** - Point d'entrée principal
  - Route: `/meditation/chooser`
  - 3 options de méditation

### Options de Méditation

#### 1. Méditation Libre
- **`meditation_free_page.dart`**
- Route: `/meditation/free`
- Fonctionnalités: Tags interactifs, génération de sujets de prière

#### 2. Méditation QCM Classique
- **`meditation_qcm_page.dart`**
- Route: `/meditation/qcm`
- Fonctionnalités: Questions prédéfinies, sélection multiple

#### 3. QCM Automatique
- **`meditation_auto_qcm_page.dart`**
- Route: `/meditation/auto_qcm`
- Fonctionnalités: Génération automatique depuis le texte

### Pages de Support
- **`prayer_subjects_page.dart`** - Sélection des sujets de prière
- **`passage_analysis_demo.dart`** - Démonstration d'analyse de passage

### Pages Obsolètes (à nettoyer)
- `meditation_page.dart` - Version simple obsolète
- `meditation_flow_page.dart` - Version complexe avec Riverpod (garder pour référence)

## 🎯 Navigation Recommandée

```
Page de Test → Nouveau Chooser → 
├── Option 1: Méditation Libre → Sujets de Prière
├── Option 2: QCM Classique
└── Option 3: QCM Automatique → Résultats
```

## 🔧 Modèles Associés
- `passage_analysis.dart` - Extraction de faits et génération de QCM
- `meditation_models.dart` - Modèles de méditation (anciens)
