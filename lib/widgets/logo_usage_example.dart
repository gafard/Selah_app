import 'package:flutter/material.dart';
import 'selah_logo.dart';

/// Exemple d'utilisation des widgets de logo Selah
/// 
/// Ce fichier montre comment utiliser les différents widgets de logo
/// dans votre application Flutter.
class LogoUsageExample extends StatelessWidget {
  const LogoUsageExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exemples de Logo Selah'),
        backgroundColor: const Color(0xFF1553FF),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Icônes
            _buildSection(
              'Icônes',
              [
                _buildExample(
                  'Icône App (fond bleu)',
                  const SelahAppIcon(size: 64, useBlueBackground: true),
                ),
                _buildExample(
                  'Icône App (fond blanc)',
                  const SelahAppIcon(size: 64, useBlueBackground: false),
                ),
                _buildExample(
                  'Icône transparente',
                  const SelahLogo(
                    variant: SelahLogoVariant.transparent,
                    width: 64,
                    height: 64,
                  ),
                ),
                _buildExample(
                  'Icône monochrome',
                  const SelahLogo(
                    variant: SelahLogoVariant.monochrome,
                    width: 64,
                    height: 64,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Section Lockups
            _buildSection(
              'Lockups (Icône + Texte)',
              [
                _buildExample(
                  'Lockup horizontal',
                  const SelahLogo(
                    variant: SelahLogoVariant.horizontal,
                    height: 40,
                  ),
                ),
                _buildExample(
                  'Lockup horizontal transparent',
                  const SelahLogo(
                    variant: SelahLogoVariant.horizontalTransparent,
                    height: 40,
                  ),
                ),
                _buildExample(
                  'Lockup empilé',
                  const SelahLogo(
                    variant: SelahLogoVariant.stacked,
                    height: 120,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Section Widgets spécialisés
            _buildSection(
              'Widgets Spécialisés',
              [
                _buildExample(
                  'Header Logo',
                  const SelahHeaderLogo(height: 32),
                ),
                _buildExample(
                  'Splash Logo',
                  const SelahSplashLogo(size: 100),
                ),
                _buildExample(
                  'Favicon',
                  const SelahFavicon(size: 32),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Section avec couleurs personnalisées
            _buildSection(
              'Avec Couleurs Personnalisées',
              [
                _buildExample(
                  'Logo bleu personnalisé',
                  const SelahLogo(
                    variant: SelahLogoVariant.transparent,
                    width: 64,
                    height: 64,
                    color: Color(0xFF1553FF),
                  ),
                ),
                _buildExample(
                  'Logo vert personnalisé',
                  const SelahLogo(
                    variant: SelahLogoVariant.transparent,
                    width: 64,
                    height: 64,
                    color: Color(0xFF49C98D),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Section usage dans différents contextes
            _buildSection(
              'Usage dans l\'App',
              [
                _buildContextExample(
                  'Header de page',
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Page d\'accueil',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SelahAppIcon(size: 32, useBlueBackground: false),
                      ],
                    ),
                  ),
                ),
                _buildContextExample(
                  'Splash Screen',
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1553FF), Color(0xFF49C98D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: SelahSplashLogo(size: 120),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildExample(String description, Widget logo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 12),
          Center(child: logo),
        ],
      ),
    );
  }

  Widget _buildContextExample(String description, Widget example) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          example,
        ],
      ),
    );
  }
}
