import 'dart:convert';
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

    // HTTP durum kodu bazlı mesajlar
    final statusCode = e.response?.statusCode;
    if (statusCode != null) {
      if (statusCode == 503) return 'Sunucu geçici olarak kullanılamıyor. Lütfen tekrar deneyin.';
      if (statusCode == 502) return 'Sunucu yanıt vermiyor. Lütfen tekrar deneyin.';
      if (statusCode == 401) return 'Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.';
      if (statusCode == 403) return 'Bu işlem için yetkiniz yok.';
      if (statusCode == 429) return 'Günlük tarama hakkınız doldu.';
    }

    // Bağlantı hatası
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown) {
      return 'Sunucuya bağlanılamadı. İnternet bağlantınızı kontrol edin.';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Bağlantı zaman aşımına uğradı. Tekrar deneyin.';
    }

    // Backend'den gelen hata mesajı (String veya Map)
    final raw = e.response?.data;
    if (raw is Map) {
      final msg = raw['error']?.toString();
      if (msg != null && msg.isNotEmpty) return msg;
    } else if (raw is String && raw.isNotEmpty) {
      try {
        final parsed = jsonDecode(raw) as Map<String, dynamic>;
        final msg = parsed['error']?.toString();
        if (msg != null && msg.isNotEmpty) return msg;
      } catch (_) {
        if (raw.length < 120) return raw;
      }
    }

    return 'Bir hata oluştu (${statusCode ?? 'bağlantı yok'})';
  }
  if (e is AppException) return e.message;
  final raw = e.toString();
  return raw.startsWith('Exception: ') ? raw.substring(11) : raw;
}
