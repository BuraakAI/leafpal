import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/first_launch.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPage(
      image: 'assets/images/devetabani.webp',
      eyebrow: 'HAFTALIK SULAMA',
      title: 'Bitkilerini tanı,\nbakım planı oluştur',
      subtitle: 'Fotoğraf çek, saniyeler içinde bitkini tanı.\nKişisel bakım planın otomatik hazırlansın.',
      plantName: 'Monstera deliciosa',
      plantSubtitle: 'Deve Tabanı',
      chipIcon: Icons.water_drop_rounded,
      accentColor: Color(0xFF143522),
    ),
    _OnboardingPage(
      image: 'assets/images/kemanyaprakliincir.webp',
      eyebrow: 'AKILLI BAKIM',
      title: 'Her bitkiye özel\npremium bakım',
      subtitle: 'Işık, nem ve sulama ritmini tek yerde takip et.\nBitkilerin daha güçlü büyüsün.',
      plantName: 'Ficus lyrata',
      plantSubtitle: 'Keman Yapraklı İncir',
      chipIcon: Icons.auto_awesome_rounded,
      accentColor: Color(0xFF1F3A2B),
    ),
    _OnboardingPage(
      image: 'assets/images/kiraz.jpg',
      eyebrow: 'SULAMA VAKTİ',
      title: 'Hiç sulama\nkaçırma',
      subtitle: 'Akıllı hatırlatıcılar doğru zamanda haber verir.\nSen sadece bitkilerinin keyfini çıkar.',
      plantName: 'Prunus serrulata',
      plantSubtitle: 'Japon Kiraz Çiçeği',
      chipIcon: Icons.notifications_active_rounded,
      accentColor: Color(0xFF583949),
    ),
  ];

  Future<void> _finish() async {
    await FirstLaunchService.setOnboardingDone();
    if (mounted) context.go('/login');
  }

  void _next() {
    if (_currentPage == _pages.length - 1) {
      _finish();
      return;
    }
    _pageCtrl.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageCtrl,
            itemCount: _pages.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (_, index) => _OnboardingSlide(page: _pages[index]),
          ),
          Positioned(
            top: topPad + 12,
            right: 18,
            child: TextButton(
              onPressed: _finish,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.black.withValues(alpha: 0.32),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: const StadiumBorder(),
              ),
              child: Text('Geç', style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 14)),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: bottomPad + 28,
            child: Row(
              children: [
                Row(
                  children: List.generate(_pages.length, (index) {
                    final active = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      margin: const EdgeInsets.only(right: 7),
                      width: active ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active ? Colors.white : Colors.white.withValues(alpha: 0.34),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    );
                  }),
                ),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _currentPage == _pages.length - 1 ? 148 : 62,
                  height: 62,
                  child: ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size.zero,
                      backgroundColor: Colors.white,
                      foregroundColor: _pages[_currentPage].accentColor,
                      elevation: 10,
                      shadowColor: Colors.black.withValues(alpha: 0.3),
                      shape: const StadiumBorder(),
                      padding: EdgeInsets.zero,
                    ),
                    child: _currentPage == _pages.length - 1
                        ? Text('Başlayalım', style: GoogleFonts.manrope(fontWeight: FontWeight.w900, fontSize: 16))
                        : const Icon(Icons.arrow_forward_rounded, size: 28),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  final _OnboardingPage page;
  const _OnboardingSlide({required this.page});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Hero image — full screen, high quality
        Image.asset(
          page.image,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
        // Gradient overlay — optimized for photo clarity at top, readability at bottom
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.35, 0.62, 1.0],
              colors: [
                Colors.black.withValues(alpha: 0.15),
                Colors.transparent,
                page.accentColor.withValues(alpha: 0.82),
                page.accentColor.withValues(alpha: 0.98),
              ],
            ),
          ),
        ),
        // Top chip badge
        Positioned(
          left: 24,
          right: 24,
          top: topPad + 64,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(page.chipIcon, size: 15, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      page.eyebrow,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Bottom text content
        Positioned(
          left: 24,
          right: 24,
          bottom: 122 + MediaQuery.of(context).padding.bottom,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plant name label
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: page.plantName,
                      style: const TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: '  ·  ${page.plantSubtitle}'),
                  ],
                ),
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.88),
                  shadows: [
                    Shadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 6),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Main title — premium Playfair Display font
              Text(
                page.title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.05,
                  shadows: [
                    Shadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Subtitle — clear, readable
              Text(
                page.subtitle,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.90),
                  height: 1.55,
                  letterSpacing: 0.1,
                  shadows: [
                    Shadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OnboardingPage {
  final String image;
  final String eyebrow;
  final String title;
  final String subtitle;
  final String plantName;
  final String plantSubtitle;
  final IconData chipIcon;
  final Color accentColor;

  const _OnboardingPage({
    required this.image,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.plantName,
    required this.plantSubtitle,
    required this.chipIcon,
    required this.accentColor,
  });
}
