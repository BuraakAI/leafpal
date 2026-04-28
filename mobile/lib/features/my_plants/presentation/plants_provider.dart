import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../data/plants_repository.dart';
import '../domain/user_plant.dart';
import '../../plant_scan/domain/plant_match.dart';

final plantsProvider = AsyncNotifierProvider<PlantsNotifier, List<Map<String, dynamic>>>(() {
  return PlantsNotifier();
});

class PlantsNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    try {
      final repo = ref.read(plantsRepositoryProvider);
      final plants = await repo.getPlants();
      return plants.map((p) => _toMap(p)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> savePlant(PlantMatch match, {XFile? imageFile}) async {
    final repo = ref.read(plantsRepositoryProvider);
    final plant = await repo.savePlant(match, imageFile: imageFile);
    final mapped = _toMap(plant);
    final current = state.valueOrNull ?? [];
    state = AsyncData([mapped, ...current]);
    return mapped;
  }

  Future<Map<String, dynamic>?> addManualPlant({
    required String name,
    String? scientificName,
    String? nickname,
    String? location,
    required int waterFrequencyDays,
    required String lightRequirement,
  }) async {
    final repo = ref.read(plantsRepositoryProvider);
    final plant = await repo.addManualPlant(
      name: name,
      scientificName: scientificName,
      nickname: nickname,
      location: location,
      waterFrequencyDays: waterFrequencyDays,
      lightRequirement: lightRequirement,
    );
    final mapped = _toMap(plant);
    final current = state.valueOrNull ?? [];
    state = AsyncData([mapped, ...current]);
    return mapped;
  }

  Future<void> deletePlant(String id) async {
    final repo = ref.read(plantsRepositoryProvider);
    await repo.deletePlant(id);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((p) => p['id'] != id).toList());
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(plantsRepositoryProvider);
      final plants = await repo.getPlants();
      return plants.map((p) => _toMap(p)).toList();
    });
  }

  Map<String, dynamic> _toMap(UserPlant p) => {
        'id': p.id,
        'nickname': p.nickname,
        'location': p.location,
        'imageUrl': p.imageUrl,
        'addedAt': p.addedAt.toIso8601String(),
        'species': {
          'id': p.species.id,
          'scientificName': p.species.scientificName,
          'commonName': p.species.commonName,
          'turkishName': p.species.turkishName,
          'waterFrequencyDays': p.species.waterFrequencyDays,
          'lightRequirement': p.species.lightRequirement,
        },
        'carePlan': p.carePlan == null
            ? null
            : {
                'wateringDays': p.carePlan!.wateringDays,
                'fertilizingDays': p.carePlan!.fertilizingDays,
              },
      };
}
