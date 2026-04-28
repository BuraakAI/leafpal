import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/di.dart';
import '../domain/plant_match.dart';

final scanRepositoryProvider = Provider<ScanRepository>((ref) {
  return ScanRepository(ref.read(apiClientProvider).dio);
});

class ScanRepository {
  final Dio _dio;
  ScanRepository(this._dio);

  // XFile kullanıyoruz — hem web hem mobilde çalışır
  Future<List<PlantMatch>> scan(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final ext = imageFile.name.split('.').last.toLowerCase();
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';

    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(bytes, filename: 'scan.$ext', contentType: DioMediaType.parse(mime)),
    });

    final response = await _dio.post('/api/plant-identification/scan', data: formData);
    return (response.data['matches'] as List)
        .map((m) => PlantMatch.fromJson(m as Map<String, dynamic>))
        .toList();
  }
}
