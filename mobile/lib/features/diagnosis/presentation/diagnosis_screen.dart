import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/di.dart';
import '../../my_plants/presentation/plants_provider.dart';

// ── Models ──────────────────────────────────────────────────────────────────

class _DiagnosisIssue {
  final String name;
  final String description;
  final String solution;
  final String severity;

  const _DiagnosisIssue({
    required this.name,
    required this.description,
    required this.solution,
    required this.severity,
  });

  factory _DiagnosisIssue.fromJson(Map<String, dynamic> j) => _DiagnosisIssue(
        name: j['name'] as String,
        description: j['description'] as String,
        solution: j['solution'] as String,
        severity: j['severity'] as String,
      );
}

// ── Symptom data ─────────────────────────────────────────────────────────────

class _SymptomOption {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  const _SymptomOption(this.key, this.label, this.icon, this.color);
}

const _symptoms = [
  _SymptomOption('yellowing', 'Sararma', Icons.circle, Color(0xFFFFD666)),
  _SymptomOption('spots', 'Yaprak Lekesi', Icons.blur_circular_outlined, Color(0xFFE57373)),
  _SymptomOption('wilting', 'Solma / Sarkma', Icons.water_drop_outlined, Color(0xFF64B5F6)),
  _SymptomOption('dropping', 'Yaprak Dökümü', Icons.eco_outlined, Color(0xFFA5D6A7)),
  _SymptomOption('root_rot', 'Kök Çürümesi', Icons.grass_outlined, Color(0xFF8D6E63)),
  _SymptomOption('pests', 'Zararlı / Böcek', Icons.bug_report_outlined, Color(0xFFCE93D8)),
  _SymptomOption('leggy', 'Uzun Zayıf Gövde', Icons.height_rounded, Color(0xFF80CBC4)),
  _SymptomOption('pale', 'Solgun Renk', Icons.brightness_low_rounded, Color(0xFFFFCC80)),
];

// ── Screen ───────────────────────────────────────────────────────────────────

class DiagnosisScreen extends ConsumerStatefulWidget {
  const DiagnosisScreen({super.key});

  @override
  ConsumerState<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends ConsumerState<DiagnosisScreen> {
  int _step = 0;
  XFile? _image;
  Map<String, dynamic>? _selectedPlant;
  final Set<String> _selected = {};
  bool _loading = false;
  String? _error;
  List<_DiagnosisIssue> _issues = [];
  String _disclaimer = '';
  final _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 1080);
    if (picked != null) setState(() => _image = picked);
  }

  Future<void> _analyze() async {
    setState(() { _loading = true; _error = null; _step = 2; });
    try {
      final dio = ref.read(apiClientProvider).dio;
      final formData = FormData.fromMap({

        'symptoms': jsonEncode(_selected.toList()),
        if (_selectedPlant != null)
          'plantName': (_selectedPlant!['nickname'] as String?) ??
              (_selectedPlant!['species'] as Map<String, dynamic>?)?['turkishName'] as String? ?? '',
        'image': MultipartFile.fromBytes(
          await _image!.readAsBytes(),
          filename: 'diagnosis.jpg',
        ),
      });
      // Minimum 4.5 sn — animasyon eksiksiz görünsün
      final results = await Future.wait<dynamic>([
        dio.post('/api/diagnosis', data: formData),
        Future<void>.delayed(const Duration(milliseconds: 4500)),
      ]);
      final res = results[0] as dynamic;
      final data = res.data as Map<String, dynamic>;
      final issuesList = (data['possibleIssues'] as List)
          .map((e) => _DiagnosisIssue.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _issues = issuesList;
        _disclaimer = data['disclaimer'] as String? ?? '';
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; _error = 'Analiz sırasında hata oluştu. Tekrar deneyin.'; });
    }
  }

  void _reset() => setState(() {
    _step = 0; _image = null; _selectedPlant = null;
    _selected.clear(); _issues = []; _error = null;
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: _loading
          ? _DiagnosisAnalyzing(cs: cs)
          : _step == 0 ? _StepPhoto(
              image: _image,
              selectedPlant: _selectedPlant,
              cs: cs,
              onPick: _pickImage,
              onSelectPlant: (p) => setState(() => _selectedPlant = p),
              onNext: () => setState(() => _step = 1),
            ) : _step == 1 ? _StepSymptoms(
              selected: _selected,
              cs: cs,
              onToggle: (k) => setState(() => _selected.contains(k) ? _selected.remove(k) : _selected.add(k)),
              onBack: () => setState(() => _step = 0),
              onAnalyze: _analyze,
            ) : _StepResult(
              loading: false,
              error: _error,
              issues: _issues,
              disclaimer: _disclaimer,
              cs: cs,
              onReset: _reset,
            ),
    );
  }
}

// ── Diagnosis analyzing — full-screen loading ─────────────────────────────────

class _DiagnosisAnalyzing extends StatefulWidget {
  final ColorScheme cs;
  const _DiagnosisAnalyzing({required this.cs});

  @override
  State<_DiagnosisAnalyzing> createState() => _DiagnosisAnalyzingState();
}

class _DiagnosisAnalyzingState extends State<_DiagnosisAnalyzing>
    with SingleTickerProviderStateMixin {
  static const _steps = [
    (icon: Icons.image_search_rounded,      label: 'Fotoğraf inceleniyor…'),
    (icon: Icons.biotech_rounded,           label: 'Belirtiler değerlendiriliyor…'),
    (icon: Icons.medical_information_rounded, label: 'Olası sorunlar tespit ediliyor…'),
    (icon: Icons.healing_rounded,           label: 'Çözüm önerileri hazırlanıyor…'),
    (icon: Icons.check_circle_outline_rounded, label: 'Rapor derleniyor…'),
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
      if (mounted) setState(() => _stepIndex = (_stepIndex + 1) % _steps.length);
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
            ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.primary.withValues(alpha: 0.2), width: 2),
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(scale: anim, child: child),
                    ),
                    child: Icon(step.icon, key: ValueKey(step.icon), size: 56, color: cs.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 36),
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
                    color: done || active ? cs.primary : cs.outlineVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(anim),
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
              'Bitkinin durumu analiz ediliyor.',
              style: GoogleFonts.manrope(fontSize: 14, color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
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

// ── Step 0: Photo (REQUIRED) + Plant selector ─────────────────────────────────

class _StepPhoto extends ConsumerWidget {
  final XFile? image;
  final Map<String, dynamic>? selectedPlant;
  final ColorScheme cs;
  final Function(ImageSource) onPick;
  final Function(Map<String, dynamic>?) onSelectPlant;
  final VoidCallback onNext;

  const _StepPhoto({
    required this.image,
    required this.selectedPlant,
    required this.cs,
    required this.onPick,
    required this.onSelectPlant,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plantsAsync = ref.watch(plantsProvider);
    final hasPhoto = image != null;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AppBar
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
                ),
                Expanded(
                  child: Text(
                    'Sorun Tespiti',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bitkini fotoğrafla',
                    style: GoogleFonts.manrope(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Yaprak, dal veya toprak fotoğrafı eklemek zorunludur.',
                    style: GoogleFonts.manrope(fontSize: 14, color: cs.onSurfaceVariant, height: 1.45),
                  ),

                  const SizedBox(height: 20),

                  // ── Fotoğraf alanı (ZORUNLU) ──────────────────
                  GestureDetector(
                    onTap: () => _showPicker(context),
                    child: Container(
                      width: double.infinity,
                      height: 220,
                      decoration: BoxDecoration(
                        color: hasPhoto
                            ? Colors.transparent
                            : cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: hasPhoto
                              ? cs.primary.withValues(alpha: 0.4)
                              : cs.outline.withValues(alpha: 0.3),
                          width: hasPhoto ? 1.5 : 1,
                        ),
                      ),
                      child: hasPhoto
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(19),
                                  child: FutureBuilder<Uint8List>(
                                    future: image!.readAsBytes(),
                                    builder: (ctx, snap) => snap.hasData
                                        ? Image.memory(snap.data!, fit: BoxFit.cover)
                                        : Container(color: cs.surfaceContainerLow),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () => _showPicker(context),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: cs.primaryContainer.withValues(alpha: 0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.add_photo_alternate_outlined, size: 32, color: cs.primary),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Fotoğraf ekle',
                                  style: GoogleFonts.manrope(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Zorunlu · Kamera veya galeri',
                                  style: GoogleFonts.manrope(fontSize: 13, color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Hızlı picker butonları
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => onPick(ImageSource.gallery),
                          icon: Icon(Icons.photo_library_outlined, size: 16, color: cs.primary),
                          label: Text('Galeri', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: cs.primary)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: cs.primary.withValues(alpha: 0.3)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => onPick(ImageSource.camera),
                          icon: Icon(Icons.camera_alt_outlined, size: 16, color: cs.primary),
                          label: Text('Kamera', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: cs.primary)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: cs.primary.withValues(alpha: 0.3)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── Kayıtlı bitki seç (opsiyonel) ─────────────
                  Text(
                    'Hangi bitkin? (opsiyonel)',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kayıtlı bitkini seçersen daha isabetli sonuç alırsın.',
                    style: GoogleFonts.manrope(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),

                  plantsAsync.when(
                    data: (plants) {
                      if (plants.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'Henüz kayıtlı bitkin yok.',
                            style: GoogleFonts.manrope(fontSize: 13, color: cs.onSurfaceVariant),
                          ),
                        );
                      }
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // "Seçme" chip
                          _PlantChip(
                            label: 'Belirtme',
                            isSelected: selectedPlant == null,
                            cs: cs,
                            onTap: () => onSelectPlant(null),
                          ),
                          ...plants.map((p) {
                            final species = p['species'] as Map<String, dynamic>? ?? {};
                            final name = p['nickname'] as String? ??
                                species['turkishName'] as String? ??
                                species['commonName'] as String? ?? '';
                            return _PlantChip(
                              label: name,
                              isSelected: selectedPlant?['id'] == p['id'],
                              cs: cs,
                              onTap: () => onSelectPlant(p),
                            );
                          }),
                        ],
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // ── Devam Et butonu ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: hasPhoto ? onNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  disabledBackgroundColor: cs.surfaceContainerHigh,
                  foregroundColor: cs.onPrimary,
                  disabledForegroundColor: cs.onSurfaceVariant,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!hasPhoto) ...[
                      Icon(Icons.photo_camera_outlined, size: 18, color: cs.onSurfaceVariant),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      hasPhoto ? 'Devam Et →' : 'Önce fotoğraf ekle',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPicker(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: cs.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.camera_alt_outlined, color: cs.primary),
                title: Text('Kamera', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: cs.onSurface)),
                onTap: () { Navigator.pop(context); onPick(ImageSource.camera); },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: cs.primary),
                title: Text('Galeriden Seç', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: cs.onSurface)),
                onTap: () { Navigator.pop(context); onPick(ImageSource.gallery); },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlantChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ColorScheme cs;
  final VoidCallback onTap;
  const _PlantChip({required this.label, required this.isSelected, required this.cs, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? cs.onPrimary : cs.onSurface,
          ),
        ),
      ),
    );
  }
}

// ── Step 1: Symptoms ──────────────────────────────────────────────────────────

class _StepSymptoms extends StatelessWidget {
  final Set<String> selected;
  final ColorScheme cs;
  final Function(String) onToggle;
  final VoidCallback onBack;
  final VoidCallback onAnalyze;
  const _StepSymptoms({
    required this.selected,
    required this.cs,
    required this.onToggle,
    required this.onBack,
    required this.onAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
                ),
                Expanded(
                  child: Text(
                    'Belirtiler',
                    style: GoogleFonts.manrope(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Text(
              'Bitkinde hangi belirtiler var? (birden fazla seçebilirsin)',
              style: GoogleFonts.manrope(fontSize: 14, color: cs.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.2,
                ),
                itemCount: _symptoms.length,
                itemBuilder: (_, i) {
                  final s = _symptoms[i];
                  final isSelected = selected.contains(s.key);
                  return GestureDetector(
                    onTap: () => onToggle(s.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? s.color.withValues(alpha: 0.15)
                            : cs.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? s.color : cs.outlineVariant.withValues(alpha: 0.4),
                          width: isSelected ? 1.5 : 0.8,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Icon(s.icon, size: 18, color: isSelected ? s.color : cs.onSurfaceVariant),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                s.label,
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                  color: isSelected ? cs.onSurface : cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: onAnalyze,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text('Analiz Et', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 2: Result ────────────────────────────────────────────────────────────

class _StepResult extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<_DiagnosisIssue> issues;
  final String disclaimer;
  final ColorScheme cs;
  final VoidCallback onReset;

  const _StepResult({
    required this.loading,
    required this.error,
    required this.issues,
    required this.disclaimer,
    required this.cs,
    required this.onReset,
  });

  Color _severityColor(String severity) => switch (severity) {
    'high' => const Color(0xFFEF5350),
    'medium' => const Color(0xFFFF9800),
    _ => const Color(0xFF66BB6A),
  };

  String _severityLabel(String severity) => switch (severity) {
    'high' => 'Yüksek Risk',
    'medium' => 'Orta Risk',
    _ => 'Düşük Risk',
  };

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: cs.primary),
            const SizedBox(height: 16),
            Text('Analiz ediliyor...', style: GoogleFonts.manrope(fontSize: 16, color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 56, color: cs.error),
              const SizedBox(height: 16),
              Text(error!, style: GoogleFonts.manrope(fontSize: 15, color: cs.onSurfaceVariant), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: onReset, child: Text('Tekrar Dene', style: GoogleFonts.manrope(fontWeight: FontWeight.w700))),
            ],
          ),
        ),
      );
    }
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Analiz Sonucu',
                    style: GoogleFonts.manrope(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onReset,
                  child: Text('Yeni Analiz', style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: cs.primary)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                ...issues.map((issue) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _severityColor(issue.severity).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(issue.name,
                                style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _severityColor(issue.severity).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              _severityLabel(issue.severity),
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _severityColor(issue.severity),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(issue.description,
                          style: GoogleFonts.manrope(fontSize: 14, color: cs.onSurfaceVariant, height: 1.5)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.lightbulb_outline_rounded, size: 16, color: cs.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(issue.solution,
                                  style: GoogleFonts.manrope(fontSize: 13, color: cs.onSurface, height: 1.45)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
                if (disclaimer.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      disclaimer,
                      style: GoogleFonts.manrope(fontSize: 12, color: cs.outline, height: 1.4),
                      textAlign: TextAlign.center,
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

// ignore: unused_element
extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
