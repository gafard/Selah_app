# Selah - Application de Lecture Biblique

Une application Flutter moderne pour la lecture et l'étude de la Bible, conçue avec une architecture offline-first.

## 🚀 Fonctionnalités

- **Lecture biblique** avec support multi-versions
- **Plans de lecture personnalisés** générés dynamiquement
- **Méditation et prière** avec QCM interactifs
- **Journal spirituel** pour noter vos réflexions
- **Architecture offline-first** - fonctionne sans connexion
- **Synchronisation intelligente** avec Supabase
- **Interface moderne** style Calm/Superlist

## 🏗️ Architecture

### Services Offline-First
- **LocalStorageService** - Stockage local avec Hive
- **PlanService** - Gestion des plans de lecture
- **BibleDownloadService** - Téléchargement et cache des versions bibliques
- **ConnectivityService** - Détection de connectivité réseau
- **SyncQueueHive** - Synchronisation en arrière-plan

### Backend
- **Supabase** - Base de données et authentification
- **Edge Functions** - API pour la génération de plans
- **Hive** - Cache local pour fonctionnement offline

## 📱 Pages Principales

- **SplashPage** - Écran de démarrage avec logique de navigation
- **HomePage** - Tableau de bord principal avec progression
- **GoalsPage** - Sélection de plans de lecture personnalisés
- **CustomPlanGeneratorPage** - Générateur de plans sur mesure
- **ReaderPage** - Lecteur biblique moderne
- **MeditationPages** - Pages de méditation et QCM
- **JournalPage** - Journal spirituel

## 🛠️ Installation

### Prérequis
- Flutter 3.0+
- Dart 3.0+
- iOS Simulator ou Android Emulator
- Compte Supabase

### Configuration

1. **Cloner le repository**
```bash
git clone <repository-url>
cd selah_app
```

2. **Installer les dépendances**
```bash
flutter pub get
```

3. **Configurer Supabase**
```bash
# Créer un fichier .env dans selah_app/
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

4. **Lancer l'application**
```bash
# Web
flutter run -d chrome

# iOS
flutter run -d ios

# Android
flutter run -d android
```

## 🔧 Configuration Supabase

### Base de données
```sql
-- Tables principales
CREATE TABLE plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  name TEXT NOT NULL,
  total_days INTEGER NOT NULL,
  start_date DATE NOT NULL,
  is_active BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE plan_days (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID REFERENCES plans(id),
  day_index INTEGER NOT NULL,
  reading_refs JSONB NOT NULL,
  completed BOOLEAN DEFAULT false,
  completed_at TIMESTAMP
);
```

### Edge Functions
- `/plans/from-preset` - Création de plan depuis un preset
- `/plans/import` - Import de plan depuis ICS
- `/plans/active` - Récupération du plan actif
- `/plans/{id}/days` - Récupération des jours de lecture
- `/plans/{id}/set-active` - Activation d'un plan
- `/plans/{id}/days/{day}/progress` - Mise à jour du progrès

## 📦 Dépendances Principales

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  provider: ^6.1.5
  
  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # Backend
  supabase_flutter: ^2.5.6
  
  # Network
  http: ^1.2.2
  connectivity_plus: ^6.1.5
  
  # Background Tasks
  workmanager: ^0.5.2
  flutter_local_notifications: ^17.2.4
  
  # UI/UX
  google_fonts: ^6.2.1
  circle_nav_bar: ^1.0.2
  fancy_stack_carousel: ^1.0.0
  
  # Utils
  uuid: ^4.4.0
  path_provider: ^2.1.4
  timezone: ^0.9.4
```

## 🎨 Design System

### Couleurs
- **Primary**: `#4F46E5` (Indigo)
- **Secondary**: `#7C3AED` (Violet)
- **Background**: `#F5F5F5` (Light Gray)
- **Surface**: `#FFFFFF` (White)

### Typographie
- **Font Family**: Inter (Google Fonts)
- **Headings**: 24-32sp, FontWeight.bold
- **Body**: 16sp, FontWeight.normal
- **Caption**: 14sp, FontWeight.w500

## 🔄 Workflow Offline-First

1. **Données locales prioritaires** - Hive pour le cache
2. **Synchronisation en arrière-plan** - Workmanager
3. **Queue de synchronisation** - SyncQueueHive
4. **Fallback gracieux** - Fonctionne sans réseau

## 📊 Télémétrie

- **TelemetryConsole** - Logs d'événements
- **Analytics** - Suivi des interactions utilisateur
- **Performance** - Métriques de performance

## 🧪 Tests

```bash
# Tests unitaires
flutter test

# Tests d'intégration
flutter test integration_test/

# Tests de widgets
flutter test test/widget_test.dart
```

## 📝 Changelog

### v1.0.0
- Architecture offline-first complète
- Intégration Supabase
- Générateur de plans personnalisés
- Interface moderne Calm/Superlist
- Support multi-versions bibliques

## 🤝 Contribution

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/AmazingFeature`)
3. Commit les changements (`git commit -m 'Add some AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 📞 Support

Pour toute question ou problème, ouvrez une issue sur GitHub.

---

**Selah** - "Pause et réfléchis" ✨
