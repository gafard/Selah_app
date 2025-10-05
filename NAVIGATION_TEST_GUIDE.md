# 🧭 Guide de Test de Navigation - Application Selah

## ✅ Tests à Effectuer

### **📱 Page Goals (FancyStackCarousel)**

#### **1. Navigation par Boutons :**
- **Bouton Précédent** : Cliquer sur le bouton gauche (chevron_left)
- **Bouton Suivant** : Cliquer sur le bouton droit (chevron_right)
- **Vérification** : Les cartes doivent changer avec animation

#### **2. Navigation par Swipe :**
- **Swipe Gauche** : Glisser vers la gauche pour aller à la carte suivante
- **Swipe Droite** : Glisser vers la droite pour aller à la carte précédente
- **Vérification** : Transitions fluides entre les cartes

#### **3. Pagination :**
- **Points indicateurs** : Vérifier que les points changent selon la carte active
- **Animation** : Les points doivent s'animer lors du changement

#### **4. Bouton "Commencer" :**
- **Fonctionnalité** : Cliquer sur "Commencer" doit créer le plan de la carte active
- **Feedback** : Afficher un message de succès
- **Navigation** : Rediriger vers la page d'accueil

### **🏠 Navigation Principale**

#### **1. Bottom Navigation :**
- **Paramètres** : Premier onglet
- **Accueil** : Deuxième onglet (centre)
- **Journal** : Troisième onglet
- **Spiritual Wall** : Quatrième onglet

#### **2. Pages avec Logo Selah :**
- **Home Page** : Logo dans le header
- **Spiritual Wall** : Logo dans l'AppBar
- **Profile Page** : Logo dans l'AppBar
- **Settings Page** : Logo dans l'AppBar
- **Journal Page** : Logo dans l'AppBar
- **Prayer Generator** : Logo dans l'AppBar

### **🎨 Pages Redesignées**

#### **1. Complete Profile Page :**
- **Header** : "Personnalise ta méditation"
- **Bouton** : "Continue" (au lieu de "Continue with 3")
- **Dropdowns** : Version Bible, Type méditation, Ambiance
- **Time Picker** : Heure scrollable avec alarme
- **Navigation** : Retour vers l'accueil

#### **2. Goals Page (ROI Style) :**
- **Status Bar** : Barre de statut iPhone
- **Header** : Logo Selah + bouton Login
- **Carousel** : 3 cartes avec FancyStackCarousel
- **Navigation** : Boutons et swipe fonctionnels

### **🔄 Flux de Navigation**

#### **1. Onboarding :**
```
Splash → Welcome → Complete Profile → Goals → Home
```

#### **2. Navigation Principale :**
```
Home ↔ Settings ↔ Journal ↔ Spiritual Wall
```

#### **3. Pages Méditation :**
```
Home → Meditation Chooser → Meditation Pages
```

#### **4. Pages Prière :**
```
Home → Prayer Generator → Prayer Workflow
```

## 🧪 Tests Spécifiques

### **✅ FancyStackCarousel :**
1. **Chargement** : Vérifier que les 3 cartes se chargent
2. **Animations** : Transitions fluides entre cartes
3. **Contrôleur** : Boutons précédent/suivant fonctionnels
4. **Callback** : onPageChanged met à jour _currentSlide
5. **Bouton Commencer** : Utilise la carte active

### **✅ Logo Integration :**
1. **Affichage** : Logo visible sur toutes les pages principales
2. **Taille** : Tailles appropriées (28-48px)
3. **Style** : Cohérent avec le design
4. **Performance** : Chargement rapide

### **✅ Navigation Flow :**
1. **Routes** : Toutes les routes fonctionnent
2. **Retour** : Boutons retour fonctionnels
3. **Transitions** : Animations fluides
4. **État** : Préservation de l'état entre pages

## 🐛 Problèmes Potentiels

### **⚠️ FancyStackCarousel :**
- **API Changes** : Vérifier la compatibilité de l'API
- **Performance** : Animations fluides
- **Memory** : Pas de fuites mémoire

### **⚠️ Navigation :**
- **GoRouter** : Erreurs de contexte
- **State** : Perte d'état entre pages
- **Back Button** : Comportement correct

### **⚠️ UI/UX :**
- **Overflow** : Pas de débordement de contenu
- **Responsive** : Adaptation aux différentes tailles
- **Accessibility** : Support des lecteurs d'écran

## 📋 Checklist de Test

### **🎯 Fonctionnalités Principales :**
- [ ] FancyStackCarousel fonctionne
- [ ] Navigation par boutons
- [ ] Navigation par swipe
- [ ] Pagination animée
- [ ] Bouton "Commencer" fonctionnel
- [ ] Logo Selah sur toutes les pages
- [ ] Bottom navigation
- [ ] Complete Profile Page
- [ ] Goals Page (ROI style)

### **🎨 Design :**
- [ ] Status bar iPhone
- [ ] Header avec logo
- [ ] Cartes empilées
- [ ] Animations fluides
- [ ] Couleurs cohérentes
- [ ] Typographie Inter

### **🔄 Navigation :**
- [ ] Toutes les routes
- [ ] Boutons retour
- [ ] Transitions
- [ ] État préservé
- [ ] Pas d'erreurs

---

**🎉 Testez toutes ces fonctionnalités pour vérifier que l'application fonctionne correctement !**