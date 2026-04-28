import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import '../../auth/domain/trial_state.dart';

class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trial = ref.watch(trialProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Close button
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8, top: 4),
                    child: IconButton(
                      icon: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                      onPressed: () => context.pop(),
                    ),
                  ),
                ),

                // Premium header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      Container(
                        width: 68, height: 68,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 2),
                          boxShadow: [
                            BoxShadow(color: Colors.amber.withValues(alpha: 0.15), blurRadius: 24, spreadRadius: 2),
                          ],
                        ),
                        child: const Icon(Icons.workspace_premium_rounded, size: 34, color: Colors.amber),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'LeafPal Premium',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bitkilerinize gerçek bir uzman gibi bakın',
                        style: GoogleFonts.manrope(fontSize: 15, color: Colors.white70, height: 1.4, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                      if (!trial.isPremium) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                          ),
                          child: Text(
                            trial.trialExpired
                                ? 'Deneme süreniz doldu'
                                : '${trial.trialDaysLeft} gün · Bugün ${trial.scansRemainingToday} tarama hakkı',
                            style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Bottom panel
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      child: Column(
                        children: [
                          // Features list
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Column(
                              children: [
                                _FeatureRow(label: 'Sınırsız bitki tanımlama', icon: Icons.photo_camera_outlined, cs: cs),
                                _FeatureRow(label: 'Kişisel yapay zeka bakım planı', icon: Icons.auto_awesome_outlined, cs: cs),
                                _FeatureRow(label: 'Sınırsız bitki koleksiyonu', icon: Icons.eco_outlined, cs: cs),
                                _FeatureRow(label: 'Hastalık ve sorun teşhisi', icon: Icons.healing_outlined, cs: cs),
                                _FeatureRow(label: 'Özel hatırlatıcı şablonları', icon: Icons.notifications_active_outlined, cs: cs),
                                _FeatureRow(label: '7/24 uzman bitki desteği', icon: Icons.support_agent_outlined, cs: cs),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Plan cards
                          _PlanCard(
                            label: 'Yıllık',
                            sublabel: 'Aylık ₺66,58\'e düşer',
                            price: '₺799',
                            period: '/yıl',
                            badge: '%33 Tasarruf',
                            isHighlighted: true,
                            onTap: () => _handlePurchase(context),
                            cs: cs,
                          ),
                          const SizedBox(height: 10),
                          _PlanCard(
                            label: 'Aylık',
                            sublabel: 'İstediğinde iptal et',
                            price: '₺99',
                            period: '/ay',
                            isHighlighted: false,
                            onTap: () => _handlePurchase(context),
                            cs: cs,
                          ),

                          const SizedBox(height: 18),

                          // Guarantees
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _GuaranteeBadge(icon: Icons.lock_outline, label: 'Güvenli ödeme', cs: cs),
                              const SizedBox(width: 20),
                              _GuaranteeBadge(icon: Icons.cancel_outlined, label: 'İstediğinde iptal', cs: cs),
                            ],
                          ),

                          const SizedBox(height: 14),
                          TextButton(
                            onPressed: () => context.pop(),
                            child: Text('Belki daha sonra',
                                style: GoogleFonts.manrope(color: cs.onSurfaceVariant, fontSize: 14)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handlePurchase(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Premium aktif! (Demo mod)', style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primaryContainer,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final ColorScheme cs;
  const _FeatureRow({required this.label, required this.icon, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryFixed.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: cs.primaryContainer),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: GoogleFonts.manrope(fontSize: 15, color: cs.onSurface, fontWeight: FontWeight.w500)),
          ),
          Icon(Icons.check_circle_rounded, size: 18, color: cs.primary),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String label;
  final String sublabel;
  final String price;
  final String period;
  final String? badge;
  final bool isHighlighted;
  final VoidCallback onTap;
  final ColorScheme cs;

  const _PlanCard({
    required this.label, required this.sublabel,
    required this.price, required this.period,
    this.badge, required this.isHighlighted, required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          gradient: isHighlighted
              ? const LinearGradient(colors: [AppColors.primary, AppColors.primaryContainer], begin: Alignment.topLeft, end: Alignment.bottomRight)
              : null,
          color: isHighlighted ? null : cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isHighlighted ? Colors.transparent : cs.outlineVariant.withValues(alpha: 0.35),
          ),
          boxShadow: isHighlighted
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))]
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(label, style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w700,
                        color: isHighlighted ? Colors.white : cs.onSurface)),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(99)),
                        child: Text(badge!, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black87)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 2),
                  Text(sublabel, style: GoogleFonts.manrope(fontSize: 12,
                      color: isHighlighted ? Colors.white60 : cs.onSurfaceVariant)),
                ],
              ),
            ),
            RichText(
              text: TextSpan(children: [
                TextSpan(text: price, style: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800,
                    color: isHighlighted ? Colors.white : cs.onSurface)),
                TextSpan(text: period, style: GoogleFonts.manrope(fontSize: 13,
                    color: isHighlighted ? Colors.white60 : cs.onSurfaceVariant)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuaranteeBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme cs;
  const _GuaranteeBadge({required this.icon, required this.label, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: cs.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.manrope(fontSize: 12, color: cs.onSurfaceVariant)),
      ],
    );
  }
}
