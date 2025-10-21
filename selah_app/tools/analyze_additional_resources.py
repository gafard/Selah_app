#!/usr/bin/env python3
"""
Script pour analyser les ressources supplémentaires disponibles
"""

import pandas as pd
import json
import os
from pathlib import Path

def analyze_bibles_excel():
    """Analyse le fichier bibles.xlsx"""
    print("🔍 Analyse de bibles.xlsx")
    print("=" * 50)
    
    try:
        excel_path = "/Users/gafardgnane/Downloads/Bibles versions/bibles.xlsx"
        df = pd.read_excel(excel_path)
        
        print(f"📊 Dimensions: {df.shape[0]} lignes x {df.shape[1]} colonnes")
        print(f"📝 Colonnes: {list(df.columns)}")
        
        # Afficher les premières lignes
        print("\n📋 Premières 5 lignes:")
        print(df.head().to_string())
        
        # Analyser les types de données
        print(f"\n🏷️ Types de données:")
        for col in df.columns:
            non_null_count = df[col].count()
            print(f"  {col}: {df[col].dtype} ({non_null_count} valeurs non-null)")
        
        return True
        
    except Exception as e:
        print(f"❌ Erreur: {e}")
        return False

def analyze_bible_json_files():
    """Analyse les fichiers JSON de bibles"""
    print("\n🔍 Analyse des fichiers JSON de bibles")
    print("=" * 50)
    
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
                with open(filepath, 'r', encoding='utf-8') as f:
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
                
                elif isinstance(data, list):
                    print(f"  📊 Type: Liste avec {len(data)} éléments")
                    if data:
                        print(f"  📝 Premier élément: {type(data[0])}")
                
            except Exception as e:
                print(f"  ❌ Erreur: {e}")
        else:
            print(f"❌ Fichier non trouvé: {filename}")

def check_pdf_outlines():
    """Vérifie le fichier PDF des plans de livres"""
    print("\n🔍 Analyse de bsb_book_outlines.pdf")
    print("=" * 50)
    
    pdf_path = "/Users/gafardgnane/Downloads/Bibles versions/bsb_book_outlines.pdf"
    
    if os.path.exists(pdf_path):
        file_size = os.path.getsize(pdf_path)
        print(f"📄 Taille du fichier: {file_size / 1024:.1f} KB")
        print("📋 Ce fichier contient probablement des plans de livres bibliques")
        print("💡 Peut être utilisé pour enrichir l'étude biblique avec des structures de livres")
        return True
    else:
        print("❌ Fichier PDF non trouvé")
        return False

def main():
    print("🎯 ANALYSE DES RESSOURCES SUPPLÉMENTAIRES")
    print("=" * 60)
    
    # Analyser bibles.xlsx
    analyze_bibles_excel()
    
    # Analyser les fichiers JSON
    analyze_bible_json_files()
    
    # Vérifier le PDF
    check_pdf_outlines()
    
    print("\n" + "=" * 60)
    print("📊 RÉSUMÉ DES RESSOURCES DISPONIBLES")
    print("=" * 60)
    print("✅ 8 versions bibliques JSON (Darby, Segond, Semeur, etc.)")
    print("✅ 1 fichier Excel bibles.xlsx (15.8 MB)")
    print("✅ 1 PDF bsb_book_outlines.pdf (981 KB)")
    print("✅ 2 fichiers BSB déjà utilisés (concordance + index thématique)")
    print("\n💡 POTENTIEL D'ENRICHISSEMENT:")
    print("  - Ajouter plus de versions bibliques à l'application")
    print("  - Utiliser bibles.xlsx pour des données supplémentaires")
    print("  - Intégrer les plans de livres du PDF")
    print("  - Créer un système de comparaison de versions")

if __name__ == "__main__":
    main()


