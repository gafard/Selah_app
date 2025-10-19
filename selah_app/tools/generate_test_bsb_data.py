#!/usr/bin/env python3
"""
Script pour générer des données de test BSB
Crée des fichiers JSONL.gz de test pour le développement
"""

import json
import gzip
import os
from pathlib import Path

def generate_test_topics_links():
    """Génère des données de test pour topics_links.jsonl.gz"""
    print("📚 Génération des données de test topics_links...")
    
    # Données de test
    test_data = [
        [0, "Jean", 3, 16, 0.95],  # Amour
        [0, "1 Jean", 4, 8, 0.90],
        [0, "1 Corinthiens", 13, 4, 0.85],
        [1, "Hébreux", 11, 1, 0.95],  # Foi
        [1, "Romains", 10, 17, 0.90],
        [1, "Éphésiens", 2, 8, 0.85],
        [2, "Romains", 15, 13, 0.95],  # Espérance
        [2, "1 Pierre", 1, 3, 0.90],
        [2, "Tite", 2, 13, 0.85],
        [3, "Éphésiens", 2, 8, 0.95],  # Grâce
        [3, "Tite", 2, 11, 0.90],
        [3, "Romains", 3, 24, 0.85],
        [4, "Actes", 4, 12, 0.95],  # Salut
        [4, "Romains", 10, 9, 0.90],
        [4, "Jean", 3, 16, 0.85],
        [5, "Matthieu", 6, 9, 0.95],  # Prière
        [5, "1 Thessaloniciens", 5, 17, 0.90],
        [5, "Philippiens", 4, 6, 0.85],
        [6, "Proverbes", 9, 10, 0.95],  # Sagesse
        [6, "Jacques", 1, 5, 0.90],
        [6, "1 Corinthiens", 1, 30, 0.85],
        [7, "Amos", 5, 24, 0.95],  # Justice
        [7, "Michée", 6, 8, 0.90],
        [7, "Romains", 3, 26, 0.85],
        [8, "Jean", 14, 27, 0.95],  # Paix
        [8, "Philippiens", 4, 7, 0.90],
        [8, "Romains", 5, 1, 0.85],
        [9, "Galates", 5, 22, 0.95],  # Joie
        [9, "Philippiens", 4, 4, 0.90],
        [9, "Néhémie", 8, 10, 0.85],
    ]
    
    # Créer le répertoire de sortie
    output_dir = Path("export_bsb")
    output_dir.mkdir(exist_ok=True)
    
    # Sauvegarder en JSONL.gz
    output_path = output_dir / "topics_links.jsonl.gz"
    with gzip.open(output_path, 'wt', encoding='utf-8') as f:
        for row in test_data:
            f.write(json.dumps(row, ensure_ascii=False) + '\n')
    
    print(f"✅ topics_links.jsonl.gz généré: {output_path} ({output_path.stat().st_size} bytes)")

def generate_test_concordance():
    """Génère des données de test pour concordance.jsonl.gz"""
    print("📖 Génération des données de test concordance...")
    
    # Données de test
    test_data = [
        ["aimer", "aime", "Jean", 3, 16, "v"],
        ["aimer", "aimé", "1 Jean", 4, 8, "v"],
        ["aimer", "amour", "1 Corinthiens", 13, 4, "n"],
        ["croire", "crois", "Hébreux", 11, 1, "v"],
        ["croire", "croyance", "Romains", 10, 17, "n"],
        ["croire", "foi", "Éphésiens", 2, 8, "n"],
        ["espérer", "espère", "Romains", 15, 13, "v"],
        ["espérer", "espérance", "1 Pierre", 1, 3, "n"],
        ["espérer", "espérance", "Tite", 2, 13, "n"],
        ["grâce", "grâce", "Éphésiens", 2, 8, "n"],
        ["grâce", "gracieux", "Tite", 2, 11, "adj"],
        ["grâce", "gracieux", "Romains", 3, 24, "adj"],
        ["sauver", "sauve", "Actes", 4, 12, "v"],
        ["sauver", "salut", "Romains", 10, 9, "n"],
        ["sauver", "sauveur", "Jean", 3, 16, "n"],
        ["prier", "prie", "Matthieu", 6, 9, "v"],
        ["prier", "prière", "1 Thessaloniciens", 5, 17, "n"],
        ["prier", "prière", "Philippiens", 4, 6, "n"],
        ["sagesse", "sagesse", "Proverbes", 9, 10, "n"],
        ["sagesse", "sage", "Jacques", 1, 5, "adj"],
        ["sagesse", "sage", "1 Corinthiens", 1, 30, "adj"],
        ["justice", "justice", "Amos", 5, 24, "n"],
        ["justice", "juste", "Michée", 6, 8, "adj"],
        ["justice", "juste", "Romains", 3, 26, "adj"],
        ["paix", "paix", "Jean", 14, 27, "n"],
        ["paix", "paix", "Philippiens", 4, 7, "n"],
        ["paix", "paix", "Romains", 5, 1, "n"],
        ["joie", "joie", "Galates", 5, 22, "n"],
        ["joie", "joyeux", "Philippiens", 4, 4, "adj"],
        ["joie", "joyeux", "Néhémie", 8, 10, "adj"],
    ]
    
    # Créer le répertoire de sortie
    output_dir = Path("export_bsb")
    output_dir.mkdir(exist_ok=True)
    
    # Sauvegarder en JSONL.gz
    output_path = output_dir / "concordance.jsonl.gz"
    with gzip.open(output_path, 'wt', encoding='utf-8') as f:
        for row in test_data:
            f.write(json.dumps(row, ensure_ascii=False) + '\n')
    
    print(f"✅ concordance.jsonl.gz généré: {output_path} ({output_path.stat().st_size} bytes)")

def main():
    print("🚀 Génération des données de test BSB")
    
    # Générer les fichiers de test
    generate_test_topics_links()
    generate_test_concordance()
    
    print("\n✅ Données de test générées avec succès !")
    print("\n📋 Fichiers générés:")
    
    output_dir = Path("export_bsb")
    for file in output_dir.glob("*"):
        size = file.stat().st_size
        size_str = f"{size:,} bytes"
        if size > 1024:
            size_str = f"{size/1024:.1f} KB"
        print(f"   {file.name}: {size_str}")

if __name__ == '__main__':
    main()
