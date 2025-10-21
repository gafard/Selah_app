#!/usr/bin/env python3
"""
Script pour analyser les fichiers JSON de bibles avec le bon encodage
"""

import json
import os

def analyze_bible_json_files():
    """Analyse les fichiers JSON de bibles avec UTF-8-sig"""
    print("🔍 Analyse des fichiers JSON de bibles (avec UTF-8-sig)")
    print("=" * 60)
    
    json_files = [
        "Darby.json",
        "Francais courant.json", 
        "French Louis Segond (1910).json",
        "Ostervald 1996.json",
        "Parole de Vie.json",
        "Segond 21 (S21).json",
        "Semeur.json"
    ]
    
    base_path = "/Users/gafardgnane/Downloads/Bibles versions"
    
    for filename in json_files:
        filepath = os.path.join(base_path, filename)
        if os.path.exists(filepath):
            print(f"\n📖 {filename}")
            try:
                with open(filepath, 'r', encoding='utf-8-sig') as f:
                    data = json.load(f)
                
                if isinstance(data, dict):
                    print(f"  📊 Clés principales: {list(data.keys())}")
                    
                    # Compter les livres
                    if 'books' in data:
                        print(f"  📚 Nombre de livres: {len(data['books'])}")
                        
                        # Analyser le premier livre
                        if data['books']:
                            first_book = data['books'][0]
                            if isinstance(first_book, dict):
                                print(f"  📝 Structure du premier livre: {list(first_book.keys())}")
                                
                                # Compter les chapitres
                                if 'chapters' in first_book:
                                    print(f"  📖 Chapitres dans le premier livre: {len(first_book['chapters'])}")
                                    
                                    # Analyser le premier chapitre
                                    if first_book['chapters']:
                                        first_chapter = first_book['chapters'][0]
                                        if isinstance(first_chapter, dict) and 'verses' in first_chapter:
                                            print(f"  📄 Versets dans le premier chapitre: {len(first_chapter['verses'])}")
                                            
                                            # Afficher un exemple de verset
                                            if first_chapter['verses']:
                                                first_verse = first_chapter['verses'][0]
                                                if isinstance(first_verse, dict) and 'text' in first_verse:
                                                    print(f"  📝 Exemple de verset: {first_verse['text'][:100]}...")
                
                elif isinstance(data, list):
                    print(f"  📊 Type: Liste avec {len(data)} éléments")
                    if data:
                        print(f"  📝 Premier élément: {type(data[0])}")
                        if isinstance(data[0], dict):
                            print(f"  📝 Clés du premier élément: {list(data[0].keys())}")
                
            except Exception as e:
                print(f"  ❌ Erreur: {e}")
        else:
            print(f"❌ Fichier non trouvé: {filename}")

def main():
    analyze_bible_json_files()

if __name__ == "__main__":
    main()


