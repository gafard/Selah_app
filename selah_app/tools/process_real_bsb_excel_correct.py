#!/usr/bin/env python3
"""
Script pour traiter les vrais fichiers Excel BSB avec la structure correcte
"""

import pandas as pd
import json
import gzip
import os
import re
from pathlib import Path

def extract_word_from_entry(entry_text):
    """Extrait le mot principal d'une entrée comme '10 (2 Occurrences)'"""
    if not entry_text or pd.isna(entry_text):
        return ""
    
    # Extraire le mot avant la parenthèse
    match = re.match(r'^([^(]+)', str(entry_text))
    if match:
        return match.group(1).strip()
    return str(entry_text).strip()

def parse_reference(verse_text):
    """Parse une référence biblique comme 'Gen 32:15'"""
    if not verse_text or pd.isna(verse_text):
        return "", 0, 0
    
    # Pattern pour capturer livre, chapitre, verset
    match = re.match(r'^([A-Za-z0-9\s]+?)\s+(\d+):(\d+)', str(verse_text))
    if match:
        book = match.group(1).strip()
        chapter = int(match.group(2))
        verse = int(match.group(3))
        return book, chapter, verse
    
    return str(verse_text), 0, 0

def process_bsb_concordance_excel(excel_path, output_path):
    """Traite le fichier Excel de concordance BSB réel"""
    print(f"🚀 Traitement de la concordance BSB depuis {excel_path}")
    
    try:
        # Lire le fichier Excel en sautant les premières lignes d'en-tête
        df = pd.read_excel(excel_path, skiprows=1)  # Skip la première ligne d'en-tête
        
        print(f"✅ {len(df)} entrées de concordance chargées")
        
        # Renommer les colonnes pour plus de clarté
        df.columns = ['Sort', 'Book', 'Chap', 'Word', 'Occ', 'Total', 'Entry', 'Verse', 'Context']
        
        print(f"📊 Colonnes: {list(df.columns)}")
        
        # Afficher un échantillon
        print("\n🔍 Échantillon des données:")
        print(df.head(3).to_string())
        
        # Convertir en format JSONL.gz pour le streaming
        concordance_entries = []
        
        for index, row in df.iterrows():
            # Ignorer les lignes d'en-tête ou de résumé
            if pd.isna(row['Book']) or pd.isna(row['Verse']) or row['Occ'] == 0:
                continue
            
            # Extraire le mot de l'entrée
            word = extract_word_from_entry(row['Entry'])
            if not word:
                continue
            
            # Parser la référence biblique
            book, chapter, verse = parse_reference(row['Verse'])
            if not book or chapter == 0 or verse == 0:
                continue
            
            # Créer l'entrée de concordance
            entry = [
                word,  # lemma
                word,  # surface (même chose pour simplifier)
                book,  # book
                chapter,  # chapter
                verse,  # verse
                "n"  # pos (part of speech) - par défaut nom
            ]
            
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
        import traceback
        traceback.print_exc()
        return 0

def process_bsb_topical_excel(excel_path, output_path):
    """Traite le fichier Excel d'index thématique BSB réel"""
    print(f"🚀 Traitement de l'index thématique BSB depuis {excel_path}")
    
    try:
        # Lire le fichier Excel en sautant les premières lignes d'en-tête
        df = pd.read_excel(excel_path, skiprows=2)  # Skip les 2 premières lignes d'en-tête
        
        print(f"✅ {len(df)} entrées d'index thématique chargées")
        
        # Renommer les colonnes pour plus de clarté
        df.columns = ['Sort', 'Source', 'Topic', 'Num', 'Verse', 'Context']
        
        print(f"📊 Colonnes: {list(df.columns)}")
        
        # Afficher un échantillon
        print("\n🔍 Échantillon des données:")
        print(df.head(3).to_string())
        
        # Convertir en format JSONL.gz pour le streaming
        topical_entries = []
        topic_counter = 1
        
        for index, row in df.iterrows():
            # Ignorer les lignes sans données valides
            if pd.isna(row['Verse']) or pd.isna(row['Num']):
                continue
            
            # Parser la référence biblique
            book, chapter, verse = parse_reference(row['Verse'])
            if not book or chapter == 0 or verse == 0:
                continue
            
            # Utiliser le numéro comme ID de thème, ou créer un compteur
            topic_id = int(row['Num']) if not pd.isna(row['Num']) else topic_counter
            topic_counter += 1
            
            # Créer l'entrée de thème
            entry = [
                topic_id,  # topic_id
                book,  # book
                chapter,  # chapter
                verse,  # verse
                1.0  # weight (par défaut)
            ]
            
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
        import traceback
        traceback.print_exc()
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
        return
    
    if not os.path.exists(topical_excel):
        print(f"❌ Fichier Excel d'index thématique non trouvé: {topical_excel}")
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



