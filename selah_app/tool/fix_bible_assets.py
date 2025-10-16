#!/usr/bin/env python3
"""
Script pour corriger les fichiers JSON bibliques au format JavaScript/JSON non standard.
"""
import json
import re
import sys
from pathlib import Path

def fix_json_format(content):
    """Corrige le format JavaScript/JSON non standard vers JSON valide."""
    
    # Étape 1: Corriger les objets malformés {Text:"...",ID:2,Text:"..."}
    # Les remplacer par des tableaux [{Text:"...",ID:2},{Text:"...",ID:3}]
    
    # D'abord, échapper les guillemets dans les valeurs Text
    def escape_text_quotes(match):
        text_content = match.group(1)
        # Échapper tous les guillemets dans le contenu
        escaped_content = text_content.replace('"', '\\"')
        return f'Text:"{escaped_content}"'
    
    content = re.sub(r'Text:"([^"]*(?:"[^"]*)*[^"]*)"', escape_text_quotes, content)
    
    # Étape 2: Ajouter des guillemets autour des clés non-quotées
    def quote_keys(match):
        key = match.group(1).strip()
        if key.startswith('"') and key.endswith('"'):
            return match.group(0)  # Déjà quoté
        return f' "{key}":'
    
    content = re.sub(r'(?<=\{|,)\s*([A-Za-zÀ-ÿ0-9 _\-]+)\s*:', quote_keys, content)
    
    return content

def validate_structure(data, path):
    """Valide la structure attendue du JSON."""
    if 'Testaments' not in data:
        raise ValueError(f'❌ {path}: "Testaments" absent')
    
    testaments = data['Testaments']
    if not isinstance(testaments, list) or len(testaments) == 0:
        raise ValueError(f'❌ {path}: Testaments[] vide ou invalide')
    
    # Vérifier la structure du premier testament
    t0 = testaments[0]
    if not isinstance(t0, dict) or 'Books' not in t0:
        raise ValueError(f'❌ {path}: testaments[0].Books manquant')
    
    books = t0['Books']
    if not isinstance(books, list):
        raise ValueError(f'❌ {path}: testaments[0].Books n\'est pas une liste')
    
    if len(books) == 0:
        print(f'⚠️ {path}: Books[] vide dans le premier testament')
        return
    
    # Vérifier la structure du premier livre
    b0 = books[0]
    if not isinstance(b0, dict) or 'Chapters' not in b0:
        raise ValueError(f'❌ {path}: testaments[0].books[0].Chapters manquant')
    
    chapters = b0['Chapters']
    if not isinstance(chapters, list):
        raise ValueError(f'❌ {path}: testaments[0].books[0].Chapters n\'est pas une liste')
    
    if len(chapters) == 0:
        print(f'⚠️ {path}: Chapters[] vide pour le premier Book')
        return
    
    # Vérifier la structure du premier chapitre
    c0 = chapters[0]
    if not isinstance(c0, dict) or 'Verses' not in c0:
        raise ValueError(f'❌ {path}: ...Chapters[0].Verses manquant')
    
    verses = c0['Verses']
    if not isinstance(verses, list):
        raise ValueError(f'❌ {path}: ...Chapters[0].Verses n\'est pas une liste')
    
    if len(verses) == 0:
        print(f'⚠️ {path}: Verses[] vide pour le premier chapitre')
        return
    
    # Vérifier la structure du premier verset
    v0 = verses[0]
    if not isinstance(v0, dict) or 'Text' not in v0:
        raise ValueError(f'❌ {path}: ...Verses[0].Text manquant')
    
    if not isinstance(v0['Text'], str):
        raise ValueError(f'❌ {path}: ...Verses[0].Text n\'est pas une chaîne')

def fix_file(file_path):
    """Corrige un fichier JSON biblique."""
    path = Path(file_path)
    
    if not path.exists():
        raise FileNotFoundError(f'Fichier introuvable: {file_path}')
    
    # Lire le contenu (gérer le BOM UTF-8)
    with open(path, 'r', encoding='utf-8-sig') as f:
        raw_content = f.read()
    
    # Essayer de parser directement
    try:
        data = json.loads(raw_content)
    except json.JSONDecodeError:
        # Corriger le format
        fixed_content = fix_json_format(raw_content)
        try:
            data = json.loads(fixed_content)
        except json.JSONDecodeError as e:
            # Afficher le contenu partiel pour debug
            print(f'❌ {file_path}: JSON invalide même après correction')
            print(f'Erreur: {e}')
            print(f'Contenu partiel (200 chars): {fixed_content[:200]}...')
            raise ValueError(f'❌ {file_path}: JSON invalide même après correction: {e}')
    
    # Valider la structure
    validate_structure(data, file_path)
    
    # Réécrire en JSON propre
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    
    print(f'✅ Corrigé et validé: {file_path}')

def main():
    if len(sys.argv) < 2:
        print('Usage: python tool/fix_bible_assets.py <chemin1.json> <chemin2.json> ...')
        sys.exit(1)
    
    success = True
    for file_path in sys.argv[1:]:
        try:
            fix_file(file_path)
        except Exception as e:
            print(e)
            success = False
    
    if not success:
        sys.exit(1)

if __name__ == '__main__':
    main()