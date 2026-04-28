import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/notification_service.dart';
import '../../my_plants/presentation/plants_provider.dart';
import 'reminders_provider.dart';

class ReminderSetupScreen extends ConsumerStatefulWidget {
  final String? plantId;
  final String? plantName;

  const ReminderSetupScreen({super.key, this.plantId, this.plantName});

  @override
  ConsumerState<ReminderSetupScreen> createState() => _ReminderSetupScreenState();
}

class _ReminderSetupScreenState extends ConsumerState<ReminderSetupScreen> {
  String _selectedType = 'watering';
  final _titleCtrl = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  bool _isLoading = false;

  // Plant selection — only used when opened without a plant context
  String? _selectedPlantId;
  String? _selectedPlantName;

  static const _types = [
    _ReminderType('watering', Icons.water_drop_rounded, 'Sulama', Color(0xFF1E88E5)),
    _ReminderType('fertilizing', Icons.grass_rounded, 'Gübreleme', Color(0xFF2E7D32)),
    _ReminderType('repotting', Icons.change_circle_rounded, 'Saksı Değişimi', Color(0xFF795548)),
    _ReminderType('misting', Icons.cloud_rounded, 'Nemlendirme', Color(0xFF00ACC1)),
    _ReminderType('pruning', Icons.content_cut_rounded, 'Budama', Color(0xFF8E5CF7)),
    _ReminderType('cleaning', Icons.cleaning_services_rounded, 'Yaprak Temizliği', Color(0xFFF9A825)),
    _ReminderType('rotation', Icons.sync_rounded, 'Yön Çevirme', Color(0xFF607D8B)),
    _ReminderType('pest_check', Icons.search_rounded, 'Zararlı Kontrolü', Color(0xFFD84315)),
    _ReminderType('custom', Icons.notifications_active_rounded, 'Özel', Color(0xFF37474F)),
  ];

  @override
  void initState() {
    super.initState();
    _selectedPlantId = widget.plantId;
    _selectedPlantName = widget.plantName;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  String get _effectivePlantId => _selectedPlantId ?? widget.plantId ?? '';
  String get _effectivePlantName => _selectedPlantName ?? widget.plantName ?? '';
  bool get _hasPlant => _effectivePlantId.isNotEmpty;

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final reminder = await ref.read(remindersProvider.notifier).create(
            type: _selectedType,
            title: _titleCtrl.text.trim(),
            dueDate: _dueDate,
            userPlantId: _hasPlant ? _effectivePlantId : null,
          );
      await NotificationService.instance.scheduleReminder(
        id: reminder.id.hashCode,
        title: reminder.title,
        body: _hasPlant ? '$_effectivePlantName için bakım vakti!' : 'Bitki bakım zamanı geldi.',
        scheduledDate: _dueDate,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hatırlatıcı eklendi!', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
      context.pop();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selected = _types.firstWhere((type) => type.id == _selectedType);
    final plantsAsync = ref.watch(plantsProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: cs.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Hatırlatıcı Ekle',
          style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: cs.onSurface, letterSpacing: -0.3),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Plant selector ──────────────────────────────
                    _SectionLabel('Bitki', cs: cs),
                    const SizedBox(height: 8),
                    _buildPlantSelector(cs, plantsAsync),

                    const SizedBox(height: 22),

                    // ── Type selection ──────────────────────────────
                    _SectionLabel('Bakım Türü', cs: cs),
                    const SizedBox(height: 10),
                    _buildTypeGrid(cs),

                    const SizedBox(height: 22),

                    // ── Title ───────────────────────────────────────
                    _SectionLabel('Başlık', cs: cs),
                    const SizedBox(height: 8),
                    _buildTitleField(cs, selected),

                    const SizedBox(height: 22),

                    // ── Date ────────────────────────────────────────
                    _SectionLabel('Tarih', cs: cs),
                    const SizedBox(height: 8),
                    _buildDatePicker(cs),
                  ],
                ),
              ),
            ),

            // ── Save button ──────────────────────────────────────
            _buildSaveButton(cs),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Plant Selector — dropdown style when no plant provided
  // ═══════════════════════════════════════════════════════════════

  Widget _buildPlantSelector(ColorScheme cs, AsyncValue<List<Map<String, dynamic>>> plantsAsync) {
    // If we already have a plant selected (either from route or user pick)
    if (_hasPlant) {
      return GestureDetector(
        onTap: widget.plantId != null ? null : () => _showPlantPicker(cs, plantsAsync),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(Icons.local_florist_rounded, color: cs.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _effectivePlantName,
                  style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: cs.primary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.plantId == null) // only show change arrow if user can change
                Icon(Icons.unfold_more_rounded, size: 16, color: cs.primary.withValues(alpha: 0.6)),
            ],
          ),
        ),
      );
    }

    // No plant selected — show picker button
    return GestureDetector(
      onTap: () => _showPlantPicker(cs, plantsAsync),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4), style: BorderStyle.solid),
        ),
        child: Row(
          children: [
            Icon(Icons.eco_outlined, color: cs.outline, size: 18),
            const SizedBox(width: 10),
            Text(
              'Bitki seç...',
              style: GoogleFonts.manrope(fontSize: 15, color: cs.outline),
            ),
            const Spacer(),
            Icon(Icons.unfold_more_rounded, size: 16, color: cs.outline),
          ],
        ),
      ),
    );
  }

  void _showPlantPicker(ColorScheme cs, AsyncValue<List<Map<String, dynamic>>> plantsAsync) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(99)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  Text('Bitki Seç', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: cs.onSurface)),
                  const Spacer(),
                  if (_hasPlant)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedPlantId = null;
                          _selectedPlantName = null;
                        });
                        Navigator.of(ctx).pop();
                      },
                      child: Text('Temizle', style: GoogleFonts.manrope(fontSize: 13, color: cs.error, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
            plantsAsync.when(
              data: (plants) {
                if (plants.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.eco_outlined, size: 40, color: cs.outlineVariant),
                        const SizedBox(height: 12),
                        Text('Henüz bitkiniz yok', style: GoogleFonts.manrope(color: cs.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Text('Önce bir bitki ekleyin.', style: GoogleFonts.manrope(fontSize: 12, color: cs.outline)),
                      ],
                    ),
                  );
                }
                return ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.45),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                    itemCount: plants.length,
                    itemBuilder: (_, i) {
                      final plant = plants[i];
                      final species = plant['species'] as Map<String, dynamic>? ?? {};
                      final name = plant['nickname'] as String? ??
                          species['turkishName'] as String? ??
                          species['commonName'] as String? ?? 'Bilinmeyen';
                      final sci = species['scientificName'] as String? ?? '';
                      final isActive = plant['id'] == _selectedPlantId;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPlantId = plant['id'] as String;
                            _selectedPlantName = name;
                          });
                          Navigator.of(ctx).pop();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isActive ? cs.primary.withValues(alpha: 0.08) : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34, height: 34,
                                decoration: BoxDecoration(
                                  color: isActive ? cs.primary.withValues(alpha: 0.12) : cs.surfaceContainerHigh,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.eco_rounded, size: 16,
                                    color: isActive ? cs.primary : cs.onSurfaceVariant),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: GoogleFonts.manrope(
                                        fontSize: 14, fontWeight: FontWeight.w700,
                                        color: isActive ? cs.primary : cs.onSurface)),
                                    if (sci.isNotEmpty)
                                      Text(sci, style: GoogleFonts.manrope(
                                          fontSize: 12, color: cs.onSurfaceVariant, fontStyle: FontStyle.italic)),
                                  ],
                                ),
                              ),
                              if (isActive)
                                Icon(Icons.check_circle_rounded, size: 18, color: cs.primary),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Bitkiler yüklenemedi', style: GoogleFonts.manrope(color: cs.error)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Type Grid — minimal, soft, airy
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTypeGrid(ColorScheme cs) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _types.map((type) {
        final isSelected = type.id == _selectedType;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedType = type.id;
              if (_titleCtrl.text.trim().isEmpty ||
                  _types.any((t) => t.label == _titleCtrl.text.trim())) {
                _titleCtrl.text = type.label;
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? type.color : cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: isSelected ? Colors.transparent : cs.outlineVariant.withValues(alpha: 0.35),
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: type.color.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 3))]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  type.icon,
                  size: 15,
                  color: isSelected ? Colors.white : type.color,
                ),
                const SizedBox(width: 6),
                Text(
                  type.label,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Title Field — clean, minimal
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTitleField(ColorScheme cs, _ReminderType selected) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: TextField(
        controller: _titleCtrl,
        style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface),
        decoration: InputDecoration(
          hintText: '${selected.label} hatırlatıcısı',
          hintStyle: GoogleFonts.manrope(color: cs.outline),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Icon(selected.icon, color: selected.color, size: 18),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Date Picker — clean inline row
  // ═══════════════════════════════════════════════════════════════

  Widget _buildDatePicker(ColorScheme cs) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _dueDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: cs.primary),
            ),
            child: child!,
          ),
        );
        if (picked != null) setState(() => _dueDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, color: cs.primary, size: 16),
            const SizedBox(width: 10),
            Text(
              '${_dueDate.day}.${_dueDate.month.toString().padLeft(2, '0')}.${_dueDate.year}',
              style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface),
            ),
            const Spacer(),
            Text(
              _relativeDate(_dueDate),
              style: GoogleFonts.manrope(fontSize: 12, color: cs.outline),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 16, color: cs.outline),
          ],
        ),
      ),
    );
  }

  String _relativeDate(DateTime d) {
    final diff = d.difference(DateTime.now()).inDays;
    if (diff <= 0) return 'Bugün';
    if (diff == 1) return 'Yarın';
    return '$diff gün sonra';
  }

  // ═══════════════════════════════════════════════════════════════
  // Save Button — elegant, minimal
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSaveButton(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            disabledBackgroundColor: cs.primary.withValues(alpha: 0.5),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('Hatırlatıcı Kaydet', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800)),
        ),
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
      text.toUpperCase(),
      style: GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: cs.onSurfaceVariant,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _ReminderType {
  final String id;
  final IconData icon;
  final String label;
  final Color color;
  const _ReminderType(this.id, this.icon, this.label, this.color);
}
