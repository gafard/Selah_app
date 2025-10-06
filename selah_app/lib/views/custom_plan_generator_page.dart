import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';
import '../services/ics_import_service.dart';
import '../services/user_prefs_hive.dart';
import '../services/plan_service.dart';
import '../services/telemetry_console.dart';
import '../models/plan_models.dart';

class CustomPlanGeneratorPage extends StatefulWidget {
  const CustomPlanGeneratorPage({super.key});

  @override
  State<CustomPlanGeneratorPage> createState() => _CustomPlanGeneratorPageState();
}

class _CustomPlanGeneratorPageState extends State<CustomPlanGeneratorPage> {
  final _nameController = TextEditingController();
  DateTime _startDate = DateTime.now();
  int _totalDays = 365;
  String _order = 'traditional';
  String _books = 'OT,NT';
  final String _lang = 'fr';
  final String _logic = 'words';
  final bool _includeUrls = true;
  final String _urlSite = 'biblegateway';
  String _urlVersion = 'NIV';
  final List<int> _daysOfWeek = [1, 2, 3, 4, 5, 6, 7];
  bool _isGenerating = false;
  bool _blockPop = false; // empêcher retour pendant génération
  
  // Détection réseau
  late final Connectivity _conn;
  Stream<List<ConnectivityResult>>? _connStream;
  bool _online = true;

  // mapping "UI -> générateur"
  static const Map<String, String> _versionMap = {
    'LSG': 'LSG', // si supporté par ton générateur
    'S21': 'S21',
    'NIV': 'NIV',
    'ESV': 'ESV',
    'KJV': 'KJV',
  };

  String get _mappedVersion => _versionMap[_urlVersion] ?? 'NIV';

  @override
  void initState() {
    super.initState();
    _conn = Connectivity();
    _connStream = _conn.onConnectivityChanged;
    _watchConnectivity();
    _hydrateFromPrefs();
  }

  Future<void> _watchConnectivity() async {
    final first = await _conn.checkConnectivity();
    setState(() => _online = first.isNotEmpty && first.first != ConnectivityResult.none);
    _connStream?.listen((results) {
      setState(() => _online = results.isNotEmpty && results.first != ConnectivityResult.none);
    });
  }

  Future<void> _hydrateFromPrefs() async {
    try {
      final userPrefs = context.read<UserPrefsHive>();
      final profile = userPrefs.profile;
      final version = profile['bibleVersion'] as String?; // ex: 'LSG'
      final dow = (profile['daysOfWeek'] as List?)?.cast<int>();
      final goal = profile['goal'] as String? ?? '';
      final level = profile['level'] as String? ?? '';

      setState(() {
        if (version != null && _versionMap.containsKey(version)) {
          _urlVersion = version;
        }
        if (dow != null && dow.isNotEmpty) {
          _daysOfWeek
            ..clear()
            ..addAll(dow);
        }
        
        // Pré-suggestions basées sur le profil utilisateur
        if (goal == 'Discipline quotidienne') {
          _books = 'Psalms,Proverbs';
          _totalDays = 60;
          _order = 'traditional';
        }
        if (goal == 'Mieux prier') {
          _books = 'Psalms';
          _totalDays = 40;
          _order = 'thematic';
        }
        if (goal == 'Approfondir la Parole') {
          _books = 'OT,NT';
          _totalDays = 180;
          _order = 'chronological';
        }
        if (goal == 'Grandir dans la foi') {
          _books = 'NT';
          _totalDays = 90;
          _order = 'chronological';
        }
        
        // Ajustements selon le niveau
        if (level == 'Nouveau converti') {
          _order = 'traditional';
          _totalDays = _totalDays > 60 ? 60 : _totalDays; // Limiter à 60 jours max
        }
        if (level == 'Serviteur/leader') {
          _totalDays = _totalDays < 90 ? 90 : _totalDays; // Minimum 90 jours
        }
      });
    } catch (_) {
      // silent fallback
    }
  }

  final List<String> _orderOptions = [
    'traditional',
    'chronological',
    'historical',
    'thematic',
  ];

  final List<String> _bookOptions = [
    'OT,NT',
    'NT',
    'OT',
    'Gospels,Psalms',
    'Gospels',
    'Psalms,Proverbs',
    'Psalms',
  ];


  final List<String> _urlVersionOptions = [
    'NIV',
    'ESV',
    'KJV',
    'LSG',
    'S21',
  ];

  final List<String> _dayNames = [
    'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !_blockPop,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1C1740), Color(0xFF2D1B69)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header moderne
                _buildHeader(),
                // Bannière réseau
                _networkBanner(),
                // Contenu scrollable
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                            // Nom du plan
                            _buildSection(
                              title: 'Nom du plan',
                              child: _buildModernTextField(
                                controller: _nameController,
                                hint: 'Ex: Mon plan de lecture 2024',
                                icon: Icons.text_fields,
                              ),
                            ),

                            // Date de début
                            _buildSection(
                              title: 'Date de début',
                              child: _buildDateSelector(),
                            ),

                            // Durée
                            _buildSection(
                              title: 'Durée (jours)',
                              child: _buildDurationSlider(),
                            ),

                            // Ordre de lecture
                            _buildSection(
                              title: 'Ordre de lecture',
                              child: _buildModernDropdown(
                                value: _order,
                                items: _orderOptions,
                                onChanged: (value) => setState(() => _order = value!),
                                displayName: _getOrderDisplayName,
                              ),
                            ),

                            // Livres
                            _buildSection(
                              title: 'Livres à inclure',
                              child: _buildModernDropdown(
                                value: _books,
                                items: _bookOptions,
                                onChanged: (value) => setState(() => _books = value!),
                                displayName: _getBooksDisplayName,
                              ),
                            ),

                            // Jours de la semaine
                            _buildSection(
                              title: 'Jours de lecture',
                              child: _buildDaysSelector(),
                            ),

                            // Version biblique
                            _buildSection(
                              title: 'Version biblique',
                              child: _buildModernDropdown(
                                value: _urlVersion,
                                items: _urlVersionOptions,
                                onChanged: (value) => setState(() => _urlVersion = value!),
                                displayName: (value) => value,
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Résumé du plan
                            _buildSection(
                              title: 'Résumé',
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _summaryLine('Nom', _nameController.text.isEmpty ? '—' : _nameController.text.trim()),
                                    _summaryLine('Début', '${_startDate.day}/${_startDate.month}/${_startDate.year}'),
                                    _summaryLine('Durée', '$_totalDays jours'),
                                    _summaryLine('Ordre', _getOrderDisplayName(_order)),
                                    _summaryLine('Livres', _getBooksDisplayName(_books)),
                                    _summaryLine('Version', _mappedVersion),
                                    _summaryLine('Jours', (_daysOfWeek..sort()).map((d) => _dayNames[d-1]).join(' · ')),
                                  ],
                                ),
                              ),
                            ),

                            // Espace pour la barre collante
                            const SizedBox(height: 96),
                          ],
                        ),
                      ),
                    ),
                // Barre résumé collante
                _stickySummaryBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Générer un plan personnalisé',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Créez votre plan de lecture sur mesure',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        child,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.inter(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.white54),
          prefixIcon: Icon(icon, color: Colors.white70),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectStartDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.white70, size: 20),
            const SizedBox(width: 12),
            Text(
              '${_startDate.day}/${_startDate.month}/${_startDate.year}',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSlider() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _totalDays.toDouble(),
                  min: 30,
                  max: 730,
                  divisions: 70,
                  onChanged: (value) {
                    setState(() {
                      _totalDays = value.round();
                    });
                  },
                  activeColor: Colors.white,
                  inactiveColor: Colors.white.withOpacity(0.3),
                ),
              ),
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_totalDays',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          Text(
            '$_totalDays jours de lecture',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required String Function(String) displayName,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        dropdownColor: const Color(0xFF2D1B69),
        style: GoogleFonts.inter(color: Colors.white),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(
              displayName(item),
              style: GoogleFonts.inter(fontSize: 16, color: Colors.white),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDaysSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(7, (index) {
          final isSelected = _daysOfWeek.contains(index + 1);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _daysOfWeek.remove(index + 1);
                } else {
                  _daysOfWeek.add(index + 1);
                }
              });
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  _dayNames[index],
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? const Color(0xFF1C1740) : Colors.white,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }


  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  String _getOrderDisplayName(String order) {
    switch (order) {
      case 'traditional':
        return 'Traditionnel';
      case 'chronological':
        return 'Chronologique';
      case 'historical':
        return 'Historique';
      case 'thematic':
        return 'Thématique';
      default:
        return order;
    }
  }

  String _getBooksDisplayName(String books) {
    switch (books) {
      case 'OT,NT':
        return 'Ancien + Nouveau Testament';
      case 'NT':
        return 'Nouveau Testament';
      case 'OT':
        return 'Ancien Testament';
      case 'Gospels,Psalms':
        return 'Évangiles + Psaumes';
      case 'Gospels':
        return 'Évangiles';
      case 'Psalms,Proverbs':
        return 'Psaumes + Proverbes';
      case 'Psalms':
        return 'Psaumes';
      default:
        return books;
    }
  }

  Future<void> _generatePlan() async {
    if (!_validateAndVibrate()) return;
    
    if (_totalDays < 30 || _totalDays > 730) {
      _showError('La durée doit être entre 30 et 730 jours');
      HapticFeedback.mediumImpact();
      return;
    }

    setState(() {
      _isGenerating = true;
      _blockPop = true;
    });

    _showBlockingProgress('1/3 Génération de l\'URL…');
    
    try {
      // Construire l'URL du générateur avec mapping de version
      final icsUrl = buildGeneratorIcsUrl(
        start: _startDate,
        totalDays: _totalDays,
        order: _order,
        daysOfWeek: List<int>.from(_daysOfWeek)..sort(),
        books: _books,
        lang: _lang,
        logic: _logic,
        includeUrls: _includeUrls,
        urlSite: _urlSite,
        urlVersion: _mappedVersion,
      );

      _updateBlockingProgress('2/3 Import du plan…');
      
      // Utiliser le PlanService pour importer le plan
      final planService = context.read<PlanService>();
      final telemetry = context.read<TelemetryConsole>();
      
      telemetry.event('custom_plan_generation_started', {
        'plan_name': _nameController.text.trim(),
        'total_days': _totalDays,
        'books': _books,
        'order': _order,
      });

      // Retry x2 si l'import échoue
      final plan = await _retry<Plan>(
        () => planService.importFromGenerator(
          planName: _nameController.text.trim(),
          icsUrl: Uri.parse(icsUrl.toString()),
        ),
        attempts: 2,
      );

      _updateBlockingProgress('3/3 Indexation & rappels…');

      // Sauvegarder les derniers choix pour le confort
      final userPrefs = context.read<UserPrefsHive>();
      await userPrefs.patchProfile({
        'bibleVersion': _urlVersion,
        'daysOfWeek': _daysOfWeek,
        'lastCustomPlanName': _nameController.text.trim(),
        'lastCustomPlanDays': _totalDays,
        'lastCustomPlanOrder': _order,
        'lastCustomPlanBooks': _books,
      });

      telemetry.event('custom_plan_generation_completed', {
        'plan_id': plan.id,
        'plan_name': plan.name,
        'total_days': plan.totalDays,
      });

      Navigator.of(context, rootNavigator: true).pop(); // ferme modal
      if (!mounted) return;
      
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('Plan "${plan.name}" créé avec succès !')),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );

      // Navigation vers la page d'accueil
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop(); // ferme modal si erreur
      if (!mounted) return;
      
      final telemetry = context.read<TelemetryConsole>();
      telemetry.event('custom_plan_generation_failed', {
        'error': e.toString(),
        'plan_name': _nameController.text.trim(),
      });
      
      // Gestion d'erreur spécifique selon le type
      String errorMessage;
      if (e.toString().contains('network') || e.toString().contains('connection')) {
        errorMessage = 'Problème de connexion. Vérifiez votre réseau et réessayez.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Le serveur met trop de temps à répondre. Réessayez plus tard.';
      } else if (e.toString().contains('404') || e.toString().contains('not found')) {
        errorMessage = 'Le générateur de plan n\'est pas disponible. Réessayez plus tard.';
      } else {
        errorMessage = 'Erreur lors de la génération: ${e.toString().split(':').last.trim()}';
      }
      
      _showError(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _blockPop = false;
        });
      }
    }
  }

  void _showError(String message) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<T> _retry<T>(Future<T> Function() run, {int attempts = 2}) async {
    int left = attempts;
    dynamic lastErr;
    while (left > 0) {
      try {
        return await run();
      } catch (e) {
        lastErr = e;
        left--;
        if (left > 0) {
          await Future.delayed(const Duration(milliseconds: 600));
        }
      }
    }
    throw lastErr ?? Exception('Échec inconnu');
  }


  bool _validateAndVibrate() {
    if (_nameController.text.trim().isEmpty) {
      _showError('Veuillez saisir un nom pour le plan');
      HapticFeedback.mediumImpact();
      return false;
    }
    if (_daysOfWeek.isEmpty) {
      _showError('Sélectionnez au moins un jour de lecture');
      HapticFeedback.mediumImpact();
      return false;
    }
    if (!_online) {
      _showError('Aucune connexion — réessayez en ligne');
      HapticFeedback.mediumImpact();
      return false;
    }
    return true;
  }

  void _showBlockingProgress(String text) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ProgressDialog(text: text),
    );
  }

  void _updateBlockingProgress(String text) {
    // ferme et rouvre avec le nouveau texte
    Navigator.of(context, rootNavigator: true).pop();
    _showBlockingProgress(text);
  }

  Widget _networkBanner() => AnimatedContainer(
    duration: const Duration(milliseconds: 220),
    height: _online ? 0 : 36,
    color: Colors.red.withOpacity(.18),
    child: Center(
      child: Text(
        'Hors-ligne — la génération nécessite Internet',
        style: GoogleFonts.inter(
          color: Colors.white, 
          fontSize: 12, 
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );

  Widget _stickySummaryBar() {
    final daysTxt = (_daysOfWeek..sort()).map((d) => _dayNames[d-1]).join(' · ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(.12))),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          // Résumé compact
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameController.text.isEmpty ? 'Plan sans nom' : _nameController.text,
                  style: GoogleFonts.inter(
                    color: Colors.white, 
                    fontSize: 14, 
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_startDate.day}/${_startDate.month}/${_startDate.year} • $_totalDays j • $daysTxt • $_urlVersion',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // CTA principal
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generatePlan,
              icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
              label: Text(
                'Générer', 
                style: GoogleFonts.inter(
                  color: Colors.white, 
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent, 
                shadowColor: Colors.transparent, 
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryLine(String label, Object value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13))),
        Text('$value', style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    ),
  );

}

class _ProgressDialog extends StatelessWidget {
  final String text;
  const _ProgressDialog({required this.text});
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1F1B3B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const SizedBox(
              height: 22, 
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2, 
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text, 
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
