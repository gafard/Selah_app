#!/usr/bin/env python3
import json
import re

def fix_semeur_json():
    print('🔧 Réparation du fichier semeur.json avec Python...')
    
    try:
        # Lire le fichier
        with open('assets/bibles/semeur.json', 'r', encoding='utf-8') as f:
            content = f.read()
        
        print(f'📖 Fichier lu: {len(content)} caractères')
        
        # Nettoyer les caractères problématiques
        content = content.replace('\uFEFF', '')  # BOM
        content = content.replace('\r\n', '\n')
        content = content.replace('\r', '\n')
        
        # Remplacer les guillemets typographiques
        content = content.replace('\u201C', '"').replace('\u201D', '"')
        content = content.replace('\u201E', '"').replace('\u201F', '"')
        content = content.replace('\u00AB', '"').replace('\u00BB', '"')
        content = content.replace('\u2018', "'").replace('\u2019', "'")
        content = content.replace('\u2032', "'").replace('\u2033', '"')
        
        # Ajouter des guillemets autour des clés non-quotées
        content = re.sub(r'(^|\{|\[|,)\s*([A-Za-z_][A-Za-z0-9_\-]*)\s*:', r'\1 "\2":', content, flags=re.MULTILINE)
        
        # Corriger les sauts de ligne littéraux \n dans le JSON
        content = re.sub(r'"([^"]*)"\s*,\s*\\n\s*"([^"]*)"', r'"\1", "\2"', content)
        
        # Corriger les sauts de ligne dans les chaînes
        def fix_newlines_in_strings(match):
            text = match.group(0)
            # Remplacer les sauts de ligne par \n dans les chaînes
            text = text.replace('\n', '\\n')
            return text
        
        # Appliquer la correction aux chaînes
        content = re.sub(r'"[^"]*"', fix_newlines_in_strings, content)
        
        # Nettoyer les caractères de contrôle
        content = re.sub(r'[\x00-\x08\x0B\x0C\x0E-\x1F]', ' ', content)
        
        # Nettoyer les caractères non-ASCII problématiques
        content = re.sub(r'[^\x20-\x7E\u00C0-\u017F]', ' ', content)
        
        # Nettoyer les espaces multiples
        content = re.sub(r'\s{2,}', ' ', content)
        
        # Sauvegarder le fichier réparé
        with open('assets/bibles/semeur_fixed.json', 'w', encoding='utf-8') as f:
            f.write(content)
        
        print('✅ Fichier réparé sauvegardé: semeur_fixed.json')
        
        # Vérifier que le JSON est valide
        try:
            json.loads(content)
            print('✅ JSON valide confirmé')
            return True
        except json.JSONDecodeError as e:
            print(f'❌ JSON invalide: {e}')
            return False
            
    except Exception as e:
        print(f'❌ Erreur: {e}')
        return False

if __name__ == '__main__':
    fix_semeur_json()
