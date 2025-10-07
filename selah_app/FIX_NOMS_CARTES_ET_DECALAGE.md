# 🔧 Fix - Noms Cartes + Décalage Nombre

## ✅ Corrections Appliquées

### **1. Noms de Cartes Uniques**
```dart
// AVANT : Noms génériques identiques
return 'Prière\nQuotidienne';  // Toujours pareil
return 'Sagesse\nDivine';      // Toujours pareil

// APRÈS : Vrais noms des presets
final name = preset.name;  // ✅ Utilise le vrai nom
// Raccourcit intelligemment si trop long
if (name.length > 20) {
  final words = name.split(' ');
  return '${words[0]}\n${words[1]}';
}
```

### **2. Décalage du Nombre Corrigé**
```dart
// AVANT : Décalage visuel
top: 24, left: 24, fontSize: 92, height: 0.75

// APRÈS : Alignement parfait
top: 20, left: 20,    // ✅ Position ajustée
fontSize: 88,         // ✅ Taille réduite (92→88)
height: 0.8,          // ✅ Height ajusté (0.75→0.8)
```

---

## 🎯 Résultat Attendu

**Avant** :
- ❌ Toutes les cartes ont des noms génériques similaires
- ❌ Le nombre "11" a un décalage visuel

**Après** :
- ✅ **Noms uniques** : Chaque carte affiche son vrai nom de preset
- ✅ **Alignement parfait** : Le nombre "11" est parfaitement aligné
- ✅ **Noms intelligents** : Raccourcissement automatique si trop long

---

## 🚀 Test

**Sur Android** :
1. Tapez `R` (hot restart) dans le terminal
2. ✅ Vérifiez que chaque carte a un nom unique
3. ✅ Vérifiez que le nombre "11" est parfaitement aligné
4. ✅ Les noms s'adaptent automatiquement à la longueur

**Exemples de noms attendus** :
- "Comme l'épi qui mûrit"
- "De la force en force"  
- "La graine qui grandit"
- etc. (vrais noms des presets)

**Plus de noms génériques identiques !** 🎨✨📱
