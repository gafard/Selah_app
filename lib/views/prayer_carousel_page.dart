import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/prayer_subjects_builder.dart';

class PrayerCarouselPage extends StatefulWidget {
  final List<PrayerSubject> subjects;
  final String? passageRef;   // ex: "Jean 4:10–12"
  final String? memoryVerse;  // si tu veux l'afficher

  const PrayerCarouselPage({
    super.key,
    required this.subjects,
    this.passageRef,
    this.memoryVerse,
  });

  @override
  State<PrayerCarouselPage> createState() => _PrayerCarouselPageState();
}

class _PrayerCarouselPageState extends State<PrayerCarouselPage> {
  late final PageController _page;
  int _index = 0;
  late final List<_UIItem> _items;

  static const Map<String, List<Color>> _catGradients = {
    'gratitude':   [Color(0xFFFF6B9D), Color(0xFFC44569)],
    'repentance':  [Color(0xFFFF8A65), Color(0xFFD84315)],
    'obedience':   [Color(0xFF4FC3F7), Color(0xFF0277BD)],
    'promise':     [Color(0xFFBA68C8), Color(0xFF7B1FA2)],
    'intercession':[Color(0xFF66BB6A), Color(0xFF2E7D32)],
    'praise':      [Color(0xFFFFB74D), Color(0xFFE65100)],
    'trust':       [Color(0xFF4DB6AC), Color(0xFF00695C)],
    'guidance':    [Color(0xFF26C6DA), Color(0xFF00838F)],
    'warning':     [Color(0xFFEF5350), Color(0xFFC62828)],
    'other':       [Color(0xFF90A4AE), Color(0xFF455A64)],
  };

  @override
  void initState() {
    super.initState();
    _page = PageController(viewportFraction: .88);
    _items = widget.subjects.map((s) => _UIItem(s)).toList();
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  int get _done => _items.where((e) => e.done).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1B3A),
              Color(0xFF2D1B69),
              Color(0xFF1C1740),
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topBar(),
              if (widget.passageRef != null) _passageChip(widget.passageRef!),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Sélectionne tes sujets de prière\npuis glisse pour passer au suivant.',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.7), 
                    fontSize: 14, 
                    height: 1.3,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // CAROUSEL
              Expanded(
                child: PageView.builder(
                  controller: _page,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemCount: _items.length,
                  itemBuilder: (_, i) => _card(_items[i], i),
                ),
              ),

              // dots
              const SizedBox(height: 6),
              _dots(),
              const SizedBox(height: 20),

              // lecteur + terminer
              _bottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Text(
            'Sujets de prière', 
            style: GoogleFonts.inter(
              color: Colors.white, 
              fontSize: 28, 
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              '$_done/${_items.length}', 
              style: GoogleFonts.inter(
                color: Colors.white, 
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passageChip(String ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.15),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.menu_book_outlined, color: Colors.white70, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                ref, 
                style: GoogleFonts.inter(
                  color: Colors.white, 
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(_UIItem ui, int i) {
    final g = _catGradients[ui.subject.category] ?? _catGradients['other']!;
    return AnimatedBuilder(
      animation: _page,
      builder: (_, child) {
        double t = 0.0;
        if (_page.position.haveDimensions) {
          t = (_page.page ?? _page.initialPage.toDouble()) - i;
        }
        final scale = (1 - (t.abs() * .06)).clamp(.92, 1.0);
        final translate = (t * 14);
        return Transform.translate(
          offset: Offset(0, translate),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => ui.done = !ui.done);
        },
        onLongPress: () async {
          final c = TextEditingController(text: ui.subject.label);
          final res = await showDialog<String>(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: const Color(0xFF1C1740),
              title: Text(
                'Modifier le sujet',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              content: TextField(
                controller: c, 
                maxLines: 3,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Nouveau sujet de prière...',
                  hintStyle: GoogleFonts.inter(color: Colors.white.withOpacity(0.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6366F1)),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: Text(
                    'Annuler',
                    style: GoogleFonts.inter(color: Colors.white.withOpacity(0.7)),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, c.text.trim()), 
                  child: Text(
                    'Enregistrer',
                    style: GoogleFonts.inter(color: const Color(0xFF6366F1), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
          if (res != null && res.isNotEmpty) setState(() => ui.subject = PrayerSubject(res, ui.subject.category));
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          decoration: BoxDecoration(
            gradient: ui.done 
                ? LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ],
                  )
                : LinearGradient(
                    colors: g, 
                    begin: Alignment.topLeft, 
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: ui.done 
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: g.last.withOpacity(0.4), 
                      blurRadius: 24, 
                      offset: const Offset(0, 12),
                    ),
                  ],
            border: ui.done 
                ? Border.all(color: Colors.white.withOpacity(0.2), width: 1.5) 
                : null,
          ),
          child: Row(
            children: [
              // pastille
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: ui.done ? Colors.white.withOpacity(0.6) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: ui.done 
                      ? null 
                      : [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                  child: Text(
                    ui.subject.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: ui.done ? Colors.white.withOpacity(0.6) : Colors.white,
                    decoration: ui.done ? TextDecoration.lineThrough : TextDecoration.none,
                    decorationThickness: 2,
                    decorationColor: Colors.white.withOpacity(0.6),
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                ui.done ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: ui.done ? Colors.white.withOpacity(0.6) : Colors.white.withOpacity(0.8),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_items.length, (i) {
        final on = i == _index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: on ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: on ? Colors.white : Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
            boxShadow: on 
                ? [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  Widget _bottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Row(
        children: [
          // mini lecteur (cosmétique, prêt pour brancher un player)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.music_note_rounded, color: Colors.white70, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Instrumental calme',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white, 
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  _PlayBtn(),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                final completed = _items.where((e) => e.done).map((e) => e.subject.label).toList();
                Navigator.pop(context, {
                  'completed': completed,
                  'all': _items.map((e) => e.subject.label).toList(),
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'Terminer', 
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UIItem {
  PrayerSubject subject;
  bool done = false;
  _UIItem(this.subject);
}

class _PlayBtn extends StatefulWidget {
  @override
  State<_PlayBtn> createState() => _PlayBtnState();
}

class _PlayBtnState extends State<_PlayBtn> {
  bool play = false;
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => play = !play),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2), 
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          play ? Icons.pause_rounded : Icons.play_arrow_rounded, 
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }
}
