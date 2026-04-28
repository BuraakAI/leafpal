import 'package:dio/dio.dart';

class AppException implements Exception {
  final String message;
  final int? statusCode;
  const AppException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// DioException veya AppException'dan okunabilir Türkçe mesaj çıkarır.
String parseApiError(Object e) {
  if (e is DioException) {
    // Interceptor'ın sardığı AppException
    final inner = e.error;
    if (inner is AppException) return inner.message;

    // Bağlantı hatası
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown) {
      return 'Sunucuya bağlanılamadı. Backend çalışıyor mu?';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Bağlantı zaman aşımına uğradı. Tekrar deneyin.';
    }

    // HTTP durum kodu mesajı
    final serverMsg = e.response?.data?['error'] as String?;
    if (serverMsg != null && serverMsg.isNotEmpty) return serverMsg;

    return 'Bir ağ hatası oluştu (${e.response?.statusCode ?? 'bağlantı yok'})';
  }
  if (e is AppException) return e.message;
  final raw = e.toString();
  return raw.startsWith('Exception: ') ? raw.substring(11) : raw;
}
