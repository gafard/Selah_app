#!/usr/bin/env python3
"""
Script de conversion BSB Excel vers JSON optimisé pour Flutter
Transforme les fichiers Excel en format JSONL compressé pour un chargement léger
"""

import pandas as pd
import json
import gzip
import argparse
import os
from pathlib import Path
import re

def normalize_reference(ref_str):
    """Normalise une référence biblique vers le format canonique français"""
    if not ref_str or pd.isna(ref_str):
        return None
    
    # Nettoyer la référence
    ref = str(ref_str).strip()
    
    # Mapping des livres vers le canon français
    book_mapping = {
        'Gen': 'Genèse', 'Ex': 'Exode', 'Lév': 'Lévitique', 'Nomb': 'Nombres', 'Deut': 'Deutéronome',
        'Jos': 'Josué', 'Jug': 'Juges', 'Ruth': 'Ruth', '1 Sam': '1 Samuel', '2 Sam': '2 Samuel',
        '1 Rois': '1 Rois', '2 Rois': '2 Rois', '1 Chron': '1 Chroniques', '2 Chron': '2 Chroniques',
        'Esd': 'Esdras', 'Néh': 'Néhémie', 'Est': 'Esther', 'Job': 'Job', 'Ps': 'Psaumes',
        'Prov': 'Proverbes', 'Eccl': 'Ecclésiaste', 'Cant': 'Cantique des Cantiques',
        'És': 'Ésaïe', 'Jér': 'Jérémie', 'Lam': 'Lamentations', 'Éz': 'Ézéchiel', 'Dan': 'Daniel',
        'Os': 'Osée', 'Joël': 'Joël', 'Am': 'Amos', 'Abd': 'Abdias', 'Jon': 'Jonas',
        'Mich': 'Michée', 'Nah': 'Nahum', 'Hab': 'Habacuc', 'Soph': 'Sophonie',
        'Agg': 'Aggée', 'Zac': 'Zacharie', 'Mal': 'Malachie',
        'Mat': 'Matthieu', 'Marc': 'Marc', 'Luc': 'Luc', 'Jean': 'Jean',
        'Act': 'Actes', 'Rom': 'Romains', '1 Cor': '1 Corinthiens', '2 Cor': '2 Corinthiens',
        'Gal': 'Galates', 'Éph': 'Éphésiens', 'Phil': 'Philippiens', 'Col': 'Colossiens',
        '1 Thess': '1 Thessaloniciens', '2 Thess': '2 Thessaloniciens',
        '1 Tim': '1 Timothée', '2 Tim': '2 Timothée', 'Tite': 'Tite', 'Philém': 'Philémon',
        'Héb': 'Hébreux', 'Jac': 'Jacques', '1 Pi': '1 Pierre', '2 Pi': '2 Pierre',
        '1 Jean': '1 Jean', '2 Jean': '2 Jean', '3 Jean': '3 Jean', 'Jude': 'Jude', 'Apoc': 'Apocalypse'
    }
    
    # Extraire livre, chapitre et verset
    # Format attendu : "Jean 3:16" ou "Jean 3:16-18"
    match = re.match(r'([A-Za-z\s]+)\s+(\d+):(\d+(?:-\d+)?)', ref)
    if not match:
        return None
    
    book_part = match.group(1).strip()
    chapter = int(match.group(2))
    verse_part = match.group(3)
    
    # Normaliser le livre
    book = book_mapping.get(book_part, book_part)
    
    # Extraire le verset de début
    verse_start = int(verse_part.split('-')[0])
    
    return {
        'book': book,
        'chapter': chapter,
        'verse': verse_start
    }

def process_topical_index(excel_path, output_dir):
    """Traite l'index thématique BSB"""
    print(f"📚 Traitement de l'index thématique: {excel_path}")
    
    # Lire le fichier Excel
    df = pd.read_excel(excel_path)
    print(f"   Colonnes détectées: {list(df.columns)}")
    
    # Détecter automatiquement les colonnes
    topic_col = None
    ref_col = None
    weight_col = None
    
    for col in df.columns:
        col_lower = col.lower()
        if 'topic' in col_lower or 'thème' in col_lower or 'sujet' in col_lower:
            topic_col = col
        elif 'ref' in col_lower or 'référence' in col_lower or 'verse' in col_lower:
            ref_col = col
        elif 'weight' in col_lower or 'poids' in col_lower or 'score' in col_lower:
            weight_col = col
    
    if not topic_col or not ref_col:
        print(f"   ❌ Colonnes requises non trouvées. Colonnes disponibles: {list(df.columns)}")
        return
    
    print(f"   📋 Colonnes utilisées: topic={topic_col}, ref={ref_col}, weight={weight_col}")
    
    # Créer l'index des sujets (léger)
    topics = {}
    topic_links = []
    
    for _, row in df.iterrows():
        topic = str(row[topic_col]).strip()
        ref = str(row[ref_col]).strip()
        weight = float(row[weight_col]) if weight_col and not pd.isna(row[weight_col]) else 1.0
        
        if not topic or not ref or topic == 'nan' or ref == 'nan':
            continue
        
        # Normaliser la référence
        norm_ref = normalize_reference(ref)
        if not norm_ref:
            continue
        
        # Créer un ID unique pour le sujet
        topic_id = len(topics)
        if topic not in topics:
            topics[topic] = {
                'id': topic_id,
                'slug': topic.lower().replace(' ', '-'),
                't': topic
            }
        
        # Ajouter le lien sujet-référence
        topic_links.append([
            topic_id,
            norm_ref['book'],
            norm_ref['chapter'],
            norm_ref['verse'],
            weight
        ])
    
    # Sauvegarder l'index des sujets (léger)
    topics_min = {
        'v': 1,
        'topics': list(topics.values())
    }
    
    topics_min_path = os.path.join(output_dir, 'topics_min.json')
    with open(topics_min_path, 'w', encoding='utf-8') as f:
        json.dump(topics_min, f, ensure_ascii=False, separators=(',', ':'))
    
    print(f"   ✅ Index des sujets sauvegardé: {topics_min_path} ({os.path.getsize(topics_min_path)} bytes)")
    
    # Sauvegarder les liens sujet-référence (compressé)
    topics_links_path = os.path.join(output_dir, 'topics_links.jsonl.gz')
    with gzip.open(topics_links_path, 'wt', encoding='utf-8') as f:
        for link in topic_links:
            f.write(json.dumps(link, ensure_ascii=False) + '\n')
    
    print(f"   ✅ Liens sujet-référence sauvegardés: {topics_links_path} ({os.path.getsize(topics_links_path)} bytes)")
    print(f"   📊 Total: {len(topics)} sujets, {len(topic_links)} liens")

def process_concordance(excel_path, output_dir):
    """Traite la concordance BSB"""
    print(f"📖 Traitement de la concordance: {excel_path}")
    
    # Lire le fichier Excel
    df = pd.read_excel(excel_path)
    print(f"   Colonnes détectées: {list(df.columns)}")
    
    # Détecter automatiquement les colonnes
    lemma_col = None
    surface_col = None
    ref_col = None
    pos_col = None
    
    for col in df.columns:
        col_lower = col.lower()
        if 'lemma' in col_lower or 'racine' in col_lower:
            lemma_col = col
        elif 'surface' in col_lower or 'forme' in col_lower or 'mot' in col_lower:
            surface_col = col
        elif 'ref' in col_lower or 'référence' in col_lower or 'verse' in col_lower:
            ref_col = col
        elif 'pos' in col_lower or 'part' in col_lower or 'grammaire' in col_lower:
            pos_col = col
    
    if not lemma_col or not ref_col:
        print(f"   ❌ Colonnes requises non trouvées. Colonnes disponibles: {list(df.columns)}")
        return
    
    print(f"   📋 Colonnes utilisées: lemma={lemma_col}, surface={surface_col}, ref={ref_col}, pos={pos_col}")
    
    # Traiter la concordance
    concordance_data = []
    
    for _, row in df.iterrows():
        lemma = str(row[lemma_col]).strip()
        surface = str(row[surface_col]).strip() if surface_col and not pd.isna(row[surface_col]) else lemma
        ref = str(row[ref_col]).strip()
        pos = str(row[pos_col]).strip() if pos_col and not pd.isna(row[pos_col]) else ''
        
        if not lemma or not ref or lemma == 'nan' or ref == 'nan':
            continue
        
        # Normaliser la référence
        norm_ref = normalize_reference(ref)
        if not norm_ref:
            continue
        
        # Ajouter l'entrée de concordance
        concordance_data.append([
            lemma,
            surface,
            norm_ref['book'],
            norm_ref['chapter'],
            norm_ref['verse'],
            pos
        ])
    
    # Sauvegarder la concordance (compressée)
    concordance_path = os.path.join(output_dir, 'concordance.jsonl.gz')
    with gzip.open(concordance_path, 'wt', encoding='utf-8') as f:
        for entry in concordance_data:
            f.write(json.dumps(entry, ensure_ascii=False) + '\n')
    
    print(f"   ✅ Concordance sauvegardée: {concordance_path} ({os.path.getsize(concordance_path)} bytes)")
    print(f"   📊 Total: {len(concordance_data)} entrées")

def main():
    parser = argparse.ArgumentParser(description='Convertir les fichiers Excel BSB en JSON optimisé pour Flutter')
    parser.add_argument('--topical', help='Chemin vers bsb_topical_index.xlsx')
    parser.add_argument('--concordance', help='Chemin vers bsb_concordance.xlsx')
    parser.add_argument('--out', required=True, help='Répertoire de sortie')
    
    args = parser.parse_args()
    
    # Créer le répertoire de sortie
    output_dir = Path(args.out)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    print("🚀 Conversion BSB Excel vers JSON optimisé")
    print(f"📁 Répertoire de sortie: {output_dir}")
    
    # Traiter l'index thématique
    if args.topical:
        if os.path.exists(args.topical):
            process_topical_index(args.topical, str(output_dir))
        else:
            print(f"❌ Fichier non trouvé: {args.topical}")
    
    # Traiter la concordance
    if args.concordance:
        if os.path.exists(args.concordance):
            process_concordance(args.concordance, str(output_dir))
        else:
            print(f"❌ Fichier non trouvé: {args.concordance}")
    
    print("✅ Conversion terminée !")
    print("\n📋 Fichiers générés:")
    for file in output_dir.glob('*'):
        size = file.stat().st_size
        size_str = f"{size:,} bytes"
        if size > 1024:
            size_str = f"{size/1024:.1f} KB"
        if size > 1024*1024:
            size_str = f"{size/(1024*1024):.1f} MB"
        print(f"   {file.name}: {size_str}")

if __name__ == '__main__':
    main()

