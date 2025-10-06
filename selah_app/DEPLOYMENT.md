# 🚀 Guide de Déploiement Selah

Ce guide vous accompagne pour déployer l'API Supabase et configurer l'application Flutter.

## 📋 Prérequis

- [Supabase CLI](https://supabase.com/docs/guides/cli) installé
- Compte Supabase créé
- Flutter SDK installé

## 🔧 1. Configuration Supabase

### Créer un projet Supabase

1. Allez sur [supabase.com](https://supabase.com)
2. Créez un nouveau projet
3. Notez votre **Project URL** et **anon key**

### Configurer les variables d'environnement

Créez un fichier `.env` dans le dossier `selah_app/` :

```bash
# .env
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

## 🗄️ 2. Déployer la Base de Données

### Appliquer les migrations

```bash
cd selah_app
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
```

### Vérifier les tables

Connectez-vous à votre dashboard Supabase et vérifiez que les tables `plans` et `plan_days` sont créées.

## ⚡ 3. Déployer les Edge Functions

### Déployer toutes les fonctions

```bash
# Déployer toutes les fonctions d'un coup
./supabase/deploy.sh

# Ou manuellement :
supabase functions deploy plans-from-preset
supabase functions deploy plans-import
supabase functions deploy plans-active
supabase functions deploy plans-days
supabase functions deploy plans-set-active
supabase functions deploy plans-progress
```

### Vérifier le déploiement

```bash
supabase functions list
```

## 🔐 4. Configurer l'Authentification

### Activer l'authentification anonyme (pour les tests)

Dans votre dashboard Supabase :
1. Allez dans **Authentication** > **Settings**
2. Activez **Enable anonymous sign-ins**

### Ou configurer l'authentification par email

1. Allez dans **Authentication** > **Settings**
2. Configurez **Site URL** : `http://localhost:3000` (pour le dev)
3. Activez **Enable email confirmations** si nécessaire

## 📱 5. Configurer l'App Flutter

### Mettre à jour les variables d'environnement

Dans `selah_app/lib/main.dart`, remplacez :

```dart
await Supabase.initialize(
  url: const String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://your-project.supabase.co'),
  anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'your-anon-key'),
);
```

Par vos vraies valeurs.

### Compiler avec les variables d'environnement

```bash
# Pour le développement
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key

# Pour la production
flutter build apk --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

## 🧪 6. Tester l'Intégration

### Test de l'API

```bash
cd supabase
./test-api.sh
```

### Test de l'app Flutter

1. Lancez l'app : `flutter run`
2. Allez dans **Goals Page**
3. Sélectionnez un preset
4. Vérifiez que le plan est créé dans Supabase

## 🔍 7. Vérifications

### Dashboard Supabase

- ✅ Tables `plans` et `plan_days` créées
- ✅ Edge Functions déployées
- ✅ Authentification configurée
- ✅ RLS activé

### App Flutter

- ✅ Connexion à Supabase réussie
- ✅ Création de plans depuis GoalsPage
- ✅ Import de plans depuis CustomPlanGeneratorPage
- ✅ Synchronisation offline/online

## 🚨 Dépannage

### Erreur de connexion

```bash
# Vérifier la configuration
supabase status

# Vérifier les logs
supabase functions logs plans-from-preset
```

### Erreur d'authentification

- Vérifiez que l'authentification anonyme est activée
- Ou implémentez une authentification par email

### Erreur de CORS

Les Edge Functions incluent déjà la configuration CORS. Si vous avez des problèmes :

1. Vérifiez que les headers CORS sont présents
2. Testez avec un client HTTP (Postman, curl)

## 📊 8. Monitoring

### Logs des fonctions

```bash
supabase functions logs --follow
```

### Métriques

- Dashboard Supabase > **Logs** > **Edge Functions**
- Dashboard Supabase > **Database** > **Logs**

## 🔄 9. Mise à jour

### Mettre à jour les fonctions

```bash
supabase functions deploy FUNCTION_NAME
```

### Mettre à jour la base de données

```bash
supabase db push
```

## 📞 Support

- [Documentation Supabase](https://supabase.com/docs)
- [Documentation Flutter](https://flutter.dev/docs)
- [Issues GitHub](https://github.com/your-repo/issues)

---

🎉 **Félicitations !** Votre API Selah est maintenant déployée et prête à l'emploi !
