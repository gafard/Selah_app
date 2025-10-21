#!/usr/bin/env python3
"""
Script pour traiter les vrais fichiers Excel BSB fournis par l'utilisateur
et générer une concordance complète et sérieuse.
"""

import pandas as pd
import json
import gzip
import os
from pathlib import Path

def process_bsb_concordance_excel(excel_path, output_path):
    """Traite le fichier Excel de concordance BSB réel"""
    print(f"🚀 Traitement de la concordance BSB depuis {excel_path}")
    
    try:
        # Lire le fichier Excel
        df = pd.read_excel(excel_path)
        print(f"✅ {len(df)} entrées de concordance chargées")
        
        # Analyser la structure
        print(f"📊 Colonnes disponibles: {list(df.columns)}")
        print(f"📏 Dimensions: {df.shape[0]} lignes x {df.shape[1]} colonnes")
        
        # Afficher un échantillon
        print("\n🔍 Échantillon des données:")
        print(df.head(3).to_string())
        
        # Convertir en format JSONL.gz pour le streaming
        concordance_entries = []
        
        for index, row in df.iterrows():
            # Adapter selon la structure réelle de votre Excel
            # Ces noms de colonnes sont des exemples - ajustez selon votre fichier
            lemma = str(row.get('lemma', row.get('mot', row.get('word', '')))).strip()
            surface = str(row.get('surface', row.get('forme', row.get('form', '')))).strip()
            book = str(row.get('book', row.get('livre', row.get('book_name', '')))).strip()
            chapter = int(row.get('chapter', row.get('chapitre', row.get('ch', 0))))
            verse = int(row.get('verse', row.get('verset', row.get('v', 0))))
            pos = str(row.get('pos', row.get('type', row.get('part_of_speech', 'n')))).strip()
            
            entry = [lemma, surface, book, chapter, verse, pos]
            
            # Vérifier que l'entrée est valide
            if entry[0] and entry[2] and entry[3] > 0 and entry[4] > 0:
                concordance_entries.append(entry)
        
        print(f"✅ {len(concordance_entries)} entrées valides générées")
        
        # Sauvegarder en JSONL.gz
        with gzip.open(output_path, 'wt', encoding='utf-8') as f:
            for entry in concordance_entries:
                f.write(json.dumps(entry, ensure_ascii=False) + '\n')
        
        print(f"💾 Concordance sauvegardée: {output_path}")
        print(f"📊 Taille du fichier: {os.path.getsize(output_path) / 1024:.1f} KB")
        
        return len(concordance_entries)
        
    except Exception as e:
        print(f"❌ Erreur lors du traitement: {e}")
        return 0

def process_bsb_topical_excel(excel_path, output_path):
    """Traite le fichier Excel d'index thématique BSB réel"""
    print(f"🚀 Traitement de l'index thématique BSB depuis {excel_path}")
    
    try:
        # Lire le fichier Excel
        df = pd.read_excel(excel_path)
        print(f"✅ {len(df)} entrées d'index thématique chargées")
        
        # Analyser la structure
        print(f"📊 Colonnes disponibles: {list(df.columns)}")
        print(f"📏 Dimensions: {df.shape[0]} lignes x {df.shape[1]} colonnes")
        
        # Afficher un échantillon
        print("\n🔍 Échantillon des données:")
        print(df.head(3).to_string())
        
        # Convertir en format JSONL.gz pour le streaming
        topical_entries = []
        
        for index, row in df.iterrows():
            # Adapter selon la structure réelle de votre Excel
            topic_id = int(row.get('topic_id', row.get('id', row.get('theme_id', 0))))
            book = str(row.get('book', row.get('livre', row.get('book_name', '')))).strip()
            chapter = int(row.get('chapter', row.get('chapitre', row.get('ch', 0))))
            verse = int(row.get('verse', row.get('verset', row.get('v', 0))))
            weight = float(row.get('weight', row.get('poids', row.get('score', 1.0))))
            
            entry = [topic_id, book, chapter, verse, weight]
            
            # Vérifier que l'entrée est valide
            if entry[1] and entry[2] > 0 and entry[3] > 0:
                topical_entries.append(entry)
        
        print(f"✅ {len(topical_entries)} entrées valides générées")
        
        # Sauvegarder en JSONL.gz
        with gzip.open(output_path, 'wt', encoding='utf-8') as f:
            for entry in topical_entries:
                f.write(json.dumps(entry, ensure_ascii=False) + '\n')
        
        print(f"💾 Index thématique sauvegardé: {output_path}")
        print(f"📊 Taille du fichier: {os.path.getsize(output_path) / 1024:.1f} KB")
        
        return len(topical_entries)
        
    except Exception as e:
        print(f"❌ Erreur lors du traitement: {e}")
        return 0

def generate_topics_min_json(topical_entries, output_path):
    """Génère le fichier topics_min.json avec les métadonnées des thèmes"""
    print(f"🚀 Génération du fichier topics_min.json...")
    
    try:
        # Extraire les thèmes uniques
        topics = {}
        for entry in topical_entries:
            topic_id = entry[0]
            if topic_id not in topics:
                topics[topic_id] = {
                    'id': topic_id,
                    't': f'Thème {topic_id}',  # Titre par défaut
                    'slug': f'theme-{topic_id}'
                }
        
        # Créer la structure finale
        topics_data = {
            'v': 1,
            'topics': list(topics.values())
        }
        
        # Sauvegarder
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(topics_data, f, ensure_ascii=False, indent=2)
        
        print(f"✅ topics_min.json généré: {len(topics)} thèmes")
        print(f"💾 Fichier sauvegardé: {output_path}")
        
        return len(topics)
        
    except Exception as e:
        print(f"❌ Erreur lors de la génération: {e}")
        return 0

def main():
    print("🎯 Traitement des vrais fichiers Excel BSB")
    print("=" * 50)
    
    # Chemins des fichiers Excel BSB réels
    concordance_excel = "/Users/gafardgnane/Downloads/Bibles versions/bsb_concordance.xlsx"
    topical_excel = "/Users/gafardgnane/Downloads/Bibles versions/bsb_topical_index.xlsx"
    
    # Chemins de sortie
    concordance_output = "assets/data/concordance.jsonl.gz"
    topical_output = "assets/data/topics_links.jsonl.gz"
    topics_min_output = "assets/data/topics_min.json"
    
    # Vérifier que les fichiers Excel existent
    if not os.path.exists(concordance_excel):
        print(f"❌ Fichier Excel de concordance non trouvé: {concordance_excel}")
        print("📁 Veuillez placer le fichier bsb_concordance.xlsx dans le répertoire tools/")
        return
    
    if not os.path.exists(topical_excel):
        print(f"❌ Fichier Excel d'index thématique non trouvé: {topical_excel}")
        print("📁 Veuillez placer le fichier bsb_topical_index.xlsx dans le répertoire tools/")
        return
    
    # Créer le dossier de sortie
    os.makedirs(os.path.dirname(concordance_output), exist_ok=True)
    
    # Traiter la concordance
    concordance_count = process_bsb_concordance_excel(concordance_excel, concordance_output)
    
    # Traiter l'index thématique
    topical_count = process_bsb_topical_excel(topical_excel, topical_output)
    
    # Générer topics_min.json
    if topical_count > 0:
        # Lire les entrées pour générer topics_min.json
        topical_entries = []
        with gzip.open(topical_output, 'rt', encoding='utf-8') as f:
            for line in f:
                entry = json.loads(line.strip())
                topical_entries.append(entry)
        
        topics_count = generate_topics_min_json(topical_entries, topics_min_output)
    else:
        topics_count = 0
    
    # Résumé final
    print("\n" + "=" * 50)
    print("📊 RÉSUMÉ FINAL")
    print("=" * 50)
    print(f"✅ Concordance: {concordance_count:,} entrées")
    print(f"✅ Index thématique: {topical_count:,} entrées")
    print(f"✅ Thèmes: {topics_count:,} thèmes")
    print(f"📁 Fichiers générés:")
    print(f"   - {concordance_output}")
    print(f"   - {topical_output}")
    print(f"   - {topics_min_output}")
    print("\n🎉 Traitement terminé avec succès !")

if __name__ == "__main__":
    main()


