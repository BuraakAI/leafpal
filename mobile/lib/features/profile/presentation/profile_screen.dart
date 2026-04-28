import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/di.dart';
import '../../../app/theme/app_colors.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/domain/trial_state.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final trial = ref.watch(trialProvider);
    final themeMode = ref.watch(themeModeProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final initials = user?.name?.isNotEmpty == true ? user!.name![0].toUpperCase() : 'L';
    final isDark = themeMode == ThemeMode.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          // Premium header
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryContainer],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                        ),
                        child: Center(
                          child: Text(initials,
                              style: GoogleFonts.manrope(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.name ?? 'LeafPal Kullanıcısı',
                        style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 2),
                      Text(user?.email ?? '',
                          style: GoogleFonts.manrope(fontSize: 14, color: Colors.white60)),
                      const SizedBox(height: 16),

                      // Trial / Premium badge
                      GestureDetector(
                        onTap: () => context.push('/premium'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                trial.isPremium ? Icons.workspace_premium_rounded : Icons.timer_outlined,
                                size: 15,
                                color: trial.isPremium ? Colors.amber : Colors.white70,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                trial.isPremium
                                    ? 'Premium Üye'
                                    : trial.trialExpired
                                        ? 'Deneme doldu · Premium\'a Geç'
                                        : '${trial.trialDaysLeft} gün deneme · ${trial.scansRemainingToday} tarama hakkı',
                                style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                              if (!trial.isPremium) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white60),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Settings
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('Görünüm', cs: cs),
                  const SizedBox(height: 8),
                  _ToggleRow(
                    icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    label: 'Karanlık Mod',
                    value: isDark,
                    onChanged: (v) => ref
                        .read(themeModeProvider.notifier)
                        .setMode(v ? ThemeMode.dark : ThemeMode.light),
                    cs: cs,
                  ),

                  const SizedBox(height: 20),
                  _SectionLabel('Hesap', cs: cs),
                  const SizedBox(height: 8),
                  _EditableNameRow(
                    name: user?.name ?? '',
                    cs: cs,
                    onEdit: () => _showEditNameDialog(context, ref, user?.name),
                  ),
                  _MenuRow(icon: Icons.workspace_premium_outlined, label: 'Premium\'a Geç',
                      onTap: () => context.push('/premium'), accent: true, cs: cs),
                  _MenuRow(
                    icon: Icons.credit_card_rounded,
                    label: 'Üyelik ve Ödeme',
                    onTap: () => _showBillingSheet(context, trial, user?.email),
                    cs: cs,
                  ),
                  _MenuRow(icon: Icons.notifications_outlined, label: 'Bildirimler', onTap: () {}, cs: cs),
                  _MenuRow(icon: Icons.language_outlined, label: 'Dil', trailing: 'Türkçe', onTap: () {}, cs: cs),

                  const SizedBox(height: 20),
                  _SectionLabel('Hakkında', cs: cs),
                  const SizedBox(height: 8),
                  _MenuRow(icon: Icons.privacy_tip_outlined, label: 'Gizlilik Politikası', onTap: () {}, cs: cs),
                  _MenuRow(icon: Icons.info_outlined, label: 'Uygulama Sürümü', trailing: '1.0.0', onTap: () {}, cs: cs),

                  const SizedBox(height: 28),

                  // Logout
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) context.go('/login');
                      },
                      icon: Icon(Icons.logout_rounded, color: cs.error),
                      label: Text('Çıkış Yap',
                          style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: cs.error)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: cs.error),
                        shape: const StadiumBorder(),
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
}

void _showEditNameDialog(BuildContext context, WidgetRef ref, String? currentName) {
  final cs = Theme.of(context).colorScheme;
  final controller = TextEditingController(text: currentName ?? '');
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: cs.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Ad Soyad Düzenle',
          style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: cs.onSurface)),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        style: GoogleFonts.manrope(color: cs.onSurface),
        decoration: InputDecoration(
          hintText: 'Adınızı girin',
          hintStyle: GoogleFonts.manrope(color: cs.onSurfaceVariant),
          filled: true,
          fillColor: cs.surfaceContainerLow,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text('İptal', style: GoogleFonts.manrope(color: cs.onSurfaceVariant)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            shape: const StadiumBorder(),
          ),
          onPressed: () async {
            final newName = controller.text.trim();
            if (newName.isEmpty) return;
            Navigator.of(ctx).pop();
            await _saveProfileName(context, ref, newName);
          },
          child: Text('Kaydet', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}

Future<void> _saveProfileName(BuildContext context, WidgetRef ref, String name) async {
  final cs = Theme.of(context).colorScheme;
  try {
    await ref.read(authRepositoryProvider).updateProfile(name: name);
    ref.read(authProvider.notifier).updateName(name);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ad güncellendi', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
        backgroundColor: cs.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Güncelleme başarısız', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
        backgroundColor: cs.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }
}

void _showBillingSheet(BuildContext context, TrialStatus trial, String? email) {
  final cs = Theme.of(context).colorScheme;
  final packageName = trial.isPremium ? 'Premium Yıllık' : 'Deneme Planı';
  final renewalText = trial.isPremium
      ? 'Yenileme: 28.04.2027'
      : trial.trialExpired
          ? 'Deneme süresi doldu'
          : 'Kalan deneme: ${trial.trialDaysLeft} gün';

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: cs.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Üyelik ve Ödeme',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email ?? 'LeafPal hesabı',
              style: GoogleFonts.manrope(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            _BillingInfoRow(icon: Icons.workspace_premium_rounded, label: 'Paket', value: packageName, cs: cs),
            _BillingInfoRow(icon: Icons.event_available_rounded, label: 'Durum', value: renewalText, cs: cs),
            _BillingInfoRow(
              icon: Icons.credit_card_rounded,
              label: 'Ödeme yöntemi',
              value: trial.isPremium ? '•••• 4242' : 'Henüz ödeme yöntemi yok',
              cs: cs,
            ),
            if (trial.isPremium)
              _BillingInfoRow(
                icon: Icons.calendar_today_rounded,
                label: 'Üye olma tarihi',
                value: '28.04.2026',
                cs: cs,
              ),
            const SizedBox(height: 16),
            if (!trial.isPremium) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.push('/premium');
                  },
                  icon: const Icon(Icons.workspace_premium_rounded),
                  label: Text(
                    'Premium\'a Geç',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(ctx).pop(),
                icon: const Icon(Icons.cancel_outlined),
                label: Text(
                  trial.isPremium ? 'Üyeliği İptal Et' : 'Denemeyi Sonlandır',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.error,
                  side: BorderSide(color: cs.error),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Canlı ödeme entegrasyonu bağlandığında kart ve fatura bilgileri mağaza sağlayıcısından güncellenecek.',
              style: GoogleFonts.manrope(fontSize: 12, color: cs.outline, height: 1.45),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BillingInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme cs;
  const _BillingInfoRow({required this.icon, required this.label, required this.value, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: cs.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: GoogleFonts.manrope(fontSize: 13, color: cs.onSurfaceVariant)),
          ),
          Text(value, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: cs.onSurface)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final ColorScheme cs;
  const _SectionLabel(this.text, {required this.cs});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: cs.onSurfaceVariant,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final ColorScheme cs;
  const _ToggleRow({required this.icon, required this.label, required this.value, required this.onChanged, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: AppColors.primaryFixed.withValues(alpha: 0.5), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: GoogleFonts.manrope(fontSize: 15, color: cs.onSurface))),
          Switch.adaptive(value: value, activeColor: cs.primary, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;
  final bool accent;
  final ColorScheme cs;
  const _MenuRow({required this.icon, required this.label, this.trailing, required this.onTap, this.accent = false, required this.cs});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: accent ? AppColors.primaryFixed.withValues(alpha: 0.3) : cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accent ? AppColors.primaryFixed.withValues(alpha: 0.25) : cs.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: accent ? AppColors.primaryFixed : cs.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: accent ? cs.primary : cs.onSurfaceVariant),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: GoogleFonts.manrope(
                  fontSize: 15, color: accent ? cs.primary : cs.onSurface,
                  fontWeight: accent ? FontWeight.w600 : FontWeight.w400)),
            ),
            if (trailing != null)
              Text(trailing!, style: GoogleFonts.manrope(fontSize: 13, color: cs.onSurfaceVariant)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 18,
                color: accent ? cs.primary : cs.outlineVariant),
          ],
        ),
      ),
    );
  }
}

class _EditableNameRow extends StatelessWidget {
  final String name;
  final ColorScheme cs;
  final VoidCallback onEdit;
  const _EditableNameRow({required this.name, required this.cs, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: cs.surfaceContainerHigh, shape: BoxShape.circle),
              child: Icon(Icons.person_outline_rounded, size: 16, color: cs.onSurfaceVariant),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ad Soyad', style: GoogleFonts.manrope(fontSize: 11, color: cs.onSurfaceVariant)),
                  Text(name.isNotEmpty ? name : 'Belirtilmemiş',
                      style: GoogleFonts.manrope(fontSize: 15, color: cs.onSurface)),
                ],
              ),
            ),
            Icon(Icons.edit_outlined, size: 16, color: cs.primary),
          ],
        ),
      ),
    );
  }
}
