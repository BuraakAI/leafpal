import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/di.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/plant_image.dart';
import '../data/plants_repository.dart';
import '../domain/user_plant.dart';
import 'plants_provider.dart';

final _plantDetailProvider = FutureProvider.family<UserPlant, String>((ref, id) {
  return ref.read(plantsRepositoryProvider).getPlantById(id);
});

class PlantDetailScreen extends ConsumerWidget {
  final String plantId;
  const PlantDetailScreen({super.key, required this.plantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantAsync = ref.watch(_plantDetailProvider(plantId));
    return plantAsync.when(
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Yüklenemedi: $e')),
      ),
      data: (plant) => _PlantDetailView(plant: plant),
    );
  }
}

class _PlantDetailView extends ConsumerWidget {
  final UserPlant plant;
  const _PlantDetailView({required this.plant});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Bitki silinsin mi?',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: cs.onSurface)),
        content: Text('${plant.displayName} koleksiyonundan kaldırılacak.',
            style: GoogleFonts.manrope(color: cs.onSurfaceVariant)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('İptal', style: GoogleFonts.manrope(color: cs.onSurfaceVariant))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('Sil', style: GoogleFonts.manrope(color: cs.error, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(plantsProvider.notifier).deletePlant(plant.id);
      if (context.mounted) context.go('/plants');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final waterDays = plant.carePlan?.wateringDays ?? plant.species.waterFrequencyDays;
    final fertilizeDays = plant.carePlan?.fertilizingDays ?? 30;
    final repotDays = plant.carePlan?.repottingDays ?? 365;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          // Hero photo
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.primary,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => context.go('/plants'),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: GestureDetector(
                  onTap: () => _confirmDelete(context, ref),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PlantImage(
                    imageUrl: plant.imageUrl ?? plant.species.imageUrl,
                    scientificName: plant.species.scientificName,
                    borderRadius: 0,
                  ),
                  // Bottom gradient
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppColors.primary.withValues(alpha: 0.7)],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                  // Plant name overlay
                  Positioned(
                    left: 20, right: 20, bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plant.displayName,
                          style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w800,
                              color: Colors.white, letterSpacing: -0.3)),
                        Text(plant.species.scientificName,
                          style: GoogleFonts.manrope(fontSize: 14, color: Colors.white70,
                              fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick care chips
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      _CareChip(icon: Icons.water_drop_rounded, label: 'Her $waterDays günde',
                          color: const Color(0xFF2196F3)),
                      _CareChip(icon: Icons.wb_sunny_rounded, label: _lightLabel(plant.species.lightRequirement),
                          color: const Color(0xFFFF9800)),
                      _CareChip(icon: Icons.water_rounded, label: _humidLabel(plant.species.humidityLevel),
                          color: const Color(0xFF4CAF50)),
                    ],
                  ),

                  if (plant.species.description != null) ...[
                    const SizedBox(height: 24),
                    _SectionTitle('Hakkında', cs: cs),
                    const SizedBox(height: 10),
                    Text(plant.species.description!,
                      style: GoogleFonts.manrope(fontSize: 15, color: cs.onSurface, height: 1.65)),
                  ],

                  const SizedBox(height: 24),
                  _SectionTitle('Bakım Planı', cs: cs),
                  const SizedBox(height: 12),

                  // Care cards — 3 columns
                  Row(
                    children: [
                      Expanded(child: _CareCard(
                        icon: Icons.water_drop_rounded,
                        color: const Color(0xFF2196F3),
                        label: 'Sulama',
                        value: 'Her $waterDays gün',
                        cs: cs,
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: _CareCard(
                        icon: Icons.grass_rounded,
                        color: const Color(0xFF4CAF50),
                        label: 'Gübreleme',
                        value: 'Her $fertilizeDays gün',
                        cs: cs,
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: _CareCard(
                        icon: Icons.change_circle_rounded,
                        color: const Color(0xFF795548),
                        label: 'Saksı',
                        value: 'Her $repotDays gün',
                        cs: cs,
                      )),
                    ],
                  ),

                  // Kültürel bilgi kartı — her bitkide göster
                  const SizedBox(height: 24),
                  _SectionTitle('Kültürel Bilgiler', cs: cs),
                  const SizedBox(height: 12),
                  _CulturalCard(species: plant.species, cs: cs),

                  const SizedBox(height: 24),
                  _SectionTitle('Notlarım', cs: cs),
                  const SizedBox(height: 10),
                  _NotesSection(plant: plant),

                  const SizedBox(height: 28),

                  // Add reminder
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [cs.primary, cs.primaryContainer],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: [
                          BoxShadow(color: cs.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6)),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/reminder/setup',
                            extra: (plantId: plant.id, plantName: plant.displayName)),
                        icon: const Icon(Icons.add_alarm_rounded),
                        label: Text('Hatırlatıcı Ekle',
                            style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _lightLabel(String key) => switch (key) {
    'bright_indirect' => 'Parlak dolaylı',
    'low_to_indirect' => 'Az ışık',
    'direct' => 'Direkt güneş',
    _ => 'Dolaylı ışık',
  };

  String _humidLabel(String key) => switch (key) {
    'high' => 'Yüksek nem',
    'low' => 'Düşük nem',
    _ => 'Orta nem',
  };
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final ColorScheme cs;
  const _SectionTitle(this.text, {required this.cs});

  @override
  Widget build(BuildContext context) => Text(text,
    style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface, letterSpacing: -0.2));
}

class _CareChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _CareChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _CareCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final ColorScheme cs;
  const _CareCard({required this.icon, required this.color, required this.label, required this.value, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 10),
          Text(label, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600,
              color: color, letterSpacing: 0.3)),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.manrope(fontSize: 12, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ── Cultural info card ────────────────────────────────────────────
class _CulturalCard extends StatelessWidget {
  final PlantSpecies species;
  final ColorScheme cs;
  const _CulturalCard({required this.species, required this.cs});

  String _difficultyLabel(String? d) => switch (d) {
    'easy' => 'Kolay',
    'hard' => 'Zor',
    _ => 'Orta',
  };

  Color _difficultyColor(String? d) => switch (d) {
    'easy' => const Color(0xFF4CAF50),
    'hard' => const Color(0xFFEF5350),
    _ => const Color(0xFFFF9800),
  };

  @override
  Widget build(BuildContext context) {
    final hasData = species.origin != null || species.family != null || species.funFact != null;
    final diffColor = _difficultyColor(species.difficulty);

    if (!hasData) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 18, color: cs.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Bu bitki türü için kültürel bilgi henüz eklenmedi.',
                style: GoogleFonts.manrope(fontSize: 13, color: cs.onSurfaceVariant, height: 1.45),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık + zorluk badge
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(Icons.public_rounded, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    species.origin ?? species.scientificName,
                    style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: diffColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: diffColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.spa_rounded, size: 11, color: diffColor),
                      const SizedBox(width: 4),
                      Text(
                        _difficultyLabel(species.difficulty),
                        style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: diffColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Familya
          if (species.family != null)
            _InfoRow(
              icon: Icons.category_outlined,
              label: 'Familya',
              value: species.family!,
              cs: cs,
            ),

          // Fun fact
          if (species.funFact != null) ...[
            Divider(height: 1, indent: 16, endIndent: 16, color: cs.outlineVariant.withValues(alpha: 0.2)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFFFFB300)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'İlginç Bilgi',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFFFB300),
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          species.funFact!,
                          style: GoogleFonts.manrope(fontSize: 13, color: cs.onSurface, height: 1.55),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme cs;
  const _InfoRow({required this.icon, required this.label, required this.value, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Icon(icon, size: 15, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.manrope(fontSize: 13, color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.manrope(fontSize: 13, color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notes section ────────────────────────────────────────────────
class _NotesSection extends ConsumerStatefulWidget {
  final UserPlant plant;
  const _NotesSection({required this.plant});

  @override
  ConsumerState<_NotesSection> createState() => _NotesSectionState();
}

class _NotesSectionState extends ConsumerState<_NotesSection> {
  late final TextEditingController _ctrl;
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.plant.notes ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final dio = ref.read(apiClientProvider).dio;
      await dio.patch('/api/plants/${widget.plant.id}/notes', data: {'notes': _ctrl.text.trim()});
      setState(() => _editing = false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
            child: Row(
              children: [
                Icon(Icons.notes_rounded, size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text('Not', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
                const Spacer(),
                if (!_editing)
                  GestureDetector(
                    onTap: () => setState(() => _editing = true),
                    child: Text('Düzenle', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary)),
                  ),
              ],
            ),
          ),
          Divider(height: 16, indent: 16, endIndent: 16, color: cs.outlineVariant.withValues(alpha: 0.3)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: _editing
                ? Column(
                    children: [
                      TextField(
                        controller: _ctrl,
                        maxLines: 4,
                        autofocus: true,
                        style: GoogleFonts.manrope(fontSize: 14, height: 1.6, color: cs.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Bu bitki hakkında not ekleyin...',
                          hintStyle: GoogleFonts.manrope(fontSize: 14, color: cs.outline),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          fillColor: Colors.transparent,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () { setState(() => _editing = false); _ctrl.text = widget.plant.notes ?? ''; },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: cs.outlineVariant),
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              child: Text('İptal', style: GoogleFonts.manrope(color: cs.onSurfaceVariant)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saving ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: cs.primary,
                                foregroundColor: Colors.white,
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                elevation: 0,
                              ),
                              child: _saving
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Text('Kaydet', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Text(
                    _ctrl.text.isEmpty ? 'Henüz not yok. "Düzenle"ye bas.' : _ctrl.text,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: _ctrl.text.isEmpty ? cs.outline : cs.onSurface,
                      height: 1.65,
                      fontStyle: _ctrl.text.isEmpty ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
