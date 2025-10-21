#!/usr/bin/env python3
"""
Script pour traiter le fichier bibles.xlsx et créer un système de comparaison de versions
"""

import pandas as pd
import json
import gzip
import os
import re
from pathlib import Path

def process_bible_comparison_excel(excel_path, output_path):
    """Traite le fichier bibles.xlsx pour créer un système de comparaison"""
    print(f"🚀 Traitement du système de comparaison de versions bibliques")
    print("=" * 60)
    
    try:
        # Lire le fichier Excel
        df = pd.read_excel(excel_path)
        print(f"✅ {len(df)} versets chargés avec {len(df.columns)-1} versions")
        
        # Renommer les colonnes
        df.columns = ['Reference'] + [col for col in df.columns[1:]]
        
        # Nettoyer les données
        df = df.dropna(subset=['Reference'])
        
        print(f"📊 Versions disponibles:")
        version_columns = [col for col in df.columns if col != 'Reference']
        for i, col in enumerate(version_columns, 1):
            non_null_count = df[col].count()
            print(f"  {i:2d}. {col}: {non_null_count:,} versets")
        
        # Créer le système de comparaison
        comparison_data = []
        
        for index, row in df.iterrows():
            reference = str(row['Reference']).strip()
            if not reference or reference == 'nan':
                continue
            
            # Parser la référence
            book, chapter, verse = parse_reference(reference)
            if not book:
                continue
            
            # Collecter toutes les versions pour ce verset
            versions = {}
            for col in version_columns:
                text = row[col]
                if pd.notna(text) and str(text).strip():
                    versions[col] = str(text).strip()
            
            if len(versions) > 1:  # Au moins 2 versions
                entry = {
                    'reference': reference,
                    'book': book,
                    'chapter': chapter,
                    'verse': verse,
                    'versions': versions
                }
                comparison_data.append(entry)
        
        print(f"✅ {len(comparison_data)} versets avec comparaison générés")
        
        # Sauvegarder en JSONL.gz
        with gzip.open(output_path, 'wt', encoding='utf-8') as f:
            for entry in comparison_data:
                f.write(json.dumps(entry, ensure_ascii=False) + '\n')
        
        print(f"💾 Données de comparaison sauvegardées: {output_path}")
        print(f"📊 Taille du fichier: {os.path.getsize(output_path) / 1024:.1f} KB")
        
        return len(comparison_data)
        
    except Exception as e:
        print(f"❌ Erreur lors du traitement: {e}")
        import traceback
        traceback.print_exc()
        return 0

def parse_reference(reference_text):
    """Parse une référence biblique comme 'Genesis 1:1'"""
    if not reference_text or pd.isna(reference_text):
        return "", 0, 0
    
    # Pattern pour capturer livre, chapitre, verset
    match = re.match(r'^([A-Za-z0-9\s]+?)\s+(\d+):(\d+)', str(reference_text))
    if match:
        book = match.group(1).strip()
        chapter = int(match.group(2))
        verse = int(match.group(3))
        return book, chapter, verse
    
    return str(reference_text), 0, 0

def create_version_metadata(output_path):
    """Crée les métadonnées des versions disponibles"""
    print(f"🚀 Création des métadonnées des versions")
    
    versions_info = {
        'BSB': {
            'name': 'Berean Standard Bible',
            'language': 'en',
            'description': 'Modern English translation with study notes',
            'year': '2016'
        },
        'KJV': {
            'name': 'King James Version',
            'language': 'en',
            'description': 'Classic English translation (1611)',
            'year': '1611'
        },
        'ASV': {
            'name': 'American Standard Version',
            'language': 'en',
            'description': 'Literal English translation (1901)',
            'year': '1901'
        },
        'AKJV': {
            'name': 'American King James Version',
            'language': 'en',
            'description': 'Modernized KJV with American spelling',
            'year': '1999'
        },
        'CPDV': {
            'name': 'Catholic Public Domain Version',
            'language': 'en',
            'description': 'Catholic translation in public domain',
            'year': '2009'
        },
        'DBT': {
            'name': 'Darby Bible Translation',
            'language': 'en',
            'description': 'Literal translation by John Darby',
            'year': '1890'
        },
        'DRB': {
            'name': 'Douay-Rheims Bible',
            'language': 'en',
            'description': 'Catholic English translation',
            'year': '1582-1610'
        },
        'ERV': {
            'name': 'English Revised Version',
            'language': 'en',
            'description': 'British revision of KJV (1885)',
            'year': '1885'
        },
        'JPS / WEY': {
            'name': 'JPS Tanakh / Weymouth NT',
            'language': 'en',
            'description': 'Jewish Publication Society OT + Weymouth NT',
            'year': '1917/1903'
        },
        'NHEB': {
            'name': 'New Heart English Bible',
            'language': 'en',
            'description': 'Modern English translation',
            'year': '2010'
        },
        'SLT': {
            'name': 'Smith\'s Literal Translation',
            'language': 'en',
            'description': 'Literal word-for-word translation',
            'year': '1876'
        },
        'WBT': {
            'name': 'Webster Bible Translation',
            'language': 'en',
            'description': 'Noah Webster\'s revision of KJV',
            'year': '1833'
        },
        'WEB': {
            'name': 'World English Bible',
            'language': 'en',
            'description': 'Public domain modern English translation',
            'year': '2000'
        },
        'YLT': {
            'name': 'Young\'s Literal Translation',
            'language': 'en',
            'description': 'Very literal English translation',
            'year': '1862'
        }
    }
    
    # Sauvegarder les métadonnées
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(versions_info, f, ensure_ascii=False, indent=2)
    
    print(f"✅ Métadonnées des versions sauvegardées: {output_path}")
    return len(versions_info)

def main():
    print("🎯 CRÉATION DU SYSTÈME DE COMPARAISON DE VERSIONS BIBLIQUES")
    print("=" * 70)
    
    # Chemins
    excel_path = "/Users/gafardgnane/Downloads/Bibles versions/bibles.xlsx"
    comparison_output = "assets/data/bible_comparison.jsonl.gz"
    metadata_output = "assets/data/bible_versions_metadata.json"
    
    # Vérifier que le fichier Excel existe
    if not os.path.exists(excel_path):
        print(f"❌ Fichier Excel non trouvé: {excel_path}")
        return
    
    # Créer le dossier de sortie
    os.makedirs(os.path.dirname(comparison_output), exist_ok=True)
    
    # Traiter le fichier Excel
    comparison_count = process_bible_comparison_excel(excel_path, comparison_output)
    
    # Créer les métadonnées
    metadata_count = create_version_metadata(metadata_output)
    
    # Résumé final
    print("\n" + "=" * 70)
    print("📊 RÉSUMÉ FINAL - SYSTÈME DE COMPARAISON DE VERSIONS")
    print("=" * 70)
    print(f"✅ Versets avec comparaison: {comparison_count:,}")
    print(f"✅ Versions disponibles: {metadata_count}")
    print(f"📁 Fichiers générés:")
    print(f"   - {comparison_output}")
    print(f"   - {metadata_output}")
    print("\n🎉 SYSTÈME DE COMPARAISON DE VERSIONS CRÉÉ !")

if __name__ == "__main__":
    main()



