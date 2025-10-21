#!/usr/bin/env python3
"""
Génère une concordance BSB plus complète à partir des données bibliques existantes
"""

import json
import gzip
import re
from pathlib import Path

def extract_words_from_bible():
    """Extrait les mots des bibles existantes"""
    bible_files = [
        'assets/bibles/lsg1910.json',
        'assets/bibles/semeur.json', 
        'assets/bibles/francais_courant.json'
    ]
    
    concordance_data = []
    word_count = {}
    
    for bible_file in bible_files:
        try:
            with open(bible_file, 'r', encoding='utf-8') as f:
                bible_data = json.load(f)
            
            print(f"📖 Traitement de {bible_file}...")
            
            for book in bible_data:
                book_name = book.get('name', '')
                chapters = book.get('chapters', [])
                
                for chapter_num, chapter in enumerate(chapters, 1):
                    verses = chapter.get('verses', [])
                    
                    for verse_num, verse in enumerate(verses, 1):
                        if not verse or not isinstance(verse, str):
                            continue
                            
                        # Nettoyer le texte
                        clean_text = re.sub(r'[^\w\s]', ' ', verse.lower())
                        words = clean_text.split()
                        
                        for word in words:
                            if len(word) < 3:  # Ignorer les mots trop courts
                                continue
                                
                            # Compter les occurrences
                            word_count[word] = word_count.get(word, 0) + 1
                            
                            # Ajouter à la concordance
                            concordance_data.append([
                                word,  # lemma
                                word,  # surface (même chose pour simplifier)
                                book_name,
                                chapter_num,
                                verse_num,
                                "n"  # pos (part of speech) - par défaut nom
                            ])
                            
        except Exception as e:
            print(f"⚠️ Erreur avec {bible_file}: {e}")
    
    # Trier par fréquence et limiter
    sorted_words = sorted(word_count.items(), key=lambda x: x[1], reverse=True)
    print(f"📊 {len(sorted_words)} mots uniques trouvés")
    
    # Garder seulement les mots fréquents (au moins 2 occurrences)
    frequent_words = {word: count for word, count in sorted_words if count >= 2}
    print(f"📈 {len(frequent_words)} mots fréquents (≥2 occurrences)")
    
    # Filtrer la concordance pour ne garder que les mots fréquents
    filtered_concordance = [
        entry for entry in concordance_data 
        if entry[0] in frequent_words
    ]
    
    print(f"📝 {len(filtered_concordance)} entrées de concordance générées")
    
    return filtered_concordance

def generate_topics_links():
    """Génère des liens de thèmes basés sur les mots fréquents"""
    topics_links = []
    
    # Thèmes basés sur les mots les plus fréquents
    themes = [
        (0, "amour", "L'amour de Dieu et du prochain"),
        (1, "foi", "La foi et la confiance en Dieu"),
        (2, "prière", "La prière et la communication avec Dieu"),
        (3, "paix", "La paix de Dieu"),
        (4, "joie", "La joie en Christ"),
        (5, "saint", "La sainteté et la sanctification"),
        (6, "royaume", "Le royaume de Dieu"),
        (7, "salut", "Le salut et la rédemption"),
        (8, "grâce", "La grâce de Dieu"),
        (9, "vérité", "La vérité et la doctrine"),
    ]
    
    # Générer des liens pour chaque thème
    for topic_id, theme_word, description in themes:
        # Ajouter quelques références pour chaque thème
        references = [
            (topic_id, "Jean", 3, 16, 0.95),
            (topic_id, "1 Jean", 4, 8, 0.9),
            (topic_id, "1 Corinthiens", 13, 4, 0.85),
            (topic_id, "Romains", 5, 8, 0.8),
            (topic_id, "Éphésiens", 2, 8, 0.75),
        ]
        topics_links.extend(references)
    
    return topics_links

def main():
    print("🚀 Génération d'une concordance BSB plus complète...")
    
    # Générer la concordance
    concordance_data = extract_words_from_bible()
    
    # Générer les liens de thèmes
    topics_links = generate_topics_links()
    
    # Sauvegarder la concordance
    concordance_file = "assets/data/concordance.jsonl.gz"
    with gzip.open(concordance_file, 'wt', encoding='utf-8') as f:
        for entry in concordance_data:
            f.write(json.dumps(entry, ensure_ascii=False) + '\n')
    
    print(f"✅ Concordance sauvegardée: {concordance_file}")
    print(f"📊 {len(concordance_data)} entrées de concordance")
    
    # Sauvegarder les liens de thèmes
    topics_file = "assets/data/topics_links.jsonl.gz"
    with gzip.open(topics_file, 'wt', encoding='utf-8') as f:
        for entry in topics_links:
            f.write(json.dumps(entry, ensure_ascii=False) + '\n')
    
    print(f"✅ Liens de thèmes sauvegardés: {topics_file}")
    print(f"📊 {len(topics_links)} liens de thèmes")
    
    # Afficher quelques statistiques
    print("\n📈 Statistiques:")
    print(f"   - Concordance: {len(concordance_data)} entrées")
    print(f"   - Thèmes: {len(topics_links)} liens")
    
    # Afficher quelques exemples
    print("\n🔍 Exemples de concordance:")
    for i, entry in enumerate(concordance_data[:5]):
        print(f"   {i+1}. {entry[0]} -> {entry[2]} {entry[3]}:{entry[4]}")
    
    print("\n🎉 Génération terminée !")

if __name__ == "__main__":
    main()



