#!/usr/bin/env python3
"""
Script pour analyser la structure réelle des fichiers Excel BSB
"""

import pandas as pd
import os

def analyze_excel_structure(file_path, max_rows=10):
    """Analyse la structure d'un fichier Excel"""
    print(f"\n🔍 Analyse détaillée de {file_path}")
    print("=" * 60)
    
    try:
        # Lire le fichier Excel
        df = pd.read_excel(file_path)
        print(f"📊 Dimensions: {df.shape[0]} lignes x {df.shape[1]} colonnes")
        print(f"📝 Colonnes: {list(df.columns)}")
        
        # Afficher les premières lignes avec plus de détails
        print(f"\n📋 Premières {max_rows} lignes:")
        for i in range(min(max_rows, len(df))):
            print(f"\n--- Ligne {i} ---")
            for j, col in enumerate(df.columns):
                value = df.iloc[i, j]
                if pd.notna(value) and str(value).strip():
                    print(f"  Colonne {j} ({col}): {repr(value)}")
        
        # Chercher les lignes avec des données valides
        print(f"\n🔍 Recherche de lignes avec des données valides...")
        valid_rows = 0
        for i in range(min(100, len(df))):  # Vérifier les 100 premières lignes
            row = df.iloc[i]
            has_data = False
            for j, value in enumerate(row):
                if pd.notna(value) and str(value).strip() and str(value) != 'NaN':
                    has_data = True
                    break
            if has_data:
                valid_rows += 1
                if valid_rows <= 5:  # Afficher les 5 premières lignes valides
                    print(f"\n✅ Ligne valide {i}:")
                    for j, value in enumerate(row):
                        if pd.notna(value) and str(value).strip() and str(value) != 'NaN':
                            print(f"  Colonne {j}: {repr(value)}")
        
        print(f"\n📈 Lignes avec données valides trouvées: {valid_rows}")
        
    except Exception as e:
        print(f"❌ Erreur lors de l'analyse: {e}")

def main():
    print("🔍 Analyse des fichiers Excel BSB")
    print("=" * 50)
    
    # Analyser la concordance
    concordance_path = "/Users/gafardgnane/Downloads/Bibles versions/bsb_concordance.xlsx"
    if os.path.exists(concordance_path):
        analyze_excel_structure(concordance_path)
    else:
        print(f"❌ Fichier non trouvé: {concordance_path}")
    
    # Analyser l'index thématique
    topical_path = "/Users/gafardgnane/Downloads/Bibles versions/bsb_topical_index.xlsx"
    if os.path.exists(topical_path):
        analyze_excel_structure(topical_path)
    else:
        print(f"❌ Fichier non trouvé: {topical_path}")

if __name__ == "__main__":
    main()
