import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../domain/reminder.dart';
import 'reminders_provider.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  void _prevMonth() => setState(() {
    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
  });

  void _nextMonth() => setState(() {
    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
  });

  @override
  Widget build(BuildContext context) {
    final remindersAsync = ref.watch(remindersProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: RefreshIndicator(
        color: cs.primary,
        onRefresh: () => ref.refresh(remindersProvider.future),
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryFixed.withValues(alpha: 0.7), cs.surface],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Column(
                      children: [
                        // Title + month nav
                        Row(
                          children: [
                            Text('Takvim',
                              style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.w800,
                                  color: cs.primary, letterSpacing: -0.5)),
                            const Spacer(),
                            _MonthNavButton(icon: Icons.chevron_left, onTap: _prevMonth, cs: cs),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMMM yyyy', 'tr').format(_focusedMonth),
                              style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: cs.primary),
                            ),
                            const SizedBox(width: 4),
                            _MonthNavButton(icon: Icons.chevron_right, onTap: _nextMonth, cs: cs),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Calendar grid
                        remindersAsync.when(
                          data: (reminders) => _CalendarGrid(
                            focusedMonth: _focusedMonth,
                            selectedDay: _selectedDay,
                            reminders: reminders,
                            onDayTap: (d) => setState(() => _selectedDay = d),
                            cs: cs,
                          ),
                          loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                          error: (_, __) => const SizedBox(height: 200),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Selected day header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    Container(
                      width: 4, height: 18,
                      decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(99)),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('d MMMM', 'tr').format(_selectedDay),
                      style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface),
                    ),
                  ],
                ),
              ),
            ),

            remindersAsync.when(
              data: (reminders) {
                final dayReminders = reminders.where((r) =>
                  r.dueDate.year == _selectedDay.year &&
                  r.dueDate.month == _selectedDay.month &&
                  r.dueDate.day == _selectedDay.day,
                ).toList();

                if (dayReminders.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.event_available_outlined, size: 48, color: cs.outlineVariant),
                            const SizedBox(height: 12),
                            Text('Bu gün için bakım yok',
                              style: GoogleFonts.manrope(fontSize: 15, color: cs.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _ReminderTile(reminder: dayReminders[i], cs: cs),
                      childCount: dayReminders.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('$e'))),
            ),

            // Other day reminders
            remindersAsync.when(
              data: (reminders) {
                final others = reminders.where((r) =>
                  !(r.dueDate.year == _selectedDay.year &&
                    r.dueDate.month == _selectedDay.month &&
                    r.dueDate.day == _selectedDay.day),
                ).toList();
                if (others.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

                final grouped = <String, List<Reminder>>{};
                for (final r in others) {
                  final key = DateFormat('d MMMM', 'tr').format(r.dueDate);
                  grouped.putIfAbsent(key, () => []).add(r);
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12, top: 8),
                        child: Text('Diğer günler',
                          style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700,
                              color: cs.onSurfaceVariant, letterSpacing: 0.8)),
                      ),
                      for (final entry in grouped.entries) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 6),
                          child: Text(entry.key,
                            style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600,
                                color: cs.onSurfaceVariant)),
                        ),
                        ...entry.value.map((r) => _ReminderTile(reminder: r, cs: cs)),
                      ],
                    ]),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/reminder/setup'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: Text('Ekle', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ── Month nav button ──────────────────────────────────────
class _MonthNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final ColorScheme cs;
  const _MonthNavButton({required this.icon, required this.onTap, required this.cs});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: cs.primary),
    ),
  );
}

// ── Calendar grid ───────────────────────────────────────────────
class _CalendarGrid extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime selectedDay;
  final List<Reminder> reminders;
  final ValueChanged<DateTime> onDayTap;
  final ColorScheme cs;
  const _CalendarGrid({
    required this.focusedMonth, required this.selectedDay,
    required this.reminders, required this.onDayTap, required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth = DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // 0 = Pazar
    final today = DateTime.now();

    final reminderDays = <int>{};
    final urgentDays = <int>{};
    for (final r in reminders) {
      if (r.dueDate.year == focusedMonth.year && r.dueDate.month == focusedMonth.month) {
        reminderDays.add(r.dueDate.day);
        if (r.dueDate.isBefore(today)) urgentDays.add(r.dueDate.day);
      }
    }

    const dayLabels = ['Pz', 'Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct'];

    return Column(
      children: [
        Row(
          children: dayLabels.map((d) => Expanded(
            child: Center(
              child: Text(d, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant)),
            ),
          )).toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: startWeekday + daysInMonth,
          itemBuilder: (_, i) {
            if (i < startWeekday) return const SizedBox.shrink();
            final day = i - startWeekday + 1;
            final date = DateTime(focusedMonth.year, focusedMonth.month, day);
            final isToday = date.day == today.day && date.month == today.month && date.year == today.year;
            final isSelected = date.day == selectedDay.day && date.month == selectedDay.month && date.year == selectedDay.year;
            final hasReminder = reminderDays.contains(day);
            final isUrgent = urgentDays.contains(day);

            return GestureDetector(
              onTap: () => onDayTap(date),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected ? cs.primary : isToday ? AppColors.primaryFixed.withValues(alpha: 0.5) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : isToday ? cs.primary : cs.onSurface,
                      ),
                    ),
                    if (hasReminder) ...[
                      const SizedBox(height: 1),
                      Container(
                        width: 5, height: 5,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : isUrgent ? cs.error : cs.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ── Reminder tile — premium card with vibrant button ─────────────────
class _ReminderTile extends ConsumerWidget {
  final Reminder reminder;
  final ColorScheme cs;
  const _ReminderTile({required this.reminder, required this.cs});

  Color get _typeColor => switch (reminder.type) {
    'watering' => const Color(0xFF2196F3),
    'fertilizing' => AppColors.primary,
    'repotting' => const Color(0xFF795548),
    'misting' => const Color(0xFF00ACC1),
    'pruning' => const Color(0xFF8E5CF7),
    'cleaning' => const Color(0xFFF9A825),
    'rotation' => const Color(0xFF607D8B),
    'pest_check' => const Color(0xFFD84315),
    _ => AppColors.secondary,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOverdue = reminder.dueDate.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOverdue ? cs.error.withValues(alpha: 0.4) : cs.outlineVariant.withValues(alpha: 0.25),
        ),
        boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          // Left color bar + icon
          Container(
            width: 56,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: _typeColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
            ),
            child: Center(
              child: Text(reminder.typeIcon, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reminder.title,
                    style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
                  if (reminder.plantName != null) ...[
                    const SizedBox(height: 2),
                    Text(reminder.plantName!,
                      style: GoogleFonts.manrope(fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                  if (isOverdue) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: cs.errorContainer, borderRadius: BorderRadius.circular(99)),
                      child: Text('Gecikmiş', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: cs.error)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Complete button — vibrant, premium
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: () => ref.read(remindersProvider.notifier).complete(reminder.id),
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_typeColor.withValues(alpha: 0.8), _typeColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: _typeColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: const Icon(Icons.check_rounded, size: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
