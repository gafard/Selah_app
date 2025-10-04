# Guide de Test de Navigation - Application Selah

## 🎯 **Tests de Navigation Principaux**

### 1. **Navigation vers les Pages de Méditation**

#### **Test 1: Page de Choix de Méditation**
- **Chemin**: Accueil → Méditation → Choix de méthode
- **Actions à tester**:
  - [ ] Cliquer sur "Méditation libre"
  - [ ] Cliquer sur "Méditation guidée (QCM)"
  - [ ] Cliquer sur "Test de compréhension (optionnel)"
- **Vérifications**:
  - [ ] Navigation correcte vers chaque page
  - [ ] Design moderne et cohérent
  - [ ] Gradients et animations fonctionnels

#### **Test 2: Méditation Libre**
- **Chemin**: Choix → Méditation libre
- **Actions à tester**:
  - [ ] Saisir du texte dans "Ce que Dieu m'enseigne"
  - [ ] Saisir du texte dans "Mes prochains"
  - [ ] Saisir du texte dans "Application aujourd'hui"
  - [ ] Saisir un verset à mémoriser
  - [ ] Cliquer sur "Continuer vers la prière"
- **Vérifications**:
  - [ ] Génération correcte des sujets de prière
  - [ ] Navigation vers PrayerCarouselPage
  - [ ] Sujets affichés avec catégories correctes

#### **Test 3: Méditation QCM**
- **Chemin**: Choix → Méditation guidée (QCM)
- **Actions à tester**:
  - [ ] Répondre aux questions QCM
  - [ ] Sélectionner plusieurs options
  - [ ] Ajouter du texte libre si disponible
  - [ ] Cliquer sur "Continuer vers la prière"
- **Vérifications**:
  - [ ] Collecte correcte des tags des options
  - [ ] Génération des sujets basés sur les tags
  - [ ] Navigation vers PrayerCarouselPage

### 2. **Navigation vers PrayerCarouselPage**

#### **Test 4: Carrousel de Prière**
- **Chemin**: Méditation → PrayerCarouselPage
- **Actions à tester**:
  - [ ] Glisser entre les sujets de prière
  - [ ] Marquer des sujets comme terminés
  - [ ] Appuyer longuement pour modifier un sujet
  - [ ] Cliquer sur "Terminer"
- **Vérifications**:
  - [ ] Affichage correct des sujets avec catégories
  - [ ] Gradients de couleur selon la catégorie
  - [ ] Animations fluides
  - [ ] Retour des sujets sélectionnés

### 3. **Navigation vers les Pages de Scan Bible**

#### **Test 5: Scan Bible Banner**
- **Chemin**: Pages avec ScanBibleBanner
- **Actions à tester**:
  - [ ] Cliquer sur le banner de scan
  - [ ] Navigation vers ScanBiblePage
- **Vérifications**:
  - [ ] Design cohérent du banner
  - [ ] Navigation fonctionnelle

#### **Test 6: Pages de Scan Bible**
- **Chemin**: Banner → ScanBiblePage / AdvancedScanBiblePage
- **Actions à tester**:
  - [ ] Interface de scan (placeholder)
  - [ ] Boutons de navigation
  - [ ] Retour à la page précédente
- **Vérifications**:
  - [ ] Design moderne et cohérent
  - [ ] Animations fonctionnelles
  - [ ] Navigation de retour

### 4. **Tests d'Intégration**

#### **Test 7: Flux Complet - Méditation Libre**
1. [ ] Accueil → Méditation → Méditation libre
2. [ ] Saisir des textes dans tous les champs
3. [ ] Continuer vers la prière
4. [ ] Vérifier les sujets générés
5. [ ] Sélectionner des sujets dans le carrousel
6. [ ] Terminer et vérifier le retour

#### **Test 8: Flux Complet - Méditation QCM**
1. [ ] Accueil → Méditation → Méditation guidée
2. [ ] Répondre aux questions QCM
3. [ ] Continuer vers la prière
4. [ ] Vérifier les sujets basés sur les tags
5. [ ] Sélectionner des sujets dans le carrousel
6. [ ] Terminer et vérifier le retour

### 5. **Tests de Robustesse**

#### **Test 9: Gestion des Erreurs**
- [ ] Navigation avec des données vides
- [ ] Navigation avec des données invalides
- [ ] Retour en arrière depuis chaque page
- [ ] Rotation d'écran (si applicable)

#### **Test 10: Performance**
- [ ] Temps de chargement des pages
- [ ] Fluidité des animations
- [ ] Responsivité de l'interface
- [ ] Gestion mémoire

## 🔧 **Points de Vérification Techniques**

### **Structure des Données**
- [ ] `PrayerSubject` avec `label` et `category`
- [ ] `PrayerSubjectsBuilder.fromFree()` avec `selectedTagsByField`
- [ ] `PrayerSubjectsBuilder.fromQcm()` avec `selectedOptionTags`
- [ ] Tags QCM correctement collectés

### **Navigation**
- [ ] `Navigator.push()` avec `MaterialPageRoute`
- [ ] Retour de données avec `Navigator.pop()`
- [ ] Gestion des arguments de navigation
- [ ] État des pages préservé

### **UI/UX**
- [ ] Design moderne et cohérent
- [ ] Gradients et couleurs appropriés
- [ ] Animations fluides
- [ ] Responsive design
- [ ] Accessibilité

## 📱 **Environnements de Test**

### **Appareils Recommandés**
- [ ] Émulateur Android (Pixel 6)
- [ ] Émulateur iOS (iPhone 14)
- [ ] Appareil physique Android
- [ ] Appareil physique iOS

### **Versions Flutter**
- [ ] Version actuelle du projet
- [ ] Compatibilité avec les dépendances

## 🐛 **Bugs Potentiels à Surveiller**

1. **Navigation**
   - Crash lors de la navigation
   - Perte de données entre pages
   - Problèmes de retour en arrière

2. **Génération de Sujets**
   - Sujets vides ou incorrects
   - Catégories manquantes
   - Tags non collectés

3. **UI/UX**
   - Animations saccadées
   - Problèmes de layout
   - Couleurs incorrectes

4. **Performance**
   - Lenteur de chargement
   - Fuites mémoire
   - Crash sur appareils anciens

## ✅ **Critères de Succès**

- [ ] Toutes les navigations fonctionnent
- [ ] Les sujets de prière sont générés correctement
- [ ] L'interface est moderne et fluide
- [ ] Aucun crash ou erreur critique
- [ ] Performance acceptable
- [ ] Compatibilité multi-plateforme

---

**Note**: Ce guide doit être utilisé pour tester systématiquement toutes les fonctionnalités de navigation après chaque modification majeure du code.
