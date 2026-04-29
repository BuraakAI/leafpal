import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/plant_image.dart';
import '../../auth/domain/trial_state.dart';
import '../../my_plants/presentation/plants_provider.dart';
import '../domain/plant_match.dart';

class ScanResultScreen extends ConsumerStatefulWidget {
  final List<PlantMatch> matches;
  final XFile? scannedImage;
  const ScanResultScreen({super.key, required this.matches, this.scannedImage});

  @override
  ConsumerState<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends ConsumerState<ScanResultScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isSaving = false;

  // Giriş animasyonu
  late final AnimationController _animCtrl;
  final List<Animation<double>> _itemAnims = [];

  @override
  void initState() {
    super.initState();
    final itemCount = widget.matches.length + 2; // matches + detail card + buttons
    _animCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + itemCount * 80),
    );
    for (var i = 0; i < itemCount; i++) {
      final start = (i * 0.08).clamp(0.0, 0.7);
      final end = (start + 0.35).clamp(0.0, 1.0);
      _itemAnims.add(CurvedAnimation(
        parent: _animCtrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ));
    }
    // Küçük gecikme sonra başlat — AppBar geçişi bitsin
    Timer(const Duration(milliseconds: 120), () {
      if (mounted) _animCtrl.forward();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Widget _animated(int index, Widget child) {
    final anim = index < _itemAnims.length ? _itemAnims[index] : _itemAnims.last;
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - anim.value)),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (widget.matches.isEmpty) {
      return Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          backgroundColor: cs.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 64, color: cs.outlineVariant),
              const SizedBox(height: 16),
              Text('Bitki tanımlanamadı',
                  style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w700, color: cs.onSurface)),
              const SizedBox(height: 8),
              Text('Daha net bir fotoğraf deneyin.',
                  style: GoogleFonts.manrope(fontSize: 15, color: cs.onSurfaceVariant)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(backgroundColor: cs.primary, foregroundColor: cs.onPrimary),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    final selected = widget.matches[_selectedIndex];

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text('Tanımlama Sonucu',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: cs.onSurface)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 8),
                _animated(
                  0,
                  Text(
                    '${widget.matches.length} eşleşme bulundu',
                    style: GoogleFonts.manrope(fontSize: 14, color: cs.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 14),

                // Eşleşme kartları
                ...widget.matches.asMap().entries.map((entry) {
                  final i = entry.key;
                  final match = entry.value;
                  final isSelected = i == _selectedIndex;
                  return _animated(
                    i + 1,
                    GestureDetector(
                      onTap: () => setState(() => _selectedIndex = i),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? cs.primary.withValues(alpha: 0.08)
                              : cs.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? cs.primary
                                : cs.outlineVariant.withValues(alpha: 0.3),
                            width: isSelected ? 1.5 : 0.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            PlantImage(
                              imageUrl: match.imageUrl,
                              scientificName: match.scientificName,
                              width: 58,
                              height: 58,
                              borderRadius: 14,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    match.turkishName,
                                    style: GoogleFonts.manrope(
                                        fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface),
                                  ),
                                  Text(
                                    match.scientificName,
                                    style: GoogleFonts.manrope(
                                        fontSize: 13,
                                        color: cs.onSurfaceVariant,
                                        fontStyle: FontStyle.italic),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: match.confidence,
                                            backgroundColor:
                                                cs.outlineVariant.withValues(alpha: 0.3),
                                            valueColor:
                                                AlwaysStoppedAnimation(cs.primary),
                                            minHeight: 5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '%${(match.confidence * 100).toStringAsFixed(0)}',
                                        style: GoogleFonts.manrope(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: cs.primary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Icon(Icons.check_circle, color: cs.primary),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 14),

                // Detay kartı
                _animated(
                  widget.matches.length + 1,
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(selected.turkishName,
                            style: GoogleFonts.manrope(
                                fontSize: 20, fontWeight: FontWeight.w700, color: cs.onSurface)),
                        const SizedBox(height: 3),
                        Text(selected.scientificName,
                            style: GoogleFonts.manrope(
                                fontSize: 14,
                                color: cs.onSurfaceVariant,
                                fontStyle: FontStyle.italic)),
                        const SizedBox(height: 12),
                        Text(selected.description,
                            style: GoogleFonts.manrope(
                                fontSize: 14, color: cs.onSurface, height: 1.55)),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _Chip(
                              icon: Icons.water_drop_outlined,
                              label: 'Her ${selected.waterFrequencyDays} günde bir',
                              cs: cs,
                            ),
                            _Chip(
                              icon: Icons.wb_sunny_outlined,
                              label: _lightLabel(selected.lightRequirement),
                              cs: cs,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Alt butonlar
          _animated(
            widget.matches.length + 2,
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
              child: Column(
                children: [
                  AppButton.primary(
                    label: _isSaving ? 'Kaydediliyor...' : 'Bu Bitkiyi Kaydet',
                    isLoading: _isSaving,
                    onPressed: () async {
                      setState(() => _isSaving = true);
                      try {
                        final savedPlant = await ref
                            .read(plantsProvider.notifier)
                            .savePlant(selected, imageFile: widget.scannedImage);
                        await ref.read(trialProvider.notifier).refresh();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${selected.turkishName} koleksiyonunuza eklendi!',
                                style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                              ),
                              backgroundColor: cs.primaryContainer,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          );
                          if (savedPlant != null) {
                            context.go('/plants/${savedPlant['id']}');
                          } else {
                            context.go('/plants');
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(e.toString().replaceAll("Exception: ", ""), style: const TextStyle(color: Colors.white)),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                      } finally {
                        if (mounted) setState(() => _isSaving = false);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  AppButton.ghost(
                    label: 'Tekrar Tara',
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _lightLabel(String key) => switch (key) {
    'bright_indirect' => 'Parlak dolaylı ışık',
    'low_to_indirect' => 'Az ila dolaylı ışık',
    'any' => 'Her ortamda',
    _ => 'Dolaylı ışık',
  };
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme cs;
  const _Chip({required this.icon, required this.label, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.primary),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.manrope(
                  fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary)),
        ],
      ),
    );
  }
}
