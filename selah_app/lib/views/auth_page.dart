import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../widgets/selah_logo.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _pass2C = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Vérifier les arguments passés lors de la navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['mode'] == 'signup') {
        setState(() {
          _isLogin = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    _passC.dispose();
    _pass2C.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await AuthService.instance.signInWithEmail(
          _emailC.text.trim(),
          _passC.text.trim(),
        );
      } else {
        await AuthService.instance.signUpWithEmail(
          name: _nameC.text.trim(),
          email: _emailC.text.trim(),
          password: _passC.text.trim(),
        );
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/complete_profile');
    } catch (e) {
      _toast('Erreur: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: GoogleFonts.inter(color: Colors.white))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Dégradé Selah
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF1A1D29), Color(0xFF112244)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Ornement léger
              Positioned(
                right: -60,
                top: -40,
                child: _softBlob(180),
              ),
              Positioned(
                left: -40,
                bottom: -50,
                child: _softBlob(220),
              ),

              // Contenu centré
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 480),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                            const SizedBox(height: 8),
                            // Logo + titre
                            _header(),
                            const SizedBox(height: 20),

                            // Toggle
                            _toggle(),

                            const SizedBox(height: 16),

                            // Formulaire animé
                            Form(
                              key: _formKey,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                switchInCurve: Curves.easeOut,
                                switchOutCurve: Curves.easeIn,
                                transitionBuilder: (child, anim) => FadeTransition(
                                  opacity: anim,
                                  child: SizeTransition(sizeFactor: anim, child: child),
                                ),
                                child: _isLogin ? _loginForm() : _signupForm(),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Bouton principal
                            SizedBox(
                              width: double.infinity,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF1553FF),
                                      Color(0xFF0D47A1),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF1553FF).withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20, width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Text(
                                          _isLogin ? 'Se connecter' : 'Créer un compte',
                                          style: GoogleFonts.inter(
                                            fontSize: 16, fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),


                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      children: [
        // Icône
        Container(
          width: 84, height: 84,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: const Center(child: SelahAppIcon(size: 46)),
        ),
        const SizedBox(height: 14),
        Text(
          'SELAH',
          style: GoogleFonts.outfit(
            fontSize: 30, fontWeight: FontWeight.w800,
            color: Colors.white, letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _isLogin ? 'Connectez-vous' : 'Créez votre compte',
          style: GoogleFonts.inter(fontSize: 16, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _toggle() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          _tab('Connexion', _isLogin, () => setState(() => _isLogin = true)),
          _tab('Inscription', !_isLogin, () => setState(() => _isLogin = false)),
        ],
      ),
    );
  }

  Widget _tab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: active ? const Color(0xFF1C1740) : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  // ----- FORMS -----

  Widget _loginForm() {
    return Column(
      key: const ValueKey('login'),
      children: [
        _field(
          label: 'Email', hint: 'votre@email.com', icon: Icons.email,
          controller: _emailC, validator: _reqEmail,
        ),
        const SizedBox(height: 14),
        _field(
          label: 'Mot de passe', hint: '••••••••', icon: Icons.lock,
          controller: _passC, obscure: true, validator: _reqPass,
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _showForgotPasswordSheet,
            child: Text(
              'Mot de passe oublié ?',
              style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _signupForm() {
    return Column(
      key: const ValueKey('signup'),
      children: [
        _field(
          label: 'Nom complet', hint: 'Votre nom', icon: Icons.person,
          controller: _nameC, validator: _req,
        ),
        const SizedBox(height: 14),
        _field(
          label: 'Email', hint: 'votre@email.com', icon: Icons.email,
          controller: _emailC, validator: _reqEmail,
        ),
        const SizedBox(height: 14),
        _field(
          label: 'Mot de passe', hint: '••••••••', icon: Icons.lock,
          controller: _passC, obscure: true, validator: _reqPass,
        ),
        const SizedBox(height: 14),
        _field(
          label: 'Confirmer le mot de passe', hint: '••••••••', icon: Icons.lock_outline,
          controller: _pass2C, obscure: true, validator: (v) {
            if ((v ?? '').isEmpty) return 'Veuillez confirmer votre mot de passe';
            if (v != _passC.text) return 'Les mots de passe ne correspondent pas';
            return null;
          },
        ),
      ],
    );
  }

  // ----- WIDGETS UTILES -----

  Widget _field({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    String? Function(String?)? validator,
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.20), width: 1),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscure,
            validator: validator,
            style: GoogleFonts.inter(color: Colors.white),
            keyboardType: icon == Icons.email ? TextInputType.emailAddress : TextInputType.text,
            textInputAction: TextInputAction.next,
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
        ),
      ],
    );
  }


  Widget _softBlob(double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Colors.white.withOpacity(0.20), Colors.transparent],
        ),
      ),
    );
  }

  void _showForgotPasswordSheet() {
    final emailC = TextEditingController(text: _emailC.text.trim());
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      border: Border(
                        top: BorderSide(color: Colors.white.withOpacity(0.15)),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36, height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Réinitialiser le mot de passe',
                            style: GoogleFonts.inter(
                              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Entrez votre email pour recevoir un lien de réinitialisation.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: Colors.white70, fontSize: 14, height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Champ email
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.20)),
                            ),
                            child: TextFormField(
                              controller: emailC,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              enableInteractiveSelection: true,
                              autocorrect: false,
                              validator: _reqEmail,
                              style: GoogleFonts.inter(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'votre@email.com',
                                hintStyle: GoogleFonts.inter(color: Colors.white54),
                                prefixIcon: const Icon(Icons.email, color: Colors.white70),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Boutons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: isLoading ? null : () => Navigator.pop(ctx),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.white.withOpacity(0.6)),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text('Annuler', style: GoogleFonts.inter()),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF1553FF),
                                        Color(0xFF0D47A1),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF1553FF).withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: isLoading
                                        ? null
                                        : () async {
                                            if (!formKey.currentState!.validate()) return;
                                            setModalState(() => isLoading = true);
                                            try {
                                              await AuthService.instance.resetPassword(emailC.text.trim());
                                              if (!mounted) return;
                                              Navigator.pop(ctx);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Un lien de réinitialisation a été envoyé.',
                                                    style: GoogleFonts.inter(color: Colors.white),
                                                  ),
                                                ),
                                              );
                                            } catch (e) {
                                              setModalState(() => isLoading = false);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Erreur: $e',
                                                    style: GoogleFonts.inter(color: Colors.white)),
                                                ),
                                              );
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: isLoading
                                        ? const SizedBox(
                                            height: 20, width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Text('Envoyer le lien', 
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            )),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ----- VALIDATEURS -----

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null;

  String? _reqEmail(String? v) {
    if ((v ?? '').isEmpty) return 'Veuillez saisir votre email';
    if (!v!.contains('@')) return 'Email invalide';
    return null;
    // Option: utiliser un regex plus strict si tu veux
  }

  String? _reqPass(String? v) {
    if ((v ?? '').isEmpty) return 'Veuillez saisir votre mot de passe';
    if (v!.length < 6) return 'Au moins 6 caractères';
    return null;
  }
}