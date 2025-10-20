#!/usr/bin/env python3
"""
Script pour analyser en détail le fichier bibles.xlsx
"""

import pandas as pd
import os

def analyze_bibles_excel_detailed():
    """Analyse détaillée du fichier bibles.xlsx"""
    print("🔍 Analyse détaillée de bibles.xlsx")
    print("=" * 60)
    
    try:
        excel_path = "/Users/gafardgnane/Downloads/Bibles versions/bibles.xlsx"
        df = pd.read_excel(excel_path)
        
        print(f"📊 Dimensions: {df.shape[0]} lignes x {df.shape[1]} colonnes")
        print(f"📝 Colonnes: {list(df.columns)}")
        
        # Analyser la colonne de références
        print(f"\n📖 Analyse de la colonne de références:")
        ref_col = df.iloc[:, 0]  # Première colonne
        print(f"  📊 Nombre de références: {ref_col.count()}")
        print(f"  📝 Exemples de références:")
        for i in range(min(10, len(ref_col))):
            if pd.notna(ref_col.iloc[i]):
                print(f"    {i+1}. {ref_col.iloc[i]}")
        
        # Analyser les versions disponibles
        print(f"\n📚 Versions bibliques disponibles:")
        version_columns = [col for col in df.columns if col != 'Unnamed: 0']
        for i, col in enumerate(version_columns, 1):
            non_null_count = df[col].count()
            print(f"  {i:2d}. {col}: {non_null_count:,} versets")
        
        # Analyser un verset spécifique
        print(f"\n📄 Analyse d'un verset spécifique (Genèse 1:1):")
        gen_1_1_row = df[df.iloc[:, 0] == 'Genesis 1:1']
        if not gen_1_1_row.empty:
            print(f"  📊 Trouvé: {len(gen_1_1_row)} occurrence(s)")
            for col in version_columns:
                if col in gen_1_1_row.columns:
                    text = gen_1_1_row[col].iloc[0]
                    if pd.notna(text):
                        print(f"  📖 {col}: {text}")
        
        # Compter les versets par livre
        print(f"\n📚 Analyse par livre:")
        ref_col_clean = ref_col.dropna()
        book_counts = {}
        for ref in ref_col_clean:
            if isinstance(ref, str) and ':' in ref:
                book = ref.split(':')[0].split()[0]  # Premier mot avant ':'
                book_counts[book] = book_counts.get(book, 0) + 1
        
        # Afficher les 10 premiers livres
        sorted_books = sorted(book_counts.items(), key=lambda x: x[1], reverse=True)
        for i, (book, count) in enumerate(sorted_books[:10], 1):
            print(f"  {i:2d}. {book}: {count:,} versets")
        
        return True
        
    except Exception as e:
        print(f"❌ Erreur: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    analyze_bibles_excel_detailed()

if __name__ == "__main__":
    main()

