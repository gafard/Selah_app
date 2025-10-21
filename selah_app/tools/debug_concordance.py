#!/usr/bin/env python3
"""
Script pour déboguer la structure de la concordance BSB
"""

import pandas as pd
import re

def debug_concordance_structure():
    """Débogue la structure de la concordance"""
    excel_path = "/Users/gafardgnane/Downloads/Bibles versions/bsb_concordance.xlsx"
    
    print("🔍 Analyse détaillée de la concordance BSB")
    print("=" * 60)
    
    # Lire sans skiprows pour voir la vraie structure
    df = pd.read_excel(excel_path)
    print(f"📊 Dimensions originales: {df.shape[0]} lignes x {df.shape[1]} colonnes")
    
    # Afficher les 20 premières lignes
    print("\n📋 Premières 20 lignes:")
    for i in range(min(20, len(df))):
        print(f"\n--- Ligne {i} ---")
        row = df.iloc[i]
        for j, value in enumerate(row):
            if pd.notna(value) and str(value).strip():
                print(f"  Colonne {j}: {repr(value)}")
    
    # Chercher des patterns de données valides
    print("\n🔍 Recherche de patterns de données valides...")
    
    # Pattern 1: Lignes avec Book et Verse
    valid_rows = 0
    for i in range(min(1000, len(df))):
        row = df.iloc[i]
        
        # Vérifier si c'est une ligne de données valide
        has_book = pd.notna(row.iloc[1]) and str(row.iloc[1]).strip() and str(row.iloc[1]) != 'Book'
        has_verse = pd.notna(row.iloc[7]) and str(row.iloc[7]).strip() and str(row.iloc[7]) != 'Verse'
        has_entry = pd.notna(row.iloc[6]) and str(row.iloc[6]).strip() and str(row.iloc[6]) != 'Entry'
        
        if has_book and has_verse and has_entry:
            valid_rows += 1
            if valid_rows <= 10:  # Afficher les 10 premières lignes valides
                print(f"\n✅ Ligne valide {i}:")
                print(f"  Book: {repr(row.iloc[1])}")
                print(f"  Verse: {repr(row.iloc[7])}")
                print(f"  Entry: {repr(row.iloc[6])}")
                print(f"  Context: {repr(row.iloc[8])}")
    
    print(f"\n📈 Lignes valides trouvées: {valid_rows}")

if __name__ == "__main__":
    debug_concordance_structure()



