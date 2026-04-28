import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/plant_image.dart';
import 'plants_provider.dart';

class MyPlantsScreen extends ConsumerStatefulWidget {
  const MyPlantsScreen({super.key});

  @override
  ConsumerState<MyPlantsScreen> createState() => _MyPlantsScreenState();
}

class _MyPlantsScreenState extends ConsumerState<MyPlantsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plantsAsync = ref.watch(plantsProvider);
    final query = _searchCtrl.text.trim().toLowerCase();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: RefreshIndicator(
        color: cs.primary,
        onRefresh: () => ref.read(plantsProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: Colors.transparent,
              expandedHeight: 174,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/kemanyaprakliincir.webp',
                      fit: BoxFit.cover,
                      alignment: Alignment.centerRight,
                      filterQuality: FilterQuality.high,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primary.withValues(alpha: 0.22),
                            AppColors.primary.withValues(alpha: 0.70),
                            cs.surface,
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bitkilerim',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Koleksiyonunu düzenle ve bakımını takip et.',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: 0.78),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          plantsAsync.when(
                            data: (plants) {
                              final count = query.isEmpty
                                  ? plants.length
                                  : plants.where((plant) => _matchesQuery(plant, query)).length;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.eco, size: 14, color: Colors.white),
                                    const SizedBox(width: 5),
                                    Text(
                                      '$count bitki',
                                      style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                                    ),
                                  ],
                                ),
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.search,
                    style: GoogleFonts.manrope(fontSize: 14, color: cs.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Koleksiyonunda ara...',
                      hintStyle: GoogleFonts.manrope(fontSize: 14, color: cs.outline),
                      prefixIcon: Icon(Icons.search_rounded, color: cs.outline, size: 20),
                      suffixIcon: query.isEmpty
                          ? null
                          : IconButton(
                              icon: Icon(Icons.close_rounded, size: 18, color: cs.outline),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {});
                              },
                            ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                      contentPadding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: plantsAsync.when(
                data: (_) => const SizedBox.shrink(),
                loading: () => LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  color: cs.primary,
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            plantsAsync.when(
              data: (plants) {
                final filteredPlants = query.isEmpty
                    ? plants
                    : plants.where((plant) => _matchesQuery(plant, query)).toList();
                if (plants.isEmpty) {
                  return SliverFillRemaining(
                    child: EmptyState(
                      icon: Icons.eco_outlined,
                      title: 'Henüz bitkiniz yok',
                      subtitle: 'İlk bitkini tarat veya adını biliyorsan elle ekle.',
                      actionLabel: 'Bitki Ekle',
                      onAction: () => context.push('/plants/new'),
                    ),
                  );
                }
                if (filteredPlants.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'Sonuç bulunamadı',
                      subtitle: 'Arama metnini değiştirerek tekrar deneyin.',
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.safeArea, 4, AppSpacing.safeArea, 100),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.70,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        if (i == filteredPlants.length) {
                          return _AddNewCard(onTap: () => context.push('/plants/new'), cs: cs);
                        }
                        return _PlantCard(plant: filteredPlants[i], cs: cs);
                      },
                      childCount: filteredPlants.length + 1,
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Text(
                    'Yüklenemedi: $e',
                    style: GoogleFonts.manrope(color: cs.onSurfaceVariant),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/plants/new'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: Text('Bitki Ekle', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
      ),
    );
  }

  bool _matchesQuery(Map<String, dynamic> plant, String query) {
    final species = plant['species'] as Map<String, dynamic>? ?? {};
    final haystack = [
      plant['nickname'],
      plant['location'],
      species['turkishName'],
      species['commonName'],
      species['scientificName'],
    ].whereType<String>().join(' ').toLowerCase();
    return haystack.contains(query);
  }
}

class _PlantCard extends StatelessWidget {
  final Map<String, dynamic> plant;
  final ColorScheme cs;
  const _PlantCard({required this.plant, required this.cs});

  @override
  Widget build(BuildContext context) {
    final species = plant['species'] as Map<String, dynamic>? ?? {};
    final name = plant['nickname'] as String?
        ?? species['turkishName'] as String?
        ?? species['commonName'] as String?
        ?? '';
    final sci = species['scientificName'] as String? ?? '';
    final waterDays = plant['carePlan']?['wateringDays'] as int?
        ?? species['waterFrequencyDays'] as int?
        ?? 7;
    final addedAt = plant['addedAt'] != null
        ? DateTime.tryParse(plant['addedAt'] as String)
        : null;
    final nextWater = addedAt?.add(Duration(days: waterDays));
    final daysLeft = nextWater?.difference(DateTime.now()).inDays;
    final isUrgent = daysLeft != null && daysLeft <= 0;
    final waterLabel = daysLeft == null
        ? 'Her $waterDays gün'
        : daysLeft <= 0
            ? 'Sulama vakti!'
            : daysLeft == 1
                ? 'Yarın'
                : '$daysLeft gün';
    final waterColor = isUrgent ? cs.error : cs.primary;

    return GestureDetector(
      onTap: () => context.push('/plants/${plant['id']}'),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isUrgent
                ? cs.error.withValues(alpha: 0.3)
                : cs.outlineVariant.withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: PlantImage(
                      imageUrl: plant['imageUrl'] as String?,
                      scientificName: species['scientificName'] as String?,
                      borderRadius: 0,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isUrgent
                            ? cs.error
                            : cs.surfaceContainerLowest.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.water_drop_rounded,
                            size: 10,
                            color: isUrgent ? Colors.white : cs.primary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            waterLabel,
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isUrgent ? Colors.white : waterColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sci,
                      style: GoogleFonts.manrope(fontSize: 11, color: cs.onSurfaceVariant, fontStyle: FontStyle.italic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddNewCard extends StatelessWidget {
  final VoidCallback onTap;
  final ColorScheme cs;
  const _AddNewCard({required this.onTap, required this.cs});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryFixed.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: AppColors.primaryFixed, shape: BoxShape.circle),
              child: Icon(Icons.add_rounded, color: cs.primary, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              'Yeni Bitki\nEkle',
              style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: cs.primary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
