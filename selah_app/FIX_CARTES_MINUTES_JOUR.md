# 🔧 Fix - Affichage Minutes/Jour sur les Cartes

## ✅ Corrections Appliquées

### **1. Suppression des Noms de Livres**
```dart
// AVANT : Affichait les livres
Text(
  _getBooksForCard(preset),  // Ex: "Psaumes & Luc"
  ...
)

// APRÈS : Affiche les minutes/jour
Text(
  '${_userProfile?['durationMin'] as int? ?? preset.minutesPerDay ?? 15} min/jour',
  ...
)
```

### **2. Source des Minutes**
- ✅ **Priorité 1** : `_userProfile['durationMin']` (choix de l'utilisateur dans CompleteProfilePage)
- ✅ **Priorité 2** : `preset.minutesPerDay` (valeur du preset)
- ✅ **Fallback** : `15 min` (valeur par défaut)

---

## 🎯 Résultat Attendu

**Avant** :
```
Grâce et
Miséricorde
Psaumes & Luc        ← Noms des livres
```

**Après** :
```
Grâce et
Miséricorde
50 min/jour          ← Minutes/jour
```

---

## 🚀 Test

**Sur Android**, tapez `R` (hot restart) dans le terminal.

**Vous devriez maintenant voir** :
- ✅ **Nom de la carte** : En haut (3-4 mots, deux lignes)
- ✅ **Minutes/jour** : En bas du nom (Ex: "50 min/jour", "15 min/jour")
- ✅ **Plus de noms de livres** : Remplacés par les minutes

**Exemple de carte** :
```
11
semaines            ← Nombre de semaines + badge

Grâce et           ← Nom de la carte
Miséricorde        ← (deux lignes)

50 min/jour        ← Minutes/jour

[Choisir ce plan]  ← Bouton
```

**Affichage cohérent avec les choix de l'utilisateur !** ⏱️✨📱

