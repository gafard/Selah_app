#!/usr/bin/env python3
"""
Script de nettoyage après conversion BSB
Supprime les fichiers temporaires et optimise l'espace disque
"""

import os
import shutil

def cleanup_conversion_files():
    """Nettoie les fichiers de conversion temporaires"""
    print("🧹 Nettoyage des fichiers de conversion BSB...")
    
    # Fichiers à supprimer
    files_to_remove = [
        "tools/convert_bsb_data.py",
        "tools/optimize_bsb_data.py",
        "tools/cleanup_bsb_conversion.py",
    ]
    
    # Dossiers à vérifier
    dirs_to_check = [
        "assets/data",
    ]
    
    removed_count = 0
    
    # Supprimer les fichiers
    for file_path in files_to_remove:
        if os.path.exists(file_path):
            try:
                os.remove(file_path)
                print(f"   🗑️  Supprimé: {file_path}")
                removed_count += 1
            except Exception as e:
                print(f"   ⚠️  Erreur suppression {file_path}: {e}")
    
    # Vérifier les dossiers
    for dir_path in dirs_to_check:
        if os.path.exists(dir_path):
            files = os.listdir(dir_path)
            print(f"   📁 Dossier {dir_path}: {len(files)} fichiers")
            
            # Afficher la taille des fichiers
            total_size = 0
            for file in files:
                file_path = os.path.join(dir_path, file)
                if os.path.isfile(file_path):
                    size = os.path.getsize(file_path)
                    total_size += size
                    print(f"      📄 {file}: {size / 1024 / 1024:.2f} MB")
            
            print(f"      💾 Taille totale: {total_size / 1024 / 1024:.2f} MB")
    
    print(f"\n✅ Nettoyage terminé: {removed_count} fichiers supprimés")
    
    # Afficher les statistiques finales
    print(f"\n📊 Statistiques finales des données BSB:")
    
    concordance_path = "assets/data/bsb_concordance_optimized.json"
    topical_path = "assets/data/bsb_topical_index_optimized.json"
    thomson_path = "assets/data/thomson_analysis.json"
    
    total_size = 0
    
    if os.path.exists(concordance_path):
        size = os.path.getsize(concordance_path) / 1024 / 1024
        total_size += size
        print(f"   📚 Concordance BSB: {size:.2f} MB")
    
    if os.path.exists(topical_path):
        size = os.path.getsize(topical_path) / 1024 / 1024
        total_size += size
        print(f"   🏷️  Index thématique BSB: {size:.2f} MB")
    
    if os.path.exists(thomson_path):
        size = os.path.getsize(thomson_path) / 1024 / 1024
        total_size += size
        print(f"   🔬 Analyse Thomson: {size:.2f} MB")
    
    print(f"   💾 Taille totale des données d'étude: {total_size:.2f} MB")
    
    # Recommandations
    print(f"\n💡 Recommandations:")
    if total_size < 20:
        print(f"   ✅ Taille acceptable pour une application mobile")
    elif total_size < 50:
        print(f"   ⚠️  Taille modérée - surveiller les performances")
    else:
        print(f"   ❌ Taille importante - considérer une optimisation supplémentaire")
    
    print(f"\n🎯 Services disponibles:")
    print(f"   📚 BSBConcordanceService - Recherche de mots bibliques")
    print(f"   🏷️  BSBTopicalService - Index thématique")
    print(f"   🔬 ThomsonService - Analyse sémantique")
    print(f"   📖 BibleContextService - Contexte historique")

if __name__ == "__main__":
    cleanup_conversion_files()

