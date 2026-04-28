import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/utils/secure_storage.dart';
import '../../../core/widgets/app_button.dart';
import '../data/auth_repository.dart';
import '../domain/auth_state.dart';
import '../domain/trial_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'E-posta ve şifre gereklidir');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ref.read(authRepositoryProvider).login(email: email, password: pass);
      _onAuthSuccess(data);
    } catch (e) {
      setState(() => _error = parseApiError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _devLogin() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    await AppStorage.instance.write(key: 'auth_token', value: 'dev-token');
    ref.read(authProvider.notifier).setUser(
          id: 'dev-user-id',
          email: 'dev@leafpal.com',
          name: 'Geliştirici',
        );
    ref.read(trialProvider.notifier).updateFromLogin({
      'isTrialAccepted': true,
      'isPremium': false,
      'trialDaysLeft': 3,
      'trialExpired': false,
      'scansRemainingToday': 2,
      'canScan': true,
    });
    if (mounted) context.go('/home');
  }

  void _onAuthSuccess(Map<String, dynamic> data) {
    final user = data['user'] as Map<String, dynamic>;
    final trialJson = data['trial'] as Map<String, dynamic>?;
    ref.read(authProvider.notifier).setUser(
          id: user['id'] as String,
          email: user['email'] as String,
          name: user['name'] as String?,
        );
    if (trialJson != null) {
      ref.read(trialProvider.notifier).updateFromLogin(trialJson);
      final trial = TrialStatus.fromJson(trialJson);
      if (!trial.isTrialAccepted && mounted) {
        context.go('/onboarding/paywall');
        return;
      }
    }
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      // Use the background image itself as base — no black layer possible
      backgroundColor: const Color(0xFF061b0e),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Full-screen background image — fills entire screen, no gaps
          Positioned.fill(
            child: Image.asset(
              'assets/images/devetabani.webp',
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.3),
              filterQuality: FilterQuality.high,
            ),
          ),
          // Full gradient overlay from top to match bottom panel
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.30, 0.52, 0.58],
                  colors: [
                    Colors.black.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.05),
                    AppColors.primary.withValues(alpha: 0.85),
                    AppColors.primary,
                  ],
                ),
              ),
            ),
          ),
          // Hero text at top
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 46, 28, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: const Icon(Icons.eco_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'LeafPal',
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 310),
                    child: Text(
                      'Bitkilerinize\nuzman dokunuşu.',
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        height: 1.03,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom form panel — fixed, no scroll, fits on screen
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 18, 24, bottomPad + 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Giriş Yap',
                        style: GoogleFonts.manrope(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, size: 14, color: Theme.of(context).colorScheme.error),
                              const SizedBox(width: 6),
                              Expanded(child: Text(_error!, style: GoogleFonts.manrope(fontSize: 12, color: Theme.of(context).colorScheme.error))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'E-posta',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _login(),
                        decoration: InputDecoration(
                          labelText: 'Şifre',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          isDense: true,
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      AppButton.primary(label: 'Giriş Yap', isLoading: _isLoading, onPressed: _login),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: Divider(color: Theme.of(context).colorScheme.outlineVariant)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text('veya', style: GoogleFonts.manrope(fontSize: 12, color: Theme.of(context).colorScheme.outline)),
                          ),
                          Expanded(child: Divider(color: Theme.of(context).colorScheme.outlineVariant)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Google girişi yakında!', style: GoogleFonts.manrope()),
                            behavior: SnackBarBehavior.floating,
                          ),
                        ),
                        icon: const Icon(Icons.g_mobiledata, size: 22),
                        label: Text('Google ile Giriş Yap', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 14)),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 46),
                          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                          shape: const StadiumBorder(),
                          foregroundColor: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (kDebugMode) ...[
                        const SizedBox(height: 6),
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _devLogin,
                          icon: const Icon(Icons.developer_mode, size: 16),
                          label: Text('Dev Giriş', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 40),
                            side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4)),
                            shape: const StadiumBorder(),
                            foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Center(
                        child: GestureDetector(
                          onTap: () => context.push('/register'),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: 'Hesabınız yok mu? ', style: GoogleFonts.manrope(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                TextSpan(text: 'Kayıt olun', style: GoogleFonts.manrope(fontSize: 13, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900)),
                              ],
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
        ],
      ),
    );
  }
}
