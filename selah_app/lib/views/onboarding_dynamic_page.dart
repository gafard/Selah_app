import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/user_prefs_service.dart';
import '../services/plan_service.dart';
import '../services/onboarding_actions.dart';
import '../services/user_prefs_hive.dart';
import '../services/sync_queue_hive.dart';
import '../services/telemetry_console.dart';
import '../features/onboarding/onboarding_vm.dart';

class OnboardingDynamicPage extends StatelessWidget {
  const OnboardingDynamicPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingVM(
        prefs: UserPrefsLocal(),
        plans: Provider.of<PlanService>(context, listen: false),
      )..load(),
      child: const _OnboardingView(),
    );
  }
}

class _OnboardingView extends StatefulWidget {
  const _OnboardingView();

  @override
  State<_OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<_OnboardingView> {
  final _page = PageController();
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OnboardingVM>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0B1025), Color(0xFF1C1740), Color(0xFF2D1B69)],
            stops: [0, .55, 1],
          ),
        ),
        child: SafeArea(
          child: vm.loading
              ? _Loader(onRetry: () => context.read<OnboardingVM>().load())
              : vm.error != null
                  ? _ErrorState(
                      message: 'Impossible de charger les infos.',
                      onRetry: () => context.read<OnboardingVM>().load(),
                    )
                  : Column(
                      children: [
                        _MeditationBanner(), // bandeau "appli de méditation"
                        Expanded(
                          child: PageView.builder(
                            controller: _page,
                            itemCount: vm.cards.length,
                            onPageChanged: (i) => setState(() => _index = i),
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (_, i) => _SlideCard(card: vm.cards[i], index: i),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _Dots(count: vm.cards.length, index: _index),
                        const SizedBox(height: 16),
                        _BottomCTA(
                          isLast: _index == vm.cards.length - 1,
                          onNext: () {
                            if (_index == vm.cards.length - 1) {
                              _finishOnboarding();
                            } else {
                              _page.nextPage(
                                duration: const Duration(milliseconds: 360),
                                curve: Curves.easeOutCubic,
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
        ),
      ),
    );
  }

  Future<void> _finishOnboarding() async {
    try {
      final prefs = context.read<UserPrefsHive>();
      final queue = context.read<SyncQueueHive>();
      final telemetry = context.read<TelemetryConsole>();

      // local d'abord (optimiste)
      await prefs.setHasOnboarded(true);
      telemetry.event('onboarding_completed');

      // enqueue patch serveur (idempotent)
      await queue.enqueueUserPatch({'hasOnboarded': true});

      // Actions legacy (alarmes, etc.)
      await OnboardingActions.complete(context);

      if (mounted) Navigator.pushReplacementNamed(context, '/congrats'); // puis Home après l'écran de succès
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: const Color(0xFFEF4444)),
      );
    }
  }
}

// ——— Widgets —————————————————————————————————————————

class _MeditationBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 10, 18, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(.14)),
      ),
      child: Row(
        children: [
          const Icon(Icons.self_improvement, color: Colors.white70, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Selah est une app de méditation de la Bible (pas de lecture). '
              'Garde ta Bible physique à portée de main pour chaque séance.',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideCard extends StatelessWidget {
  const _SlideCard({required this.card, required this.index});
  final OnboardingCard card;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
      child: Stack(
        children: [
          // accent doux (Calm)
          Positioned.fill(child: _AccentBlob(index: card.indexAccent)),
          Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.22),
                    blurRadius: 26,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // hero
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: AspectRatio(
                      aspectRatio: 1.4,
                      child: Image.network(card.imageUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: const Color(0xFFEFF1F5)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(card.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                  const SizedBox(height: 6),
                  Text(card.subtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF2563EB))),
                  const SizedBox(height: 10),
                  Text(card.content,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14, height: 1.55, color: const Color(0xFF475569))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccentBlob extends StatelessWidget {
  const _AccentBlob({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF7C3AED).withOpacity(.28),
      const Color(0xFF22D3EE).withOpacity(.28),
      const Color(0xFF49C98D).withOpacity(.28),
    ];
    return IgnorePointer(
      child: Container(
        margin: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: RadialGradient(
            colors: [colors[index % colors.length], Colors.transparent],
            radius: 0.85, center: Alignment.topRight,
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 28 : 8, height: 8,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white30,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _BottomCTA extends StatelessWidget {
  const _BottomCTA({required this.isLast, required this.onNext});
  final bool isLast;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1553FF), Color(0xFF49C98D)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ElevatedButton(
        onPressed: onNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          foregroundColor: Colors.white,
        ),
        child: Text(isLast ? 'Commencer' : 'Continuer',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _Loader extends StatelessWidget {
  const _Loader({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white)),
        const SizedBox(height: 16),
        Text('Chargement…', style: GoogleFonts.inter(color: Colors.white70)),
        const SizedBox(height: 8),
        TextButton(onPressed: onRetry, child: const Text('Réessayer', style: TextStyle(color: Colors.white))),
      ]),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(message, style: GoogleFonts.inter(color: Colors.white70)),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: onRetry, child: const Text('Réessayer', style: TextStyle(color: Colors.white))),
      ]),
    );
  }
}