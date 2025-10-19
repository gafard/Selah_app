#!/usr/bin/env python3
"""
Script de conversion des données BSB (concordance et index thématique) 
en JSON optimisé pour l'application Flutter.
"""

import pandas as pd
import json
import os
from pathlib import Path

def analyze_excel_structure(file_path):
    """Analyse la structure d'un fichier Excel"""
    print(f"\n🔍 Analyse de {file_path}")
    
    try:
        # Lire toutes les feuilles
        excel_file = pd.ExcelFile(file_path)
        print(f"   📊 Feuilles disponibles: {excel_file.sheet_names}")
        
        for sheet_name in excel_file.sheet_names:
            print(f"\n   📋 Feuille: {sheet_name}")
            df = pd.read_excel(file_path, sheet_name=sheet_name)
            print(f"   📏 Dimensions: {df.shape[0]} lignes x {df.shape[1]} colonnes")
            print(f"   📝 Colonnes: {list(df.columns)}")
            
            # Afficher les premières lignes
            print("   🔤 Premières lignes:")
            print(df.head(3).to_string())
            
            # Analyser les types de données
            print(f"   🏷️  Types de données:")
            for col in df.columns:
                non_null_count = df[col].count()
                print(f"      {col}: {df[col].dtype} ({non_null_count} valeurs non-null)")
                
    except Exception as e:
        print(f"   ❌ Erreur lors de l'analyse: {e}")

def convert_concordance_to_json(excel_path, output_path):
    """Convertit la concordance BSB en JSON optimisé"""
    print(f"\n📚 Conversion de la concordance BSB...")
    
    try:
        # Lire la concordance
        df = pd.read_excel(excel_path)
        print(f"   📊 {len(df)} entrées de concordance trouvées")
        
        # Analyser la structure
        print(f"   📝 Colonnes: {list(df.columns)}")
        
        # Créer un index optimisé par mot
        concordance_index = {}
        
        for _, row in df.iterrows():
            # Adapter selon la structure réelle du fichier
            word = str(row.iloc[0]).strip().lower() if pd.notna(row.iloc[0]) else ""
            if not word:
                continue
                
            # Extraire les références (adapter selon la structure)
            references = []
            for col in df.columns[1:]:  # Supposer que les colonnes suivantes sont des références
                if pd.notna(row[col]):
                    ref = str(row[col]).strip()
                    if ref and ref != "nan":
                        references.append(ref)
            
            if references:
                concordance_index[word] = {
                    "references": references,
                    "count": len(references)
                }
        
        # Sauvegarder en JSON
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(concordance_index, f, ensure_ascii=False, indent=2)
        
        print(f"   ✅ Concordance convertie: {len(concordance_index)} mots")
        print(f"   💾 Sauvegardé dans: {output_path}")
        
        # Statistiques
        total_refs = sum(data["count"] for data in concordance_index.values())
        print(f"   📊 Total références: {total_refs}")
        
        return concordance_index
        
    except Exception as e:
        print(f"   ❌ Erreur conversion concordance: {e}")
        return None

def convert_topical_index_to_json(excel_path, output_path):
    """Convertit l'index thématique BSB en JSON optimisé"""
    print(f"\n🏷️  Conversion de l'index thématique BSB...")
    
    try:
        # Lire l'index thématique
        df = pd.read_excel(excel_path)
        print(f"   📊 {len(df)} entrées thématiques trouvées")
        
        # Analyser la structure
        print(f"   📝 Colonnes: {list(df.columns)}")
        
        # Créer un index optimisé par thème
        topical_index = {}
        
        for _, row in df.iterrows():
            # Adapter selon la structure réelle du fichier
            theme = str(row.iloc[0]).strip() if pd.notna(row.iloc[0]) else ""
            if not theme or theme == "nan":
                continue
                
            # Extraire les références (adapter selon la structure)
            references = []
            for col in df.columns[1:]:  # Supposer que les colonnes suivantes sont des références
                if pd.notna(row[col]):
                    ref = str(row[col]).strip()
                    if ref and ref != "nan":
                        references.append(ref)
            
            if references:
                topical_index[theme] = {
                    "references": references,
                    "count": len(references)
                }
        
        # Sauvegarder en JSON
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(topical_index, f, ensure_ascii=False, indent=2)
        
        print(f"   ✅ Index thématique converti: {len(topical_index)} thèmes")
        print(f"   💾 Sauvegardé dans: {output_path}")
        
        # Statistiques
        total_refs = sum(data["count"] for data in topical_index.values())
        print(f"   📊 Total références: {total_refs}")
        
        return topical_index
        
    except Exception as e:
        print(f"   ❌ Erreur conversion index thématique: {e}")
        return None

def create_optimized_services(concordance_data, topical_data):
    """Crée des services Flutter optimisés"""
    print(f"\n🔧 Création des services Flutter optimisés...")
    
    # Service de concordance
    concordance_service = f"""
import 'dart:convert';
import 'package:flutter/services.dart';

/// Service de concordance BSB optimisé
class BSBConcordanceService {{
  static Map<String, dynamic>? _concordanceData;
  
  /// Initialise le service
  static Future<void> init() async {{
    if (_concordanceData != null) return;
    
    try {{
      final String jsonString = await rootBundle.loadString('assets/data/bsb_concordance.json');
      _concordanceData = json.decode(jsonString);
      print('✅ BSBConcordanceService initialisé avec ${{_concordanceData?.length ?? 0}} mots');
    }} catch (e) {{
      print('⚠️ Erreur chargement concordance BSB: $e');
      _concordanceData = {{}};
    }}
  }}
  
  /// Recherche un mot dans la concordance
  static Future<List<String>> searchWord(String word) async {{
    await init();
    
    if (_concordanceData == null) return [];
    
    final normalizedWord = word.toLowerCase().trim();
    final data = _concordanceData![normalizedWord];
    
    if (data == null) return [];
    
    return List<String>.from(data['references'] ?? []);
  }}
  
  /// Obtient les statistiques d'un mot
  static Future<Map<String, dynamic>?> getWordStats(String word) async {{
    await init();
    
    if (_concordanceData == null) return null;
    
    final normalizedWord = word.toLowerCase().trim();
    return _concordanceData![normalizedWord];
  }}
  
  /// Recherche partielle
  static Future<List<String>> searchPartial(String partial) async {{
    await init();
    
    if (_concordanceData == null) return [];
    
    final normalizedPartial = partial.toLowerCase().trim();
    final matches = <String>[];
    
    for (final word in _concordanceData!.keys) {{
      if (word.contains(normalizedPartial)) {{
        matches.add(word);
      }}
    }}
    
    return matches.take(20).toList(); // Limiter à 20 résultats
  }}
}}
"""
    
    # Service d'index thématique
    topical_service = f"""
import 'dart:convert';
import 'package:flutter/services.dart';

/// Service d'index thématique BSB optimisé
class BSBTopicalService {{
  static Map<String, dynamic>? _topicalData;
  
  /// Initialise le service
  static Future<void> init() async {{
    if (_topicalData != null) return;
    
    try {{
      final String jsonString = await rootBundle.loadString('assets/data/bsb_topical_index.json');
      _topicalData = json.decode(jsonString);
      print('✅ BSBTopicalService initialisé avec ${{_topicalData?.length ?? 0}} thèmes');
    }} catch (e) {{
      print('⚠️ Erreur chargement index thématique BSB: $e');
      _topicalData = {{}};
    }}
  }}
  
  /// Recherche un thème
  static Future<List<String>> searchTheme(String theme) async {{
    await init();
    
    if (_topicalData == null) return [];
    
    final normalizedTheme = theme.toLowerCase().trim();
    
    // Recherche exacte d'abord
    for (final key in _topicalData!.keys) {{
      if (key.toLowerCase() == normalizedTheme) {{
        return List<String>.from(_topicalData![key]['references'] ?? []);
      }}
    }}
    
    // Recherche partielle
    final matches = <String>[];
    for (final key in _topicalData!.keys) {{
      if (key.toLowerCase().contains(normalizedTheme)) {{
        matches.addAll(_topicalData![key]['references'] ?? []);
      }}
    }}
    
    return matches.take(50).toList(); // Limiter à 50 résultats
  }}
  
  /// Obtient tous les thèmes disponibles
  static Future<List<String>> getAllThemes() async {{
    await init();
    
    if (_topicalData == null) return [];
    
    return _topicalData!.keys.toList()..sort();
  }}
  
  /// Recherche partielle de thèmes
  static Future<List<String>> searchPartialTheme(String partial) async {{
    await init();
    
    if (_topicalData == null) return [];
    
    final normalizedPartial = partial.toLowerCase().trim();
    final matches = <String>[];
    
    for (final theme in _topicalData!.keys) {{
      if (theme.toLowerCase().contains(normalizedPartial)) {{
        matches.add(theme);
      }}
    }}
    
    return matches.take(20).toList(); // Limiter à 20 résultats
  }}
}}
"""
    
    # Sauvegarder les services
    with open('lib/services/bsb_concordance_service.dart', 'w', encoding='utf-8') as f:
        f.write(concordance_service)
    
    with open('lib/services/bsb_topical_service.dart', 'w', encoding='utf-8') as f:
        f.write(topical_service)
    
    print("   ✅ Services Flutter créés")
    print("   📁 bsb_concordance_service.dart")
    print("   📁 bsb_topical_service.dart")

def main():
    """Fonction principale"""
    print("🚀 Conversion des données BSB pour l'application Flutter")
    
    # Chemins des fichiers
    base_path = "/Users/gafardgnane/Downloads/Bibles versions"
    concordance_excel = f"{base_path}/bsb_concordance.xlsx"
    topical_excel = f"{base_path}/bsb_topical_index.xlsx"
    
    # Chemins de sortie
    output_dir = "assets/data"
    os.makedirs(output_dir, exist_ok=True)
    
    concordance_json = f"{output_dir}/bsb_concordance.json"
    topical_json = f"{output_dir}/bsb_topical_index.json"
    
    # Analyser la structure des fichiers
    analyze_excel_structure(concordance_excel)
    analyze_excel_structure(topical_excel)
    
    # Convertir les fichiers
    concordance_data = convert_concordance_to_json(concordance_excel, concordance_json)
    topical_data = convert_topical_index_to_json(topical_excel, topical_json)
    
    # Créer les services Flutter
    if concordance_data and topical_data:
        create_optimized_services(concordance_data, topical_data)
        
        # Afficher les statistiques finales
        concordance_size = os.path.getsize(concordance_json) / 1024 / 1024
        topical_size = os.path.getsize(topical_json) / 1024 / 1024
        
        print(f"\n📊 Statistiques finales:")
        print(f"   📚 Concordance: {len(concordance_data)} mots ({concordance_size:.2f} MB)")
        print(f"   🏷️  Index thématique: {len(topical_data)} thèmes ({topical_size:.2f} MB)")
        print(f"   💾 Taille totale: {concordance_size + topical_size:.2f} MB")
        
        print(f"\n✅ Conversion terminée avec succès!")
        print(f"   📁 Fichiers JSON créés dans: {output_dir}")
        print(f"   🔧 Services Flutter créés dans: lib/services/")
    else:
        print("\n❌ Erreur lors de la conversion")

if __name__ == "__main__":
    main()
