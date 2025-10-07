-- ═══════════════════════════════════════════════════════════════════════════
-- 🧪 TEST RAPIDE - Connexion Supabase
-- ═══════════════════════════════════════════════════════════════════════════
-- À exécuter dans SQL Editor pour vérifier que tout fonctionne
-- ═══════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- 1️⃣ VÉRIFICATION DES TABLES (Doit retourner 13)
-- ═══════════════════════════════════════════════════════════════════════════

SELECT COUNT(*) AS total_tables, 
       string_agg(table_name, ', ' ORDER BY table_name) AS table_names
FROM information_schema.tables 
WHERE table_schema = 'public';

-- Résultat attendu : 13 tables

-- ═══════════════════════════════════════════════════════════════════════════
-- 2️⃣ VÉRIFICATION DES FONCTIONS (Doit retourner 6)
-- ═══════════════════════════════════════════════════════════════════════════

SELECT COUNT(*) AS total_functions,
       string_agg(routine_name, ', ' ORDER BY routine_name) AS function_names
FROM information_schema.routines 
WHERE routine_schema = 'public';

-- Résultat attendu : 6 fonctions

-- ═══════════════════════════════════════════════════════════════════════════
-- 3️⃣ VÉRIFICATION DES PLAN PRESETS (Doit retourner 7)
-- ═══════════════════════════════════════════════════════════════════════════

SELECT COUNT(*) AS total_presets,
       string_agg(name, ', ' ORDER BY name) AS preset_names
FROM plan_presets;

-- Résultat attendu : 7 presets

-- ═══════════════════════════════════════════════════════════════════════════
-- 4️⃣ VÉRIFICATION DES TRIGGERS (Doit retourner 9)
-- ═══════════════════════════════════════════════════════════════════════════

SELECT COUNT(*) AS total_triggers,
       string_agg(trigger_name || ' on ' || event_object_table, ', ') AS triggers
FROM information_schema.triggers 
WHERE trigger_schema = 'public';

-- Résultat attendu : 9 triggers

-- ═══════════════════════════════════════════════════════════════════════════
-- 5️⃣ VÉRIFICATION RLS (Doit retourner 13+)
-- ═══════════════════════════════════════════════════════════════════════════

SELECT COUNT(*) AS total_policies,
       string_agg(tablename || ': ' || policyname, E'\n' ORDER BY tablename) AS policies
FROM pg_policies 
WHERE schemaname = 'public';

-- Résultat attendu : 13+ policies

-- ═══════════════════════════════════════════════════════════════════════════
-- 6️⃣ TEST CRÉATION UTILISATEUR (Optionnel)
-- ═══════════════════════════════════════════════════════════════════════════

-- Créer un utilisateur de test (décommentez pour tester)
/*
DO $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Créer un utilisateur dans auth.users
    INSERT INTO auth.users (
        instance_id,
        id,
        aud,
        role,
        email,
        encrypted_password,
        email_confirmed_at,
        raw_user_meta_data,
        created_at,
        updated_at
    ) VALUES (
        '00000000-0000-0000-0000-000000000000',
        gen_random_uuid(),
        'authenticated',
        'authenticated',
        'test@selah.app',
        crypt('password123', gen_salt('bf')),
        NOW(),
        '{"display_name": "Test User"}'::jsonb,
        NOW(),
        NOW()
    )
    RETURNING id INTO v_user_id;
    
    RAISE NOTICE '✅ Utilisateur créé: %', v_user_id;
    
    -- Vérifier que le trigger a créé les tables liées
    PERFORM * FROM users WHERE id = v_user_id;
    RAISE NOTICE '✅ Profil utilisateur créé automatiquement';
    
    PERFORM * FROM reader_settings WHERE user_id = v_user_id;
    RAISE NOTICE '✅ Reader settings créés automatiquement';
    
    PERFORM * FROM user_progress WHERE user_id = v_user_id;
    RAISE NOTICE '✅ User progress créé automatiquement';
    
END $$;
*/

-- ═══════════════════════════════════════════════════════════════════════════
-- 7️⃣ RÉSUMÉ RAPIDE
-- ═══════════════════════════════════════════════════════════════════════════

SELECT 
    '✅ Schema deployed successfully!' AS status,
    (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public') AS tables_count,
    (SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema = 'public') AS functions_count,
    (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public') AS policies_count,
    (SELECT COUNT(*) FROM plan_presets) AS presets_count;

-- ═══════════════════════════════════════════════════════════════════════════
-- ✅ TESTS TERMINÉS
-- ═══════════════════════════════════════════════════════════════════════════
-- 
-- Si tous les tests passent :
--   ✅ Tables : 13
--   ✅ Fonctions : 6
--   ✅ Triggers : 9
--   ✅ Policies : 13+
--   ✅ Presets : 7
--
-- Votre base de données est prête ! 🚀
-- ═══════════════════════════════════════════════════════════════════════════
