import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../app/di.dart';

class TrialStatus {
  final bool isTrialAccepted;
  final bool isPremium;
  final int trialDaysLeft;
  final bool trialExpired;
  final int scansRemainingToday;
  final bool canScan;

  const TrialStatus({
    required this.isTrialAccepted,
    required this.isPremium,
    required this.trialDaysLeft,
    required this.trialExpired,
    required this.scansRemainingToday,
    required this.canScan,
  });

  factory TrialStatus.fromJson(Map<String, dynamic> json) => TrialStatus(
        isTrialAccepted: json['isTrialAccepted'] as bool? ?? false,
        isPremium: json['isPremium'] as bool? ?? false,
        trialDaysLeft: json['trialDaysLeft'] as int? ?? 0,
        trialExpired: json['trialExpired'] as bool? ?? true,
        scansRemainingToday: json['scansRemainingToday'] as int? ?? 0,
        canScan: json['canScan'] as bool? ?? false,
      );

  // Yeni kayıt — trial henüz kabul edilmemiş
  static const initial = TrialStatus(
    isTrialAccepted: false,
    isPremium: false,
    trialDaysLeft: 3,
    trialExpired: false,
    scansRemainingToday: 2,
    canScan: false,
  );

  String get scanBadge => isPremium ? '∞' : '$scansRemainingToday';
  String get trialLabel {
    if (isPremium) return 'Premium';
    if (trialExpired) return 'Süre Doldu';
    return '$trialDaysLeft gün kaldı';
  }
}

final trialProvider = StateNotifierProvider<TrialNotifier, TrialStatus>((ref) {
  return TrialNotifier(ref.read(apiClientProvider).dio);
});

class TrialNotifier extends StateNotifier<TrialStatus> {
  final Dio _dio;
  TrialNotifier(this._dio) : super(TrialStatus.initial);

  Future<void> fetchStatus() async {
    try {
      final res = await _dio.get('/api/auth/me');
      state = TrialStatus.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {}
  }

  Future<bool> acceptTrial() async {
    try {
      final res = await _dio.post('/api/auth/trial/accept');
      state = TrialStatus.fromJson(res.data as Map<String, dynamic>);
      return true;
    } catch (_) {
      return false;
    }
  }

  void updateFromLogin(Map<String, dynamic> trialJson) {
    state = TrialStatus.fromJson(trialJson);
  }

  Future<void> refresh() async {
    try {
      final res = await _dio.get('/api/auth/me');
      state = TrialStatus.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {}
  }
}
