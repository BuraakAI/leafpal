import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/reminders_repository.dart';
import '../domain/reminder.dart';

final remindersProvider = AsyncNotifierProvider<RemindersNotifier, List<Reminder>>(() {
  return RemindersNotifier();
});

class RemindersNotifier extends AsyncNotifier<List<Reminder>> {
  @override
  Future<List<Reminder>> build() async {
    try {
      return ref.read(remindersRepositoryProvider).getReminders();
    } catch (_) {
      return [];
    }
  }

  Future<Reminder> create({
    required String type,
    required String title,
    required DateTime dueDate,
    String? userPlantId,
  }) async {
    final repo = ref.read(remindersRepositoryProvider);
    final reminder = await repo.createReminder(
      type: type,
      title: title,
      dueDate: dueDate,
      userPlantId: userPlantId,
    );
    final current = state.valueOrNull ?? [];
    state = AsyncData([reminder, ...current]);
    return reminder;
  }

  Future<void> complete(String id) async {
    await ref.read(remindersRepositoryProvider).complete(id);
    state = AsyncData(
      (state.valueOrNull ?? []).where((r) => r.id != id).toList(),
    );
  }
}
