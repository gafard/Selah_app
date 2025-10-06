# 🎨 Redesign de la Page Goals - Style ROI Onboarding

## ✅ Modifications Apportées

### **📱 Design iPhone Frame**
- **Status Bar** : Barre de statut iPhone avec heure, batterie, signal
- **Layout** : Design centré avec contraintes max-width 390px
- **Style** : Interface blanche moderne avec ombres subtiles

### **🎯 Header Modernisé**
- **Logo Selah** : Intégration du logo Selah avec texte
- **Bouton Login** : Bouton "Log in" en haut à droite
- **Style** : Design épuré et professionnel

### **🃏 Cards Section - Style ROI**
- **Cartes empilées** : Effet de pile avec rotation et échelle
- **Carte centrale** : Mise en évidence de la carte active
- **Animations** : Transitions fluides entre les cartes
- **Détails** : Affichage des informations uniquement sur la carte centrale

### **📋 Contenu des Cartes**
- **Image** : Gradient coloré avec icône du plan
- **Titre** : Nom du plan de méditation
- **Badge** : Indicateur de popularité avec icône trending
- **Détails** : Durée et description du plan
- **Boutons** : Actions "Commencer avec Selah" et "Commencer"

### **📝 Contenu Textuel**
- **Titre principal** : "Choisis ton plan de méditation."
- **Description** : Explication des avantages des plans
- **Style** : Typographie Inter avec hiérarchie claire

### **🔘 Navigation**
- **Pagination** : Points indicateurs animés
- **Boutons** : Navigation précédent/suivant
- **Bouton principal** : "Commencer" au centre
- **Style** : Boutons circulaires avec bordures

## 🎯 Fonctionnalités

### **1. Navigation par Slides**
- **3 plans** : Nouveau Testament, Psaumes, Proverbes
- **Rotation** : Cartes latérales avec rotation
- **Échelle** : Carte centrale agrandie
- **Opacité** : Cartes latérales semi-transparentes

### **2. Interactions**
- **Boutons navigation** : Précédent/Suivant
- **Sélection** : Carte centrale mise en évidence
- **Actions** : Création de plan avec feedback

### **3. Animations**
- **Transitions** : Animations fluides entre cartes
- **Pagination** : Points animés
- **Boutons** : Effets hover et press

## 🛠️ Code Modifié

### **Structure Principale :**
```dart
Widget _buildROIOnboardingPage(List<PlanPreset> presets) {
  return Container(
    child: Column(
      children: [
        _buildStatusBar(),           // Barre de statut iPhone
        _buildHeader(),              // Header avec logo
        _buildCardsSection(presets), // Section des cartes
        _buildTextContent(),         // Contenu textuel
        _buildPaginationDots(),      // Points de pagination
        _buildBottomNavigation(),    // Navigation du bas
      ],
    ),
  );
}
```

### **Cartes Empilées :**
```dart
Widget _buildCardsSection(List<PlanPreset> presets) {
  return Stack(
    children: presets.map((preset, index) {
      final isCenter = index == _currentSlide;
      return Transform.scale(
        scale: isCenter ? 1.0 : 0.85,
        child: Transform.rotate(
          angle: isCenter ? 0 : (index < _currentSlide ? -0.14 : 0.14),
          child: Opacity(
            opacity: isCenter ? 1.0 : 0.4,
            child: _buildPlanCard(preset, isCenter),
          ),
        ),
      );
    }).toList(),
  );
}
```

### **Status Bar iPhone :**
```dart
Widget _buildStatusBar() {
  return Container(
    height: 44,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('9:41'),                    // Heure
        Container(/* Batterie */),       // Indicateur batterie
        Row(/* Signal, WiFi, Battery */), // Icônes système
      ],
    ),
  );
}
```

## 📱 Interface Finale

### **Design iPhone :**
- **Status Bar** : Barre de statut complète
- **Layout** : Contraintes iPhone (390px max-width)
- **Style** : Interface blanche moderne

### **Cartes ROI :**
- **Empilement** : 3 cartes avec effet de pile
- **Rotation** : Cartes latérales inclinées
- **Échelle** : Carte centrale agrandie
- **Contenu** : Détails uniquement sur la carte active

### **Navigation :**
- **Pagination** : Points indicateurs animés
- **Boutons** : Navigation circulaire
- **Actions** : Bouton principal "Commencer"

## 🎉 Résultat Final

### **✅ Design Moderne :**
- **Style ROI** : Interface inspirée du design React
- **iPhone Frame** : Barre de statut et contraintes
- **Cartes empilées** : Effet visuel attractif

### **✅ UX Optimisée :**
- **Navigation intuitive** : Boutons clairs et accessibles
- **Feedback visuel** : Animations et transitions
- **Hiérarchie claire** : Information bien structurée

### **✅ Fonctionnalités :**
- **3 plans** : Nouveau Testament, Psaumes, Proverbes
- **Sélection** : Carte centrale mise en évidence
- **Actions** : Création de plan avec feedback

---

**🎉 La page Goals a été complètement redesignée avec un style ROI Onboarding moderne et attractif !**
