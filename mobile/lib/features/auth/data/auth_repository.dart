import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/di.dart';
import '../../../core/utils/secure_storage.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(apiClientProvider).dio);
});

class AuthRepository {
  final Dio _dio;
  AuthRepository(this._dio);

  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final res = await _dio.post('/api/auth/login', data: {'email': email, 'password': password});
    final data = res.data as Map<String, dynamic>;
    await AppStorage.instance.write(key: 'auth_token', value: data['token'] as String);
    return data;
  }

  Future<Map<String, dynamic>> register({required String email, required String password, String? name}) async {
    final res = await _dio.post('/api/auth/register', data: {
      'email': email,
      'password': password,
      if (name != null && name.isNotEmpty) 'name': name,
    });
    final data = res.data as Map<String, dynamic>;
    await AppStorage.instance.write(key: 'auth_token', value: data['token'] as String);
    return data;
  }

  Future<Map<String, dynamic>> updateProfile({required String name}) async {
    final res = await _dio.patch('/api/auth/profile', data: {'name': name});
    return res.data as Map<String, dynamic>;
  }
}
