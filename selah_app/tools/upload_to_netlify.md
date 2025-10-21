# Guide d'upload vers Netlify (Gratuit)

## 📋 Étapes rapides :

### 1. Préparer les fichiers
```bash
# Créer un dossier pour Netlify
mkdir netlify-upload
cp tools/export_bsb/*.gz netlify-upload/
```

### 2. Upload sur Netlify
1. Allez sur [netlify.com](https://netlify.com)
2. Cliquez sur "Add new site" → "Deploy manually"
3. Glissez-déposez le dossier `netlify-upload`
4. Attendez le déploiement (2-3 minutes)

### 3. Obtenir les URLs
Votre site sera disponible à : `https://votre-nom-site.netlify.app`

Les fichiers seront accessibles via :
- `https://votre-nom-site.netlify.app/topics_links.jsonl.gz`
- `https://votre-nom-site.netlify.app/concordance.jsonl.gz`

### 4. Mettre à jour l'app
```dart
// Dans BSBConfig
static const String baseUrl = 'https://votre-nom-site.netlify.app';
```

## 🔧 Alternative : GitHub Releases

### 1. Créer un repository
```bash
git init
git add tools/export_bsb/*.gz
git commit -m "Add BSB data files"
git remote add origin https://github.com/votre-username/selah-bsb-data.git
git push -u origin main
```

### 2. Créer une release
1. Allez sur GitHub → Releases
2. Cliquez "Create a new release"
3. Uploadez les fichiers .gz
4. Publiez la release

### 3. URLs des fichiers
- `https://github.com/votre-username/selah-bsb-data/releases/download/v1.0.0/topics_links.jsonl.gz`
- `https://github.com/votre-username/selah-bsb-data/releases/download/v1.0.0/concordance.jsonl.gz`



