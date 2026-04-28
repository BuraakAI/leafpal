import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/theme/app_colors.dart';
import '../../auth/domain/trial_state.dart';
import 'scan_provider.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  XFile? _selectedImage;
  final _picker = ImagePicker();
  final _transformCtrl = TransformationController();

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 92, maxWidth: 2400);
    if (picked == null) return;
    _transformCtrl.value = Matrix4.identity();
    setState(() => _selectedImage = picked);
  }

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanProvider);
    final isLoading = scanState is ScanLoading;
    final trial = ref.watch(trialProvider);
    final cs = Theme.of(context).colorScheme;

    ref.listen(scanProvider, (_, next) {
      if (next is ScanSuccess) {
        context.push('/scan/result', extra: (matches: next.matches, scannedImage: _selectedImage));
        ref.read(scanProvider.notifier).reset();
      } else if (next is ScanError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: cs.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: cs.onSurface),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          'Bitkiyi Tara',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        actions: [
          if (_selectedImage != null)
            IconButton(
              icon: Icon(Icons.restart_alt_rounded, color: cs.onSurfaceVariant),
              tooltip: 'Sıfırla',
              onPressed: () {
                _transformCtrl.value = Matrix4.identity();
                setState(() => _selectedImage = null);
              },
            ),
        ],
      ),
      body: !trial.canScan && !trial.isPremium
          ? _ScanBlocker(trial: trial, cs: cs)
          : isLoading
              ? _ScanAnalyzing(cs: cs)
              : _selectedImage == null
                  ? _EmptyState(
                      onCamera: () => _pickImage(ImageSource.camera),
                      onGallery: () => _pickImage(ImageSource.gallery),
                      cs: cs,
                    )
                  : _ImagePreview(
                      image: _selectedImage!,
                      isLoading: false,
                      transformCtrl: _transformCtrl,
                      cs: cs,
                      onGallery: () => _pickImage(ImageSource.gallery),
                      onCamera: () => _pickImage(ImageSource.camera),
                      onScan: () => ref.read(scanProvider.notifier).scanImage(_selectedImage!),
                    ),
    );
  }
}

// ── Empty state — clean & premium ────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final ColorScheme cs;
  const _EmptyState({required this.onCamera, required this.onGallery, required this.cs});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const Spacer(flex: 2),

            // ── Illustration area ───────────────────────────────
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.12),
                  width: 1.5,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Büyük arka plan ikon
                  Icon(
                    Icons.eco_rounded,
                    size: 140,
                    color: cs.primary.withValues(alpha: 0.07),
                  ),
                  // Merkez içerik
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_photo_alternate_rounded,
                          size: 40,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Fotoğraf Seç',
                        style: GoogleFonts.manrope(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Net bir yaprak veya gövde fotoğrafı seç.\nArka plan sade olursa sonuç daha iyi olur.',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: cs.onSurfaceVariant,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  // Köşe süslemeleri
                  Positioned(
                    top: 16, left: 16,
                    child: _Corner(color: cs.primary.withValues(alpha: 0.3)),
                  ),
                  Positioned(
                    top: 16, right: 16,
                    child: Transform.flip(
                      flipX: true,
                      child: _Corner(color: cs.primary.withValues(alpha: 0.3)),
                    ),
                  ),
                  Positioned(
                    bottom: 16, left: 16,
                    child: Transform.flip(
                      flipY: true,
                      child: _Corner(color: cs.primary.withValues(alpha: 0.3)),
                    ),
                  ),
                  Positioned(
                    bottom: 16, right: 16,
                    child: Transform.flip(
                      flipX: true,
                      flipY: true,
                      child: _Corner(color: cs.primary.withValues(alpha: 0.3)),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 1),

            // ── İpuçları ─────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TipChip(label: 'Tek yaprak', icon: Icons.eco_outlined, cs: cs),
                const SizedBox(width: 8),
                _TipChip(label: 'Net fotoğraf', icon: Icons.center_focus_strong_outlined, cs: cs),
                const SizedBox(width: 8),
                _TipChip(label: 'Sade arka plan', icon: Icons.crop_outlined, cs: cs),
              ],
            ),

            const Spacer(flex: 1),

            // ── Aksiyon butonları ─────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.photo_library_rounded,
                    label: 'Galeriden Seç',
                    sublabel: 'Var olan fotoğraf',
                    color: cs.secondaryContainer,
                    iconColor: cs.onSecondaryContainer,
                    onTap: onGallery,
                    cs: cs,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.photo_camera_rounded,
                    label: 'Kamera',
                    sublabel: 'Şimdi çek',
                    color: cs.primary,
                    iconColor: cs.onPrimary,
                    onTap: onCamera,
                    cs: cs,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  final Color color;
  const _Corner({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(painter: _CornerPainter(color: color)),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  const _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, size.height), const Offset(0, 6), paint);
    canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TipChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final ColorScheme cs;
  const _TipChip({required this.label, required this.icon, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;
  final ColorScheme cs;
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.iconColor,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: iconColor,
              ),
            ),
            Text(
              sublabel,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: iconColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Image preview ─────────────────────────────────────────────────────────────

class _ImagePreview extends StatelessWidget {
  final XFile image;
  final bool isLoading;
  final TransformationController transformCtrl;
  final ColorScheme cs;
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final VoidCallback onScan;
  const _ImagePreview({
    required this.image,
    required this.isLoading,
    required this.transformCtrl,
    required this.cs,
    required this.onGallery,
    required this.onCamera,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              InteractiveViewer(
                transformationController: transformCtrl,
                minScale: 0.8,
                maxScale: 5.0,
                child: FutureBuilder<Uint8List>(
                  future: image.readAsBytes(),
                  builder: (ctx, snap) => snap.hasData
                      ? Image.memory(snap.data!, fit: BoxFit.contain)
                      : const Center(child: CircularProgressIndicator()),
                ),
              ),
              // İpucu pill
              Positioned(
                top: 14,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: cs.inverseSurface.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      'Yakınlaştırmak için iki parmak kullan',
                      style: GoogleFonts.manrope(
                        color: cs.onInverseSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              if (isLoading)
                Container(
                  color: cs.scrim.withValues(alpha: 0.55),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: cs.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Bitki tanımlanıyor...',
                        style: GoogleFonts.manrope(
                          color: cs.onInverseSurface,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        // Alt panel
        Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 34),
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : onGallery,
                      icon: Icon(Icons.photo_library_outlined, size: 16, color: cs.primary),
                      label: Text('Galeri', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: cs.primary)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: cs.primary.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : onCamera,
                      icon: Icon(Icons.photo_camera_outlined, size: 16, color: cs.primary),
                      label: Text('Kamera', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: cs.primary)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: cs.primary.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : onScan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    disabledBackgroundColor: cs.surfaceContainerHigh,
                    foregroundColor: cs.onPrimary,
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
                        )
                      : Text(
                          'Bitkiyi Tanımla',
                          style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w900),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Scan analyzing — tam ekran ara yükleme ekranı ────────────────────────────

class _ScanAnalyzing extends StatefulWidget {
  final ColorScheme cs;
  const _ScanAnalyzing({required this.cs});

  @override
  State<_ScanAnalyzing> createState() => _ScanAnalyzingState();
}

class _ScanAnalyzingState extends State<_ScanAnalyzing>
    with SingleTickerProviderStateMixin {
  static const _steps = [
    (icon: Icons.image_search_rounded,       label: 'Fotoğraf işleniyor…'),
    (icon: Icons.eco_rounded,                label: 'Bitki türü belirleniyor…'),
    (icon: Icons.compare_rounded,            label: 'Özellikler karşılaştırılıyor…'),
    (icon: Icons.local_florist_rounded,      label: 'Bakım bilgileri hazırlanıyor…'),
    (icon: Icons.auto_awesome_rounded,       label: 'Sonuçlar derleniyor…'),
  ];

  int _stepIndex = 0;
  late final Timer _timer;
  late final AnimationController _pulse;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnim = Tween(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );

    _timer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (mounted) {
        setState(() => _stepIndex = (_stepIndex + 1) % _steps.length);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    final step = _steps[_stepIndex];

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pulsing icon
            ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(scale: anim, child: child),
                    ),
                    child: Icon(
                      step.icon,
                      key: ValueKey(step.icon),
                      size: 56,
                      color: cs.primary,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 36),

            // Adım sayacı
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_steps.length, (i) {
                final active = i == _stepIndex;
                final done = i < _stepIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 24 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: done || active
                        ? cs.primary
                        : cs.outlineVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // Mesaj
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: Text(
                step.label,
                key: ValueKey(step.label),
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Bu işlem birkaç saniye sürebilir.',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Progress bar
            SizedBox(
              width: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  backgroundColor: cs.surfaceContainerHigh,
                  color: cs.primary,
                  minHeight: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Scan blocker ──────────────────────────────────────────────────────────────

class _ScanBlocker extends StatelessWidget {
  final TrialStatus trial;
  final ColorScheme cs;
  const _ScanBlocker({required this.trial, required this.cs});

  @override
  Widget build(BuildContext context) {
    final isExpired = trial.trialExpired;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: cs.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.block_outlined, size: 44, color: cs.error),
          ),
          const SizedBox(height: 28),
          Text(
            isExpired ? 'Deneme Süreniz Doldu' : 'Bugünlük Tarama Tamamlandı',
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            isExpired
                ? 'Premium\'a geçerek sınırsız tarama yapabilirsiniz.'
                : 'Yarın tekrar deneyebilir veya Premium\'a geçerek sınırsız tarama yapabilirsiniz.',
            style: GoogleFonts.manrope(fontSize: 15, color: cs.onSurfaceVariant, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () => context.push('/premium'),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: Text("Premium'a Geç", style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go('/home'),
            child: Text('Ana Sayfaya Dön', style: GoogleFonts.manrope(color: cs.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}
