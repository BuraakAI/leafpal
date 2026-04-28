import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/di.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/secure_storage.dart';
import '../domain/auth_state.dart';
import '../domain/first_launch.dart';
import '../domain/trial_state.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scaleAnim = Tween(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _ctrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final onboardingDone = await FirstLaunchService.isOnboardingDone();
    if (!mounted) return;
    if (!onboardingDone) {
      context.go('/onboarding');
      return;
    }

    final token = await AppStorage.instance.read(key: 'auth_token');
    if (!mounted) return;
    if (token == null) {
      context.go('/login');
      return;
    }

    // Token var — kullanıcı bilgisi + trial durumunu kontrol et
    try {
      final dio = ref.read(apiClientProvider).dio;
      final res = await dio.get('/api/auth/me');
      if (!mounted) return;

      final data = res.data as Map<String, dynamic>;

      // Kullanıcı state'ini güncelle
      ref.read(authProvider.notifier).setUser(
        id: data['userId'] as String? ?? '',
        email: data['email'] as String? ?? '',
        name: data['name'] as String?,
      );

      // Trial state'ini güncelle
      ref.read(trialProvider.notifier).updateFromLogin(data);

      final isTrialAccepted = data['isTrialAccepted'] as bool? ?? false;
      if (!mounted) return;
      if (!isTrialAccepted) {
        context.go('/onboarding/paywall');
      } else {
        context.go('/home');
      }
    } on DioException {
      // Backend yoksa bile home'a git (offline tolerans)
      if (mounted) context.go('/home');
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Subtle ambient glow
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.primaryFixed.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryContainer.withValues(alpha: 0.08),
                            blurRadius: 40,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryFixed,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.eco,
                            size: 52,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'LeafPal',
                      style: GoogleFonts.manrope(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: -0.02 * 40,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bitkileriniz için uzman dokunuşu.',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
