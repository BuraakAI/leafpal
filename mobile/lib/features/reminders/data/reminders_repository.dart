import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/di.dart';
import '../domain/reminder.dart';

final remindersRepositoryProvider = Provider<RemindersRepository>((ref) {
  return RemindersRepository(ref.read(apiClientProvider).dio);
});

class RemindersRepository {
  final Dio _dio;
  RemindersRepository(this._dio);

  Future<List<Reminder>> getReminders() async {
    final res = await _dio.get('/api/reminders');
    return (res.data as List).map((j) => Reminder.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<Reminder> createReminder({
    required String type,
    required String title,
    required DateTime dueDate,
    String? userPlantId,
  }) async {
    final res = await _dio.post('/api/reminders', data: {
      'type': type,
      'title': title,
      'dueDate': dueDate.toIso8601String(),
      if (userPlantId != null) 'userPlantId': userPlantId,
    });
    return Reminder.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> complete(String id) async {
    await _dio.patch('/api/reminders/$id/complete');
  }
}
