import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import 'plants_provider.dart';

class ManualPlantScreen extends ConsumerStatefulWidget {
  const ManualPlantScreen({super.key});

  @override
  ConsumerState<ManualPlantScreen> createState() => _ManualPlantScreenState();
}

class _ManualPlantScreenState extends ConsumerState<ManualPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _scientificCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  int _waterDays = 7;
  String _light = 'bright_indirect';
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _scientificCtrl.dispose();
    _nicknameCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final plant = await ref.read(plantsProvider.notifier).addManualPlant(
            name: _nameCtrl.text,
            scientificName: _scientificCtrl.text,
            nickname: _nicknameCtrl.text,
            location: _locationCtrl.text,
            waterFrequencyDays: _waterDays,
            lightRequirement: _light,
          );
      if (!mounted) return;
      if (plant != null) {
        context.go('/plants/${plant['id']}');
      } else {
        context.go('/plants');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bitki eklenemedi: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Bitki Ekle',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bitkiyi zaten biliyorsan hızlıca koleksiyonuna ekle.',
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        height: 1.45,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _Section(
                      title: 'Temel Bilgiler',
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameCtrl,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Bitki adı',
                              prefixIcon: Icon(Icons.eco_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Bitki adı gerekli';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _scientificCtrl,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Bilimsel ad (opsiyonel)',
                              prefixIcon: Icon(Icons.science_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _nicknameCtrl,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Takma ad (opsiyonel)',
                              prefixIcon: Icon(Icons.local_florist_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _locationCtrl,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'Konum (Salon, balkon...)',
                              prefixIcon: Icon(Icons.place_outlined),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Builder(builder: (ctx) {
                      final cs2 = Theme.of(ctx).colorScheme;
                      return _Section(
                        title: 'Bakım Ritmi',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.water_drop_outlined, color: cs2.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Sulama: Her $_waterDays gün',
                                    style: GoogleFonts.manrope(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: cs2.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: _waterDays.toDouble(),
                              min: 2,
                              max: 21,
                              divisions: 19,
                              activeColor: cs2.primary,
                              label: '$_waterDays gün',
                              onChanged: (value) => setState(() => _waterDays = value.round()),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                const _LightChoice(value: 'bright_indirect', label: 'Parlak dolaylı', icon: Icons.wb_sunny_outlined),
                                const _LightChoice(value: 'low_to_indirect', label: 'Az ışık', icon: Icons.nightlight_outlined),
                                const _LightChoice(value: 'direct', label: 'Direkt güneş', icon: Icons.light_mode_outlined),
                              ].map((choice) {
                                final selected = _light == choice.value;
                                return ChoiceChip(
                                  selected: selected,
                                  showCheckmark: false,
                                  avatar: Icon(
                                    choice.icon,
                                    size: 16,
                                    color: selected ? cs2.onPrimary : cs2.primary,
                                  ),
                                  label: Text(choice.label),
                                  labelStyle: GoogleFonts.manrope(
                                    fontWeight: FontWeight.w700,
                                    color: selected ? cs2.onPrimary : cs2.primary,
                                  ),
                                  selectedColor: cs2.primary,
                                  backgroundColor: cs2.primaryContainer.withValues(alpha: 0.4),
                                  side: BorderSide(
                                    color: selected ? cs2.primary : cs2.primary.withValues(alpha: 0.15),
                                  ),
                                  onSelected: (_) => setState(() => _light = choice.value),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.add_rounded),
              label: Text(
                _isSaving ? 'Ekleniyor...' : 'Koleksiyona Ekle',
                style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: cs.primary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _LightChoice {
  final String value;
  final String label;
  final IconData icon;
  const _LightChoice({required this.value, required this.label, required this.icon});
}
