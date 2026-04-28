import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/error/app_exception.dart';
import '../data/scan_repository.dart';
import '../domain/plant_match.dart';

sealed class ScanState {
  const ScanState();
}

class ScanIdle extends ScanState {
  const ScanIdle();
}

class ScanLoading extends ScanState {
  const ScanLoading();
}

class ScanSuccess extends ScanState {
  final List<PlantMatch> matches;
  final String? scanId;
  const ScanSuccess(this.matches, {this.scanId});
}

class ScanError extends ScanState {
  final String message;
  const ScanError(this.message);
}

final scanProvider = StateNotifierProvider<ScanNotifier, ScanState>((ref) {
  return ScanNotifier(ref.read(scanRepositoryProvider));
});

class ScanNotifier extends StateNotifier<ScanState> {
  final ScanRepository _repo;
  ScanNotifier(this._repo) : super(const ScanIdle());

  Future<void> scanImage(XFile image) async {
    state = const ScanLoading();
    try {
      // Minimum 4.5 sn — animasyon eksiksiz görünsün
      final results = await Future.wait<dynamic>([
        _repo.scan(image),
        Future<void>.delayed(const Duration(milliseconds: 4500)),
      ]);
      final matches = results[0] as List<PlantMatch>;
      state = ScanSuccess(matches);
    } catch (e) {
      state = ScanError(parseApiError(e));
    }
  }

  void reset() => state = const ScanIdle();
}
