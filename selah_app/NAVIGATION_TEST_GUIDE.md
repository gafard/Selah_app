# 🧭 Guide de Test de Navigation - Selah App

## 📱 Pages Principales à Tester

### 1. **Flux d'Onboarding (Nouvel Utilisateur)**
- **Splash** → **Welcome** → **Auth** → **Complete Profile** → **Choose Plan** → **Onboarding** → **Congrats** → **Home**

### 2. **Pages de Plans de Lecture**

#### **Page de Choix de Plan (`/choose-plan`)**
- ✅ **Carousel de cartes** : Navigation avec les flèches
- ✅ **Sélection de plan** : Tap sur une carte pour sélectionner
- ✅ **Bouton "Importer depuis un générateur"** : Navigation vers import
- ✅ **Bouton "Générer un plan personnalisé"** : Navigation vers générateur
- ✅ **Pagination dots** : Indicateurs de progression

#### **Page de Génération Personnalisée (`/custom_plan_generator`)**
- ✅ **Nom du plan** : Champ de saisie
- ✅ **Date de début** : Sélecteur de date
- ✅ **Durée** : Slider de 30 à 730 jours
- ✅ **Ordre de lecture** : Dropdown (Traditional, Chronological, etc.)
- ✅ **Livres** : Dropdown (OT,NT / NT / OT / Gospels, etc.)
- ✅ **Jours de lecture** : Sélecteur visuel des jours
- ✅ **Version biblique** : Dropdown (NIV, ESV, KJV, etc.)
- ✅ **Bouton "Générer le plan"** : Création du plan

#### **Page d'Importation ICS (`/import_plan`)**
- ✅ **URL du fichier ICS** : Champ de saisie
- ✅ **Nom du plan** : Champ de saisie
- ✅ **Bouton "Importer le plan"** : Importation

### 3. **Pages d'Authentification**

#### **Page d'Auth (`/auth`)**
- ✅ **Toggle Login/Register** : Basculement entre modes
- ✅ **Champs de saisie** : Nom, Email, Mot de passe
- ✅ **Bouton "Se connecter/Créer un compte"** : Authentification
- ✅ **Bouton "Continuer avec Google"** : Auth sociale

### 4. **Pages de Configuration**

#### **Page Complete Profile (`/complete-profile`)**
- ✅ **Version de la Bible** : Dropdown
- ✅ **Heure de rappel** : Sélecteur d'heure
- ✅ **Durée de méditation** : Slider
- ✅ **Types de méditation** : Sélecteur multiple
- ✅ **Ambiances** : Sélecteur multiple
- ✅ **Bouton "Continuer"** : Sauvegarde et navigation

### 5. **Pages d'Onboarding**

#### **Onboarding Dynamique (`/onboarding`)**
- ✅ **Slides personnalisés** : Basés sur le profil utilisateur
- ✅ **Navigation** : Boutons Précédent/Suivant
- ✅ **Progression** : Barre de progression
- ✅ **Bouton "Commencer"** : Finalisation

#### **Page de Félicitations (`/congrats`)**
- ✅ **Animation de succès** : Icône avec effet élastique
- ✅ **Résumé des fonctionnalités** : Liste des éléments configurés
- ✅ **Bouton "Aller à l'accueil"** : Navigation vers home

## 🧪 Tests Fonctionnels

### **Test 1 : Flux Complet Nouvel Utilisateur**
1. Démarrer l'application
2. Passer par toutes les étapes d'onboarding
3. Vérifier que chaque étape sauvegarde les données
4. Arriver sur la page d'accueil

### **Test 2 : Génération de Plan Personnalisé**
1. Aller sur `/choose-plan`
2. Cliquer sur "Générer un plan personnalisé"
3. Configurer tous les paramètres
4. Générer le plan
5. Vérifier la création et l'importation

### **Test 3 : Importation de Plan ICS**
1. Aller sur `/choose-plan`
2. Cliquer sur "Importer depuis un générateur"
3. Saisir une URL ICS valide
4. Importer le plan
5. Vérifier l'importation

### **Test 4 : Navigation avec Guards**
1. Tester la redirection automatique selon l'état utilisateur
2. Vérifier que les utilisateurs non connectés sont redirigés vers `/welcome`
3. Vérifier que les utilisateurs sans profil complet vont vers `/complete-profile`
4. Vérifier que les utilisateurs sans plan vont vers `/choose-plan`

## 🎨 Tests d'Interface

### **Design et Thème**
- ✅ **Cohérence visuelle** : Gradient violet sombre sur toutes les pages
- ✅ **Typographie** : Google Fonts Inter avec poids cohérents
- ✅ **Espacement** : Padding et margins uniformes
- ✅ **Bordures** : Rayon de 12-16px pour tous les éléments

### **Composants Modernisés**
- ✅ **Champs de saisie** : Style uniforme avec icônes
- ✅ **Boutons** : Gradients et ombres cohérents
- ✅ **Dropdowns** : Fond sombre avec texte blanc
- ✅ **Navigation** : Boutons avec style moderne

## 🔧 Tests Techniques

### **Performance**
- ✅ **Chargement** : Temps de chargement des pages
- ✅ **Animations** : Fluidité des transitions
- ✅ **Mémoire** : Pas de fuites mémoire

### **Compatibilité**
- ✅ **Responsive** : Adaptation à différentes tailles d'écran
- ✅ **Accessibilité** : Contraste élevé et éléments tactiles
- ✅ **Navigation** : Boutons de retour et navigation cohérente

## 📋 Checklist de Test

### **Pages de Plans**
- [ ] Carousel de cartes fonctionne
- [ ] Sélection de plan avec date picker
- [ ] Génération de plan personnalisé
- [ ] Importation de plan ICS
- [ ] Navigation entre les pages

### **Authentification**
- [ ] Toggle Login/Register
- [ ] Validation des champs
- [ ] Authentification (simulée)
- [ ] Google Sign In (simulé)

### **Configuration**
- [ ] Tous les champs de profil
- [ ] Sauvegarde des préférences
- [ ] Navigation vers l'étape suivante

### **Onboarding**
- [ ] Slides dynamiques
- [ ] Navigation entre slides
- [ ] Finalisation de l'onboarding

### **Navigation Globale**
- [ ] Guards de redirection
- [ ] Navigation cohérente
- [ ] Retour en arrière
- [ ] État de l'application

## 🚀 Commandes de Test

```bash
# Lancer l'application
flutter run -d chrome

# Tester la compilation
flutter analyze

# Tester les routes
# Naviguer manuellement vers chaque page via l'interface
```

## 📝 Notes de Test

- **Simulation** : Les appels API sont simulés avec `Future.delayed`
- **Données Mock** : Utilisation de données de test pour l'onboarding
- **Navigation** : GoRouter avec guards intelligents
- **État** : Gestion d'état avec Provider et Riverpod

---

**🎯 Objectif** : Vérifier que toutes les pages fonctionnent correctement et que la navigation est fluide et intuitive.