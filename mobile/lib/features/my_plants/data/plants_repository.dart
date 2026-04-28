import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/di.dart';
import '../domain/user_plant.dart';
import '../../plant_scan/domain/plant_match.dart';

final plantsRepositoryProvider = Provider<PlantsRepository>((ref) {
  return PlantsRepository(ref.read(apiClientProvider).dio);
});

class PlantsRepository {
  final Dio _dio;
  PlantsRepository(this._dio);

  Future<List<UserPlant>> getPlants() async {
    final res = await _dio.get('/api/plants');
    return (res.data as List).map((j) => UserPlant.fromJson(j as Map<String, dynamic>)).toList();
  }

  /// Save a scanned plant — optionally with the user's photo.
  Future<UserPlant> savePlant(PlantMatch match, {XFile? imageFile}) async {
    final FormData formData = FormData.fromMap({
      'scientificName': match.scientificName,
      'commonName': match.commonName,
      'turkishName': match.turkishName,
      'imageUrl': match.imageUrl.isEmpty ? '' : match.imageUrl,
      'waterFrequencyDays': match.waterFrequencyDays,
      'lightRequirement': match.lightRequirement,
    });

    // Attach scanned photo if available
    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      final ext = imageFile.name.split('.').last.toLowerCase();
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
      formData.files.add(MapEntry(
        'image',
        MultipartFile.fromBytes(bytes, filename: 'plant.$ext', contentType: DioMediaType.parse(mime)),
      ));
    }

    final res = await _dio.post('/api/plants', data: formData);
    return UserPlant.fromJson(res.data as Map<String, dynamic>);
  }

  Future<UserPlant> addManualPlant({
    required String name,
    String? scientificName,
    String? nickname,
    String? location,
    int waterFrequencyDays = 7,
    String lightRequirement = 'indirect',
  }) async {
    final cleanName = name.trim();
    final cleanScientificName = scientificName?.trim();
    final res = await _dio.post('/api/plants', data: {
      'scientificName': cleanScientificName == null || cleanScientificName.isEmpty
          ? cleanName
          : cleanScientificName,
      'commonName': cleanName,
      'turkishName': cleanName,
      'nickname': nickname?.trim().isEmpty == true ? null : nickname?.trim(),
      'location': location?.trim().isEmpty == true ? null : location?.trim(),
      'waterFrequencyDays': waterFrequencyDays,
      'lightRequirement': lightRequirement,
    });
    return UserPlant.fromJson(res.data as Map<String, dynamic>);
  }

  Future<UserPlant> getPlantById(String id) async {
    final res = await _dio.get('/api/plants/$id');
    return UserPlant.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deletePlant(String id) async {
    await _dio.delete('/api/plants/$id');
  }

  /// Upload or replace a plant's photo.
  Future<UserPlant> uploadPlantPhoto(String plantId, XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final ext = imageFile.name.split('.').last.toLowerCase();
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(bytes, filename: 'photo.$ext', contentType: DioMediaType.parse(mime)),
    });
    final res = await _dio.patch('/api/plants/$plantId/photo', data: formData);
    return UserPlant.fromJson(res.data as Map<String, dynamic>);
  }
}
