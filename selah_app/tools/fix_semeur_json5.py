#!/usr/bin/env python3
import json
import json5

def fix_semeur_json():
    print('🔧 Réparation du fichier semeur.json avec JSON5...')
    
    try:
        # Lire le fichier
        with open('assets/bibles/semeur.json', 'r', encoding='utf-8') as f:
            content = f.read()
        
        print(f'📖 Fichier lu: {len(content)} caractères')
        
        # Parser avec JSON5
        try:
            data = json5.loads(content)
            print('✅ Parsing JSON5 réussi')
            
            # Convertir en JSON valide
            json_string = json.dumps(data, ensure_ascii=False, indent=2)
            
            # Sauvegarder le fichier réparé
            with open('assets/bibles/semeur_fixed.json', 'w', encoding='utf-8') as f:
                f.write(json_string)
            
            print('✅ Fichier réparé sauvegardé: semeur_fixed.json')
            
            # Vérifier que le JSON est valide
            try:
                json.loads(json_string)
                print('✅ JSON valide confirmé')
                return True
            except json.JSONDecodeError as e:
                print(f'❌ JSON invalide: {e}')
                return False
                
        except Exception as e:
            print(f'❌ Erreur de parsing JSON5: {e}')
            return False
            
    except Exception as e:
        print(f'❌ Erreur: {e}')
        return False

if __name__ == '__main__':
    fix_semeur_json()
