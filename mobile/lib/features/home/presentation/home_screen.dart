import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/plant_image.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/domain/trial_state.dart';
import '../../my_plants/presentation/plants_provider.dart';
import '../../reminders/domain/reminder.dart';
import '../../reminders/presentation/reminders_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantsAsync = ref.watch(plantsProvider);
    final remindersAsync = ref.watch(remindersProvider);
    final authState = ref.watch(authProvider);
    final trial = ref.watch(trialProvider);
    final cs = Theme.of(context).colorScheme;
    final userName = authState is AuthAuthenticated
        ? (authState.user.name?.split(' ').first ?? 'Kullanıcı')
        : 'Kullanıcı';
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Günaydın' : hour < 18 ? 'Merhaba' : 'İyi akşamlar';

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // AppBar
              SliverAppBar(
                floating: true,
                backgroundColor: cs.surface.withValues(alpha: 0.92),
                elevation: 0,
                toolbarHeight: 60,
                title: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.eco, size: 18, color: cs.primary),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'LeafPal',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    _ScanQuotaPill(trial: trial, onTap: () => context.push('/premium'), cs: cs),
                  ],
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.safeArea),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 8),

                    // Greeting
                    Text(
                      '$greeting, $userName 🌿',
                      style: GoogleFonts.manrope(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                        letterSpacing: -0.28,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bitkileriniz sizi bekliyor.',
                      style: GoogleFonts.manrope(fontSize: 15, color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),

                    // Notification banner
                    remindersAsync.when(
                      data: (reminders) {
                        final urgent = reminders.where((r) {
                          final diff = r.dueDate.difference(DateTime.now()).inDays;
                          return diff <= 1;
                        }).toList();
                        if (urgent.isEmpty) return const SizedBox.shrink();
                        return _NotificationBanner(reminders: urgent, onTap: () => context.go('/calendar'), cs: cs);
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    const SizedBox(height: AppSpacing.sectionGap),

                    // Quick Actions
                    Row(
                      children: [
                        _QuickAction(
                          icon: Icons.photo_camera_outlined,
                          label: 'Bitki Tara',
                          color: cs.secondaryContainer,
                          iconColor: cs.onSecondaryContainer,
                          onTap: () => context.push('/scan'),
                          cs: cs,
                        ),
                        const SizedBox(width: 12),
                        _QuickAction(
                          icon: Icons.add_circle_outline,
                          label: 'Bitki Ekle',
                          color: cs.secondaryContainer,
                          iconColor: cs.onSecondaryContainer,
                          onTap: () => context.push('/plants/new'),
                          cs: cs,
                        ),
                        const SizedBox(width: 12),
                        _QuickAction(
                          icon: Icons.healing_outlined,
                          label: 'Sorun Tespit',
                          color: cs.tertiaryContainer,
                          iconColor: cs.onTertiaryContainer,
                          onTap: () => context.push('/diagnosis'),
                          cs: cs,
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.sectionGap),

                    // My plants header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bitkilerim',
                          style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w600, color: cs.onSurface),
                        ),
                        TextButton(
                          onPressed: () => context.go('/plants'),
                          child: Text('Tümünü Gör', style: GoogleFonts.manrope(color: cs.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Plants horizontal scroll
                    plantsAsync.when(
                      data: (plants) => plants.isEmpty
                          ? _AddPlantCard(onTap: () => context.push('/plants/new'), cs: cs)
                          : SizedBox(
                              height: 210,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: plants.length + 1,
                                separatorBuilder: (_, __) => const SizedBox(width: 12),
                                itemBuilder: (_, i) {
                                  if (i == plants.length) {
                                    return _AddPlantCard(onTap: () => context.push('/plants/new'), cs: cs);
                                  }
                                  final p = plants[i];
                                  return _PlantHCard(plant: p, onTap: () => context.push('/plants/${p['id']}'), cs: cs);
                                },
                              ),
                            ),
                      loading: () => const SizedBox(height: 210, child: Center(child: CircularProgressIndicator())),
                      error: (_, __) => _AddPlantCard(onTap: () => context.push('/plants/new'), cs: cs),
                    ),

                    const SizedBox(height: AppSpacing.sectionGap),

                    // Premium upsell
                    _PremiumBanner(onTap: () => context.push('/premium')),

                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Scan Quota Pill ──────────────────────────────────────────
class _ScanQuotaPill extends StatelessWidget {
  final TrialStatus trial;
  final VoidCallback onTap;
  final ColorScheme cs;
  const _ScanQuotaPill({required this.trial, required this.onTap, required this.cs});

  @override
  Widget build(BuildContext context) {
    final label = trial.isPremium ? 'Sınırsız' : '${trial.scansRemainingToday} hak';
    final isEmpty = !trial.isPremium && trial.scansRemainingToday <= 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isEmpty ? cs.errorContainer : AppColors.primaryFixed.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: isEmpty
                ? cs.error.withValues(alpha: 0.25)
                : cs.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              trial.isPremium ? Icons.all_inclusive_rounded : Icons.photo_camera_outlined,
              size: 15,
              color: isEmpty ? cs.error : cs.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isEmpty ? cs.error : cs.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationBanner extends StatelessWidget {
  final List<Reminder> reminders;
  final VoidCallback onTap;
  final ColorScheme cs;
  const _NotificationBanner({required this.reminders, required this.onTap, required this.cs});

  @override
  Widget build(BuildContext context) {
    final first = reminders.first;
    final isOverdue = first.dueDate.isBefore(DateTime.now());

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isOverdue
              ? cs.errorContainer.withValues(alpha: 0.7)
              : AppColors.primaryFixed.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOverdue
                ? cs.error.withValues(alpha: 0.3)
                : cs.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Text(first.typeIcon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminders.length == 1
                        ? first.title
                        : '${reminders.length} bakım hatırlatıcısı!',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isOverdue ? cs.error : cs.primary,
                    ),
                  ),
                  if (first.plantName != null)
                    Text(
                      first.plantName!,
                      style: GoogleFonts.manrope(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isOverdue ? cs.error : cs.primary,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Plant H Card ────────────────────────────────────────────
class _PlantHCard extends StatelessWidget {
  final Map<String, dynamic> plant;
  final VoidCallback onTap;
  final ColorScheme cs;
  const _PlantHCard({required this.plant, required this.onTap, required this.cs});

  @override
  Widget build(BuildContext context) {
    final species = plant['species'] as Map<String, dynamic>? ?? {};
    final name = plant['nickname'] as String? ?? species['turkishName'] as String? ?? species['commonName'] as String? ?? '';
    final waterDays = plant['carePlan']?['wateringDays'] as int? ?? species['waterFrequencyDays'] as int? ?? 7;
    final addedAt = plant['addedAt'] != null ? DateTime.tryParse(plant['addedAt'] as String) : null;
    final daysLeft = addedAt?.add(Duration(days: waterDays)).difference(DateTime.now()).inDays;
    final isUrgent = daysLeft != null && daysLeft <= 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isUrgent
                ? cs.error.withValues(alpha: 0.4)
                : cs.outlineVariant.withValues(alpha: 0.3),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PlantImage(
                    imageUrl: plant['imageUrl'] as String?,
                    scientificName: species['scientificName'] as String?,
                    borderRadius: 16,
                  ),
                  if (isUrgent)
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.error,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.water_drop, size: 10, color: Colors.white),
                            const SizedBox(width: 3),
                            Text('Sulama!', style: GoogleFonts.manrope(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.water_drop_outlined, size: 11, color: isUrgent ? cs.error : cs.outline),
                      const SizedBox(width: 3),
                      Text(
                        isUrgent ? 'Sulama vakti!' : daysLeft == null ? 'Her $waterDays günde' : '$daysLeft gün sonra',
                        style: GoogleFonts.manrope(fontSize: 11, color: isUrgent ? cs.error : cs.outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPlantCard extends StatelessWidget {
  final VoidCallback onTap;
  final ColorScheme cs;
  const _AddPlantCard({required this.onTap, required this.cs});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        height: 210,
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: cs.secondaryContainer, shape: BoxShape.circle),
              child: Icon(Icons.add, color: cs.onSecondaryContainer),
            ),
            const SizedBox(height: 12),
            Text('Yeni Bitki\nEkle', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;
  final ColorScheme cs;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.iconColor, required this.onTap, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(height: 8),
              Text(label, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface, letterSpacing: 0.3), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _PremiumBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryContainer],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 18),
                    const SizedBox(width: 6),
                    Text('LeafPal Premium', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 0.5)),
                  ]),
                  const SizedBox(height: 6),
                  Text('Sınırsız bitki tanımlama\nave uzman bakım planı', style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white, height: 1.3)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
              child: Text('Keşfet', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
