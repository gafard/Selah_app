import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart'; // ✅ Import GoRouter
import '../services/ics_import_service.dart';
import '../services/user_prefs_hive.dart';
import '../bootstrap.dart' as bootstrap;
import '../services/telemetry_console.dart';
import '../services/semantic_passage_boundary_service.dart';
import '../services/intelligent_duration_calculator.dart';
import '../models/plan_models.dart';
import '../widgets/uniform_back_button.dart';
import '../services/doctrine/doctrine_pipeline.dart'; // 🕊️ Pipeline doctrinal modulaire
import '../services/doctrine/anchored_doctrine_base.dart'; // 🕊️ DoctrineContext
import '../models/plan_templates.dart'; // 📋 Templates de plans standards

class CustomPlanGeneratorPage extends StatefulWidget {
  const CustomPlanGeneratorPage({super.key});

  @override
  State<CustomPlanGeneratorPage> createState() => _CustomPlanGeneratorPageState();
}

class _CustomPlanGeneratorPageState extends State<CustomPlanGeneratorPage> {
  final _nameController = TextEditingController();
  DateTime _startDate = DateTime.now();
  int _totalDays = 5;
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
  
  // 🧠 Variables pour IntelligentDurationCalculator
  DurationCalculation? _durationRecommendation;
  bool _isCalculatingDuration = false;
  
  // Détection réseau
  late final Connectivity _conn;
  Stream<List<ConnectivityResult>>? _connStream;
  bool _online = true;
  
  // 🕊️ Profil utilisateur pour le pipeline doctrinal
  Map<String, dynamic>? _userProfile;

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
      
      // 🕊️ Charger le profil utilisateur pour le pipeline doctrinal
      _userProfile = profile;
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
    
    // 🧠 Calculer la durée optimale au chargement
    _calculateOptimalDuration();
  }
  
  /// 🧠 Calcule la durée optimale avec IntelligentDurationCalculator
  Future<void> _calculateOptimalDuration() async {
    if (_isCalculatingDuration) return;
    
    setState(() {
      _isCalculatingDuration = true;
    });
    
    try {
      final profile = context.read<UserPrefsHive>().profile;
      
      // 🧠 CALCUL INTELLIGENT DE LA DURÉE
      final durationCalculation = IntelligentDurationCalculator.calculateOptimalDuration(
        goal: profile['goal'] ?? 'Discipline quotidienne',
        level: profile['level'] ?? 'Fidèle régulier',
        dailyMinutes: profile['durationMin'] ?? 15,
        meditationType: profile['meditation'] ?? 'Méditation biblique',
      );
      
      setState(() {
        _durationRecommendation = durationCalculation;
        _totalDays = durationCalculation.optimalDays;
        _isCalculatingDuration = false;
      });
      
      print('🧠 Durée optimale calculée: ${durationCalculation.optimalDays} jours');
      print('📊 Raisonnement: ${durationCalculation.reasoning}');
      if (durationCalculation.warnings.isNotEmpty) {
        print('⚠️ Avertissements: ${durationCalculation.warnings.join(', ')}');
      }
    } catch (e) {
      print('❌ Erreur calcul durée: $e');
      setState(() {
        _isCalculatingDuration = false;
      });
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
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                            // Plans suggérés
                            _buildSuggestedPlansSection(),
                            
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
                              child: Column(
                                children: [
                                  _buildDurationSlider(),
                                  SizedBox(height: 8),
                                  // Les systèmes intelligents travaillent en arrière-plan
                                ],
                              ),
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
                            const SizedBox(height: 120),
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
    return UniformHeader(
      title: 'Générer un plan personnalisé',
      subtitle: 'Créez votre plan de lecture sur mesure',
      onBackPressed: () => context.go('/goals'), // ✅ Utiliser GoRouter
      textColor: Colors.white,
      iconColor: Colors.white,
      titleAlignment: CrossAxisAlignment.center,
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

  Widget _buildSuggestedPlansSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plans suggérés',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: kPlanTemplates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final template = kPlanTemplates[index];
              return _buildTemplateCard(template);
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTemplateCard(PlanTemplate template) {
    return GestureDetector(
      onTap: () => _applyTemplate(template),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${template.days}j',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.auto_awesome,
                  color: Colors.white.withOpacity(0.7),
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              template.title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              template.description,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white70,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Icon(
                  Icons.touch_app,
                  color: Colors.white.withOpacity(0.6),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  'Appliquer',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _applyTemplate(PlanTemplate template) {
    setState(() {
      _nameController.text = template.title;
      _totalDays = template.days;
      
      // Mapper les livres du template vers les options disponibles
      if (template.books.length == 27 && template.books.contains('Matthieu') && template.books.contains('Apocalypse')) {
        _books = 'NT';
      } else if (template.books.length == 66) {
        _books = 'OT,NT';
      } else if (template.books.contains('Psaumes') && template.books.contains('Proverbes')) {
        _books = 'Psalms,Proverbs';
      } else if (template.books.contains('Matthieu') && template.books.contains('Jean') && template.books.length == 4) {
        _books = 'Gospels';
      } else if (template.books.contains('Romains') && template.books.contains('Jude')) {
        _books = 'NT'; // Épîtres font partie du NT
      }
    });
    
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Template "${template.title}" appliqué !'),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
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
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.done,
        enableInteractiveSelection: true,
        autocorrect: false,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.white54),
          prefixIcon: Icon(icon, color: Colors.white70),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
    // 🧠 Utiliser les bornes intelligentes si disponibles
    final minDays = _durationRecommendation?.minDays ?? 5;
    final maxDays = _durationRecommendation?.maxDays ?? 360;
    final divisions = maxDays - minDays;
    
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
          // Les systèmes intelligents travaillent en arrière-plan
          
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _totalDays.toDouble().clamp(minDays.toDouble(), maxDays.toDouble()),
                  min: minDays.toDouble(),
                  max: maxDays.toDouble(),
                  divisions: divisions,
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
          
          // Les systèmes intelligents travaillent en arrière-plan
        ],
      ),
    );
  }
  
  // Les systèmes intelligents travaillent en arrière-plan sans interface visible
  Widget _buildIntelligenceRecommendations() {
    return SizedBox.shrink(); // Pas d'interface visible
  }
  
  /// 🎨 Couleur basée sur le niveau de confiance
  Color _getConfidenceColor(double confidence) {
    if (confidence >= 80) return Colors.green;
    if (confidence >= 60) return Colors.orange;
    return Colors.red;
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
    
    if (_totalDays < 5 || _totalDays > 360) {
      _showError('La durée doit être entre 5 et 360 jours');
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
      final planService = bootstrap.planService;
      final telemetry = context.read<TelemetryConsole>();
      
      telemetry.event('custom_plan_generation_started', {
        'plan_name': _nameController.text.trim(),
        'total_days': _totalDays,
        'books': _books,
        'order': _order,
      });

      // Créer un plan local avec les passages générés intelligemment
      final plan = await bootstrap.planService.createLocalPlan(
        name: _nameController.text.trim(),
        totalDays: _totalDays,
        books: _books,
        startDate: DateTime.now(),
        minutesPerDay: 15, // Valeur par défaut
        daysOfWeek: _daysOfWeek,
        customPassages: _generateOfflinePassages(
          booksKey: _books,
          totalDays: _totalDays,
          startDate: DateTime.now(),
          daysOfWeek: _daysOfWeek,
        ),
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
      context.go('/home'); // ✅ Utiliser GoRouter
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

  Future<Plan> _createLocalPlan() async {
    // Créer un plan local simple
    final plan = Plan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: 'local_user',
      name: _nameController.text.trim(),
      totalDays: _totalDays,
      startDate: _startDate,
      isActive: true,
      books: _books,
      minutesPerDay: 15, // Valeur par défaut
    );
    
    return plan;
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
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1553FF),
                  Color(0xFF0D47A1),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1553FF).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
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

  /// 🧠 Crée un plan local avec génération intelligente de passages
  Future<Plan> _createLocalPlanWithPassages() async {
    // 1) Générer les passages intelligents avec frontières sémantiques
    final passages = _generateOfflinePassages(
      booksKey: _books,
      totalDays: _totalDays,
      startDate: DateTime.now(),
      daysOfWeek: _daysOfWeek,
    );

    // 2) Créer le plan avec les passages générés
    final plan = await bootstrap.planService.createLocalPlan(
      name: _nameController.text.trim(),
      totalDays: _totalDays,
      books: _books,
      startDate: DateTime.now(),
      minutesPerDay: 15, // Valeur par défaut
      daysOfWeek: _daysOfWeek,
      customPassages: passages,
    );

    return plan;
  }

  /// 🚀 Génération INTELLIGENTE des passages (avec frontières sémantiques)
  List<Map<String, dynamic>> _generateOfflinePassages({
    required String booksKey,
    required int totalDays,
    required DateTime startDate,
    required List<int> daysOfWeek, // 1..7
  }) {
    // 1) Récupérer un pool de livres/chapitres selon booksKey
    final chapters = _expandBooksPoolToChapters(booksKey);
    int cursor = 0;

    final result = <Map<String, dynamic>>[];
    DateTime cur = startDate;

    int produced = 0;
    while (produced < totalDays && cursor < chapters.length) {
      // Respect réel du calendrier : sauter les jours non cochés
      final dow = cur.weekday; // 1=Mon..7=Sun
      if (!daysOfWeek.contains(dow)) {
        cur = cur.add(const Duration(days: 1));
        continue; // Passer au jour suivant
      }

      // 🧠 Prend 1 "unité sémantique" par jour (chapitre ou groupe cohérent)
      final unit = _pickSemanticUnit(chapters, cursor);
      cursor = unit.nextCursor;

      result.add({
        'reference': unit.reference,
        'text': unit.annotation ?? 'Lecture de ${unit.reference}',
        'book': chapters[cursor - 1 < 0 ? 0 : cursor - 1].book,
        'theme': _themeForBook(chapters[cursor - 1 < 0 ? 0 : cursor - 1].book),
        'focus': _focusForBook(chapters[cursor - 1 < 0 ? 0 : cursor - 1].book),
        'duration': 15, // minutes
        'wasAdjusted': unit.wasAdjusted,
        'annotation': unit.annotation,
        'date': cur.toIso8601String(),
      });

      produced++;
      cur = cur.add(const Duration(days: 1));
    }

    print('📖 ${result.length} passages générés offline (INTELLIGENTS)');
    
    // 🕊️ INTÉGRATION DOCTRINALE - Application du pipeline doctrinal modulaire
    final ctx = DoctrineContext(userProfile: _userProfile, minutesPerDay: 15);
    final pipeline = DoctrinePipeline.defaultModules();
    final withDoctrine = pipeline.apply(result, context: ctx);
    
    print('🕊️ Plan structuré par le pipeline doctrinal modulaire');
    return withDoctrine;
  }

  /// 🧠 Expand books pool vers chapitres (pour génération intelligente)
  List<_ChapterRef> _expandBooksPoolToChapters(String booksSource) {
    if (booksSource.contains(',')) {
      final books = booksSource.split(',').map((b) => b.trim()).toList();
      final allChapters = <_ChapterRef>[];
      for (final book in books) {
        allChapters.addAll(_expandBooksPoolToChapters(book));
      }
      return allChapters;
    }

    // Expansion des catégories
    if (booksSource == 'NT') {
      return _ntChapters();
    } else if (booksSource == 'OT') {
      return _otChapters();
    } else if (booksSource == 'Gospels') {
      return _gospelsChapters();
    } else if (booksSource == 'Psaumes' || booksSource == 'Psalms') {
      return List.generate(150, (i) => _ChapterRef('Psaumes', i + 1));
    } else if (booksSource == 'Proverbes' || booksSource == 'Proverbs') {
      return List.generate(31, (i) => _ChapterRef('Proverbes', i + 1));
    } else if (booksSource == 'Matthieu') {
      return List.generate(28, (i) => _ChapterRef('Matthieu', i + 1));
    } else if (booksSource == 'Marc') {
      return List.generate(16, (i) => _ChapterRef('Marc', i + 1));
    } else if (booksSource == 'Luc') {
      return List.generate(24, (i) => _ChapterRef('Luc', i + 1));
    } else if (booksSource == 'Jean') {
      return List.generate(21, (i) => _ChapterRef('Jean', i + 1));
    } else if (booksSource == 'Romains') {
      return List.generate(16, (i) => _ChapterRef('Romains', i + 1));
    } else if (booksSource == 'Galates') {
      return List.generate(6, (i) => _ChapterRef('Galates', i + 1));
    } else if (booksSource == 'Éphésiens') {
      return List.generate(6, (i) => _ChapterRef('Éphésiens', i + 1));
    } else if (booksSource == 'Philippiens') {
      return List.generate(4, (i) => _ChapterRef('Philippiens', i + 1));
    }

    // Fallback: retourner 1 chapitre
    return [_ChapterRef(booksSource, 1)];
  }

  /// Chapitres des Évangiles
  List<_ChapterRef> _gospelsChapters() => [
    ...List.generate(28, (i) => _ChapterRef('Matthieu', i + 1)),
    ...List.generate(16, (i) => _ChapterRef('Marc', i + 1)),
    ...List.generate(24, (i) => _ChapterRef('Luc', i + 1)),
    ...List.generate(21, (i) => _ChapterRef('Jean', i + 1)),
  ];

  /// Chapitres du Nouveau Testament
  List<_ChapterRef> _ntChapters() => [
    ..._gospelsChapters(),
    ...List.generate(28, (i) => _ChapterRef('Actes', i + 1)),
    ...List.generate(16, (i) => _ChapterRef('Romains', i + 1)),
    ...List.generate(6, (i) => _ChapterRef('Galates', i + 1)),
    ...List.generate(6, (i) => _ChapterRef('Éphésiens', i + 1)),
    ...List.generate(4, (i) => _ChapterRef('Philippiens', i + 1)),
  ];

  /// Chapitres de l'Ancien Testament
  List<_ChapterRef> _otChapters() => [
    ...List.generate(50, (i) => _ChapterRef('Genèse', i + 1)),
    ...List.generate(40, (i) => _ChapterRef('Exode', i + 1)),
    ...List.generate(150, (i) => _ChapterRef('Psaumes', i + 1)),
    ...List.generate(31, (i) => _ChapterRef('Proverbes', i + 1)),
    ...List.generate(66, (i) => _ChapterRef('Ésaïe', i + 1)),
  ];

  /// 🚀 FALCON X - Sélection ultra-intelligente d'unités sémantiques
  _SemanticPick _pickSemanticUnit(List<_ChapterRef> chapters, int cursor) {
    if (cursor >= chapters.length) {
      return _SemanticPick('Psaume 1', cursor + 1);
    }

    final c = chapters[cursor];
    
    // 🚀 ÉTAPE 1: Chercher une unité sémantique CRITICAL ou HIGH qui commence ici
    final unit = SemanticPassageBoundaryService.findUnitContaining(c.book, c.chapter);
    
    if (unit != null && 
        unit.startChapter == c.chapter &&
        (unit.priority == UnitPriority.critical || unit.priority == UnitPriority.high)) {
      
      // Vérifier qu'on a assez de chapitres restants pour l'unité complète
      final chaptersNeeded = unit.length;
      final chaptersAvailable = chapters.length - cursor;
      
      if (chaptersAvailable >= chaptersNeeded) {
        // Vérifier que tous les chapitres suivants font partie de cette unité
        bool allMatch = true;
        for (int i = 1; i < chaptersNeeded; i++) {
          if (cursor + i >= chapters.length) {
            allMatch = false;
            break;
          }
          final nextChap = chapters[cursor + i];
          if (nextChap.book != c.book || nextChap.chapter != c.chapter + i) {
            allMatch = false;
            break;
          }
        }
        
        if (allMatch) {
          // ✅ Utiliser l'unité sémantique complète
          return _SemanticPick(
            unit.reference,
            (cursor + chaptersNeeded).toInt(),
            wasAdjusted: true,
            annotation: unit.annotation ?? unit.name,
          );
        }
      }
    }
    
    // 🎨 ÉTAPE 2: Pas d'unité critique, mais peut-être une annotation utile
    if (unit != null && unit.priority == UnitPriority.medium) {
      // Donner l'annotation mais ne pas forcer le groupement
      return _SemanticPick(
        '${c.book} ${c.chapter}',
        cursor + 1,
        wasAdjusted: false,
        annotation: unit.annotation,
      );
    }

    // 📖 ÉTAPE 3: Défaut - 1 chapitre avec annotation si disponible
    final annotation = SemanticPassageBoundaryService.getAnnotationForChapter(c.book, c.chapter);
    return _SemanticPick(
      '${c.book} ${c.chapter}',
      cursor + 1,
      wasAdjusted: false,
      annotation: annotation,
    );
  }

  String _themeForBook(String book) {
    // Logique simple de thème par livre
    if (book.contains('Psaumes')) return 'Louange et adoration';
    if (book.contains('Proverbes')) return 'Sagesse pratique';
    if (book.contains('Matthieu') || book.contains('Marc') || book.contains('Luc') || book.contains('Jean')) return 'Vie de Jésus';
    if (book.contains('Romains') || book.contains('Galates') || book.contains('Éphésiens')) return 'Doctrine chrétienne';
    return 'Méditation biblique';
  }

  String _focusForBook(String book) {
    // Logique simple de focus par livre
    if (book.contains('Psaumes')) return 'Cœur et émotions';
    if (book.contains('Proverbes')) return 'Sagesse quotidienne';
    if (book.contains('Matthieu') || book.contains('Marc') || book.contains('Luc') || book.contains('Jean')) return 'Suivre Jésus';
    if (book.contains('Romains') || book.contains('Galates') || book.contains('Éphésiens')) return 'Comprendre la foi';
    return 'Croissance spirituelle';
  }
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

/// 📖 Classe helper pour référence de chapitre
class _ChapterRef {
  final String book;
  final int chapter;
  
  _ChapterRef(this.book, this.chapter);
}

/// 🧠 Classe helper pour unité sémantique
class _SemanticPick {
  final String reference;
  final int nextCursor;
  final bool wasAdjusted;
  final String? annotation;
  
  _SemanticPick(
    this.reference,
    this.nextCursor, {
    this.wasAdjusted = false,
    this.annotation,
  });
}
