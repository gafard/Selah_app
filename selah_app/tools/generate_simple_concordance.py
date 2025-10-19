#!/usr/bin/env python3
"""
Génère une concordance BSB simple avec des mots bibliques courants
"""

import json
import gzip

def generate_concordance():
    """Génère une concordance avec des mots bibliques courants"""
    
    # Mots bibliques courants avec leurs références
    concordance_data = [
        # Amour
        ["aimer", "aime", "Jean", 3, 16, "v"],
        ["aimer", "aimé", "1 Jean", 4, 8, "v"],
        ["aimer", "amour", "1 Corinthiens", 13, 4, "n"],
        ["aimer", "aime", "Matthieu", 22, 37, "v"],
        ["aimer", "aimons", "1 Jean", 4, 19, "v"],
        
        # Foi
        ["croire", "crois", "Hébreux", 11, 1, "v"],
        ["croire", "croyance", "Romains", 10, 17, "n"],
        ["croire", "croit", "Jean", 3, 16, "v"],
        ["croire", "croyons", "2 Corinthiens", 4, 13, "v"],
        ["croire", "croyant", "Actes", 16, 31, "n"],
        
        # Dieu
        ["Dieu", "Dieu", "Genèse", 1, 1, "n"],
        ["Dieu", "Dieu", "Jean", 1, 1, "n"],
        ["Dieu", "Dieu", "Psaumes", 23, 1, "n"],
        ["Dieu", "Dieu", "Matthieu", 6, 9, "n"],
        ["Dieu", "Dieu", "Romains", 8, 28, "n"],
        
        # Jésus
        ["Jésus", "Jésus", "Matthieu", 1, 21, "n"],
        ["Jésus", "Jésus", "Jean", 14, 6, "n"],
        ["Jésus", "Jésus", "Actes", 4, 12, "n"],
        ["Jésus", "Jésus", "Philippiens", 2, 9, "n"],
        ["Jésus", "Jésus", "Apocalypse", 1, 8, "n"],
        
        # Christ
        ["Christ", "Christ", "Matthieu", 16, 16, "n"],
        ["Christ", "Christ", "Jean", 1, 41, "n"],
        ["Christ", "Christ", "Actes", 2, 36, "n"],
        ["Christ", "Christ", "1 Corinthiens", 15, 3, "n"],
        ["Christ", "Christ", "Éphésiens", 2, 8, "n"],
        
        # Esprit
        ["Esprit", "Esprit", "Genèse", 1, 2, "n"],
        ["Esprit", "Esprit", "Jean", 14, 26, "n"],
        ["Esprit", "Esprit", "Actes", 2, 4, "n"],
        ["Esprit", "Esprit", "Romains", 8, 9, "n"],
        ["Esprit", "Esprit", "Galates", 5, 22, "n"],
        
        # Prière
        ["prier", "prie", "Matthieu", 6, 9, "v"],
        ["prier", "prière", "1 Thessaloniciens", 5, 17, "n"],
        ["prier", "prient", "Actes", 1, 14, "v"],
        ["prier", "prier", "Philippiens", 4, 6, "v"],
        ["prier", "prière", "Jacques", 5, 16, "n"],
        
        # Paix
        ["paix", "paix", "Jean", 14, 27, "n"],
        ["paix", "paix", "Romains", 5, 1, "n"],
        ["paix", "paix", "Philippiens", 4, 7, "n"],
        ["paix", "paix", "Colossiens", 3, 15, "n"],
        ["paix", "paix", "Éphésiens", 2, 14, "n"],
        
        # Joie
        ["joie", "joie", "Galates", 5, 22, "n"],
        ["joie", "joyeux", "Philippiens", 4, 4, "adj"],
        ["joie", "joyeux", "Néhémie", 8, 10, "adj"],
        ["joie", "joie", "Psaumes", 16, 11, "n"],
        ["joie", "joie", "Luc", 2, 10, "n"],
        
        # Grâce
        ["grâce", "grâce", "Éphésiens", 2, 8, "n"],
        ["grâce", "grâce", "Jean", 1, 17, "n"],
        ["grâce", "grâce", "Romains", 3, 24, "n"],
        ["grâce", "grâce", "Tite", 2, 11, "n"],
        ["grâce", "grâce", "Hébreux", 4, 16, "n"],
        
        # Vérité
        ["vérité", "vérité", "Jean", 14, 6, "n"],
        ["vérité", "vérité", "Jean", 8, 32, "n"],
        ["vérité", "vérité", "Éphésiens", 4, 15, "n"],
        ["vérité", "vérité", "1 Jean", 1, 6, "n"],
        ["vérité", "vérité", "Psaumes", 119, 160, "n"],
        
        # Vie
        ["vie", "vie", "Jean", 3, 16, "n"],
        ["vie", "vie", "Jean", 10, 10, "n"],
        ["vie", "vie", "Romains", 6, 23, "n"],
        ["vie", "vie", "1 Jean", 5, 12, "n"],
        ["vie", "vie", "Apocalypse", 21, 6, "n"],
        
        # Salut
        ["salut", "salut", "Actes", 4, 12, "n"],
        ["salut", "salut", "Romains", 1, 16, "n"],
        ["salut", "salut", "Éphésiens", 2, 8, "n"],
        ["salut", "salut", "Philippiens", 1, 28, "n"],
        ["salut", "salut", "1 Pierre", 1, 9, "n"],
        
        # Royaume
        ["royaume", "royaume", "Matthieu", 6, 33, "n"],
        ["royaume", "royaume", "Luc", 17, 21, "n"],
        ["royaume", "royaume", "Jean", 3, 3, "n"],
        ["royaume", "royaume", "Actes", 1, 3, "n"],
        ["royaume", "royaume", "Apocalypse", 11, 15, "n"],
        
        # Saint
        ["saint", "saint", "Lévitique", 19, 2, "adj"],
        ["saint", "saint", "1 Pierre", 1, 16, "adj"],
        ["saint", "saint", "Hébreux", 12, 14, "adj"],
        ["saint", "saint", "Apocalypse", 4, 8, "adj"],
        ["saint", "saint", "Éphésiens", 1, 4, "adj"],
        
        # Parole
        ["parole", "parole", "Jean", 1, 1, "n"],
        ["parole", "parole", "Hébreux", 4, 12, "n"],
        ["parole", "parole", "2 Timothée", 3, 16, "n"],
        ["parole", "parole", "Psaumes", 119, 105, "n"],
        ["parole", "parole", "Matthieu", 4, 4, "n"],
        
        # Église
        ["église", "église", "Matthieu", 16, 18, "n"],
        ["église", "église", "Actes", 2, 47, "n"],
        ["église", "église", "1 Corinthiens", 12, 28, "n"],
        ["église", "église", "Éphésiens", 1, 22, "n"],
        ["église", "église", "Colossiens", 1, 18, "n"],
        
        # Pardon
        ["pardon", "pardon", "Matthieu", 6, 14, "n"],
        ["pardon", "pardon", "Luc", 23, 34, "n"],
        ["pardon", "pardon", "Actes", 2, 38, "n"],
        ["pardon", "pardon", "Éphésiens", 1, 7, "n"],
        ["pardon", "pardon", "1 Jean", 1, 9, "n"],
        
        # Espérance
        ["espérance", "espérance", "Romains", 15, 13, "n"],
        ["espérance", "espérance", "Hébreux", 6, 19, "n"],
        ["espérance", "espérance", "1 Pierre", 1, 3, "n"],
        ["espérance", "espérance", "Tite", 2, 13, "n"],
        ["espérance", "espérance", "1 Corinthiens", 13, 13, "n"],
        
        # Gloire
        ["gloire", "gloire", "Psaumes", 19, 1, "n"],
        ["gloire", "gloire", "Jean", 17, 5, "n"],
        ["gloire", "gloire", "Romains", 3, 23, "n"],
        ["gloire", "gloire", "1 Corinthiens", 10, 31, "n"],
        ["gloire", "gloire", "Apocalypse", 4, 11, "n"],
        
        # Lumière
        ["lumière", "lumière", "Genèse", 1, 3, "n"],
        ["lumière", "lumière", "Jean", 8, 12, "n"],
        ["lumière", "lumière", "Matthieu", 5, 14, "n"],
        ["lumière", "lumière", "1 Jean", 1, 5, "n"],
        ["lumière", "lumière", "Apocalypse", 21, 23, "n"],
        
        # Ténèbres
        ["ténèbres", "ténèbres", "Genèse", 1, 2, "n"],
        ["ténèbres", "ténèbres", "Jean", 1, 5, "n"],
        ["ténèbres", "ténèbres", "1 Jean", 1, 6, "n"],
        ["ténèbres", "ténèbres", "Éphésiens", 6, 12, "n"],
        ["ténèbres", "ténèbres", "Colossiens", 1, 13, "n"],
        
        # Croix
        ["croix", "croix", "Matthieu", 27, 32, "n"],
        ["croix", "croix", "Jean", 19, 17, "n"],
        ["croix", "croix", "1 Corinthiens", 1, 18, "n"],
        ["croix", "croix", "Galates", 6, 14, "n"],
        ["croix", "croix", "Philippiens", 2, 8, "n"],
        
        # Résurrection
        ["résurrection", "résurrection", "Matthieu", 28, 6, "n"],
        ["résurrection", "résurrection", "Jean", 11, 25, "n"],
        ["résurrection", "résurrection", "Actes", 4, 33, "n"],
        ["résurrection", "résurrection", "1 Corinthiens", 15, 20, "n"],
        ["résurrection", "résurrection", "Apocalypse", 20, 6, "n"],
        
        # Éternel
        ["éternel", "éternel", "Psaumes", 90, 2, "adj"],
        ["éternel", "éternel", "Jean", 3, 16, "adj"],
        ["éternel", "éternel", "Romains", 6, 23, "adj"],
        ["éternel", "éternel", "2 Corinthiens", 4, 18, "adj"],
        ["éternel", "éternel", "Apocalypse", 21, 6, "adj"],
    ]
    
    return concordance_data

def generate_topics_links():
    """Génère des liens de thèmes"""
    topics_links = [
        # Thème 0: Amour
        (0, "Jean", 3, 16, 0.95),
        (0, "1 Jean", 4, 8, 0.9),
        (0, "1 Corinthiens", 13, 4, 0.85),
        (0, "Matthieu", 22, 37, 0.8),
        (0, "1 Jean", 4, 19, 0.75),
        
        # Thème 1: Foi
        (1, "Hébreux", 11, 1, 0.95),
        (1, "Romains", 10, 17, 0.9),
        (1, "Jean", 3, 16, 0.85),
        (1, "2 Corinthiens", 4, 13, 0.8),
        (1, "Actes", 16, 31, 0.75),
        
        # Thème 2: Prière
        (2, "Matthieu", 6, 9, 0.95),
        (2, "1 Thessaloniciens", 5, 17, 0.9),
        (2, "Actes", 1, 14, 0.85),
        (2, "Philippiens", 4, 6, 0.8),
        (2, "Jacques", 5, 16, 0.75),
        
        # Thème 3: Paix
        (3, "Jean", 14, 27, 0.95),
        (3, "Romains", 5, 1, 0.9),
        (3, "Philippiens", 4, 7, 0.85),
        (3, "Colossiens", 3, 15, 0.8),
        (3, "Éphésiens", 2, 14, 0.75),
        
        # Thème 4: Joie
        (4, "Galates", 5, 22, 0.95),
        (4, "Philippiens", 4, 4, 0.9),
        (4, "Néhémie", 8, 10, 0.85),
        (4, "Psaumes", 16, 11, 0.8),
        (4, "Luc", 2, 10, 0.75),
        
        # Thème 5: Grâce
        (5, "Éphésiens", 2, 8, 0.95),
        (5, "Jean", 1, 17, 0.9),
        (5, "Romains", 3, 24, 0.85),
        (5, "Tite", 2, 11, 0.8),
        (5, "Hébreux", 4, 16, 0.75),
        
        # Thème 6: Vérité
        (6, "Jean", 14, 6, 0.95),
        (6, "Jean", 8, 32, 0.9),
        (6, "Éphésiens", 4, 15, 0.85),
        (6, "1 Jean", 1, 6, 0.8),
        (6, "Psaumes", 119, 160, 0.75),
        
        # Thème 7: Vie
        (7, "Jean", 3, 16, 0.95),
        (7, "Jean", 10, 10, 0.9),
        (7, "Romains", 6, 23, 0.85),
        (7, "1 Jean", 5, 12, 0.8),
        (7, "Apocalypse", 21, 6, 0.75),
        
        # Thème 8: Salut
        (8, "Actes", 4, 12, 0.95),
        (8, "Romains", 1, 16, 0.9),
        (8, "Éphésiens", 2, 8, 0.85),
        (8, "Philippiens", 1, 28, 0.8),
        (8, "1 Pierre", 1, 9, 0.75),
        
        # Thème 9: Royaume
        (9, "Matthieu", 6, 33, 0.95),
        (9, "Luc", 17, 21, 0.9),
        (9, "Jean", 3, 3, 0.85),
        (9, "Actes", 1, 3, 0.8),
        (9, "Apocalypse", 11, 15, 0.75),
    ]
    
    return topics_links

def main():
    print("🚀 Génération d'une concordance BSB complète...")
    
    # Générer la concordance
    concordance_data = generate_concordance()
    
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
