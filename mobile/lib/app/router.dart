import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/onboarding_paywall_screen.dart';
import '../features/auth/presentation/onboarding_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/diagnosis/presentation/diagnosis_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/my_plants/presentation/manual_plant_screen.dart';
import '../features/my_plants/presentation/my_plants_screen.dart';
import '../features/my_plants/presentation/plant_detail_screen.dart';
import '../features/plant_scan/domain/plant_match.dart';
import '../features/plant_scan/presentation/scan_result_screen.dart';
import '../features/plant_scan/presentation/scan_screen.dart';
import '../features/premium/presentation/premium_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/reminders/presentation/reminder_setup_screen.dart';
import '../features/reminders/presentation/reminders_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    // ── Auth & Onboarding ──────────────────────────────────────
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/onboarding/paywall', builder: (_, __) => const OnboardingPaywallScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

    // ── Full-screen flows (outside shell) ─────────────────────
    GoRoute(
      path: '/scan',
      builder: (_, __) => const ScanScreen(),
    ),
    GoRoute(
      path: '/scan/result',
      builder: (ctx, state) {
        final extra = state.extra as ({List<PlantMatch> matches, XFile? scannedImage})?;
        return ScanResultScreen(
          matches: extra?.matches ?? [],
          scannedImage: extra?.scannedImage,
        );
      },
    ),
    GoRoute(path: '/plants/new', builder: (_, __) => const ManualPlantScreen()),
    GoRoute(
      path: '/plants/:id',
      builder: (ctx, state) => PlantDetailScreen(plantId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/reminder/setup',
      builder: (_, state) {
        final extra = state.extra as ({String plantId, String plantName})?;
        return ReminderSetupScreen(
          plantId: extra?.plantId,
          plantName: extra?.plantName,
        );
      },
    ),
    GoRoute(path: '/premium', builder: (_, __) => const PremiumScreen()),
    GoRoute(path: '/diagnosis', builder: (_, __) => const DiagnosisScreen()),

    // ── Shell (bottom nav) ─────────────────────────────────────
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (ctx, state, child) => _AppShell(
        location: state.uri.toString(),
        child: child,
      ),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/plants', builder: (_, __) => const MyPlantsScreen()),
        GoRoute(path: '/calendar', builder: (_, __) => const RemindersScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      ],
    ),
  ],
);

// ── Shell scaffold with LeafPal nav bar ───────────────────────

class _AppShell extends StatelessWidget {
  final Widget child;
  final String location;
  const _AppShell({required this.child, required this.location});

  int get _currentIndex {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/plants')) return 1;
    if (location.startsWith('/calendar')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _LeafPalNavBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          switch (i) {
            case 0: context.go('/home');
            case 1: context.go('/plants');
            case 2: context.go('/calendar');
            case 3: context.go('/profile');
          }
        },
        onScanTap: () => context.push('/scan'),
      ),
    );
  }
}

class _LeafPalNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onScanTap;

  const _LeafPalNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.onScanTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Anasayfa', isActive: currentIndex == 0, onTap: () => onTap(0), cs: cs),
              _NavItem(icon: Icons.eco_outlined, activeIcon: Icons.eco, label: 'Bitkiler', isActive: currentIndex == 1, onTap: () => onTap(1), cs: cs),
              _ScanButton(onTap: onScanTap, cs: cs),
              _NavItem(icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month, label: 'Takvim', isActive: currentIndex == 2, onTap: () => onTap(2), cs: cs),
              _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profil', isActive: currentIndex == 3, onTap: () => onTap(3), cs: cs),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? cs.primary : cs.outline,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isActive ? cs.primary : cs.outline,
                letterSpacing: 0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  final VoidCallback onTap;
  final ColorScheme cs;
  const _ScanButton({required this.onTap, required this.cs});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 2),
          Text(
            'Tara',
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: cs.primary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
