import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/widgets/app_button.dart';
import '../data/auth_repository.dart';
import '../domain/auth_state.dart';
import '../domain/trial_state.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'E-posta ve şifre gereklidir');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Şifre en az 6 karakter olmalıdır');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ref.read(authRepositoryProvider).register(
            email: email,
            password: pass,
            name: _nameCtrl.text.trim(),
          );
      _onRegisterSuccess(data);
    } catch (e) {
      setState(() => _error = parseApiError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onRegisterSuccess(Map<String, dynamic> data) {
    final user = data['user'] as Map<String, dynamic>;
    final trialJson = data['trial'] as Map<String, dynamic>?;
    ref.read(authProvider.notifier).setUser(
          id: user['id'] as String,
          email: user['email'] as String,
          name: user['name'] as String?,
        );
    if (trialJson != null) ref.read(trialProvider.notifier).updateFromLogin(trialJson);
    if (mounted) context.go('/onboarding/paywall');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final screenW = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          // Full-screen filigree background — %40-50 opacity, clearly visible deve tabanı
          Positioned(
            right: -screenW * 0.15,
            top: 40,
            bottom: 0,
            child: Opacity(
              opacity: 0.42,
              child: Image.asset(
                'assets/images/devetabani.webp',
                width: screenW * 0.85,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          // Gradient overlay for readability
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.3, 0.65, 1.0],
                  colors: [
                    cs.surface.withValues(alpha: 0.75),
                    cs.surface.withValues(alpha: 0.85),
                    cs.surface.withValues(alpha: 0.95),
                    cs.surface,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 12, 24, bottomPad + 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLowest.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Premium header
                  Text(
                    'Hesap Oluştur',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bitkilerinize premium bakım rutini kurun',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.errorContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, size: 16, color: cs.error),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_error!, style: GoogleFonts.manrope(fontSize: 13, color: cs.error))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  // Glass fields — premium frosted glass effect
                  _GlassField(
                    child: TextField(
                      controller: _nameCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Ad Soyad', prefixIcon: Icon(Icons.person_outline)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _GlassField(
                    child: TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'E-posta', prefixIcon: Icon(Icons.mail_outline)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _GlassField(
                    child: TextField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _register(),
                      decoration: InputDecoration(
                        labelText: 'Şifre (en az 6 karakter)',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  AppButton.primary(label: 'Kayıt Ol', isLoading: _isLoading, onPressed: _register),
                  const SizedBox(height: 18),
                  // Premium plan info card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryFixed.withValues(alpha: 0.7),
                          AppColors.primaryFixed.withValues(alpha: 0.45),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
                      boxShadow: [
                        BoxShadow(color: cs.primary.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.workspace_premium_rounded, size: 18, color: cs.primary),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'LeafPal Premium',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Kayıttan sonra aylık veya yıllık planını seçip denemeyi başlatabilirsin. İlk kullanım için ödeme bilgisi gereklidir.',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: AppColors.primaryContainer,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _MiniTag(label: '₺99/ay', icon: Icons.calendar_month_outlined),
                            const SizedBox(width: 8),
                            _MiniTag(label: '₺799/yıl', icon: Icons.star_rounded),
                            const SizedBox(width: 8),
                            _MiniTag(label: '3 gün ücretsiz', icon: Icons.timer_outlined),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: GestureDetector(
                      onTap: () => context.pop(),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: 'Zaten hesabınız var mı? ', style: GoogleFonts.manrope(color: cs.onSurfaceVariant)),
                            TextSpan(text: 'Giriş yapın', style: GoogleFonts.manrope(color: cs.primary, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  final IconData icon;
  const _MiniTag({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primaryContainer),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryContainer),
          ),
        ],
      ),
    );
  }
}

class _GlassField extends StatelessWidget {
  final Widget child;
  const _GlassField({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.10 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.08))
            : null,
      ),
      child: child,
    );
  }
}
