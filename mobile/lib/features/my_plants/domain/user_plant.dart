class UserPlant {
  final String id;
  final String speciesId;
  final String? nickname;
  final String? location;
  final String? imageUrl;
  final String? notes;
  final DateTime addedAt;
  final PlantSpecies species;
  final CarePlan? carePlan;

  const UserPlant({
    required this.id,
    required this.speciesId,
    this.nickname,
    this.location,
    this.imageUrl,
    this.notes,
    required this.addedAt,
    required this.species,
    this.carePlan,
  });

  String get displayName => nickname ?? species.turkishName ?? species.commonName;

  factory UserPlant.fromJson(Map<String, dynamic> json) => UserPlant(
        id: json['id'] as String,
        speciesId: json['speciesId'] as String,
        nickname: json['nickname'] as String?,
        location: json['location'] as String?,
        imageUrl: json['imageUrl'] as String?,
        notes: json['notes'] as String?,
        addedAt: DateTime.parse(json['addedAt'] as String),
        species: PlantSpecies.fromJson(json['species'] as Map<String, dynamic>),
        carePlan: json['carePlan'] != null
            ? CarePlan.fromJson(json['carePlan'] as Map<String, dynamic>)
            : null,
      );
}

class PlantSpecies {
  final String id;
  final String scientificName;
  final String commonName;
  final String? turkishName;
  final String? description;
  final int waterFrequencyDays;
  final String lightRequirement;
  final String humidityLevel;
  final String? imageUrl;
  final String? origin;
  final String? family;
  final String? funFact;
  final String? difficulty;

  const PlantSpecies({
    required this.id,
    required this.scientificName,
    required this.commonName,
    this.turkishName,
    this.description,
    required this.waterFrequencyDays,
    required this.lightRequirement,
    required this.humidityLevel,
    this.imageUrl,
    this.origin,
    this.family,
    this.funFact,
    this.difficulty,
  });

  factory PlantSpecies.fromJson(Map<String, dynamic> json) => PlantSpecies(
        id: json['id'] as String,
        scientificName: json['scientificName'] as String,
        commonName: json['commonName'] as String,
        turkishName: json['turkishName'] as String?,
        description: json['description'] as String?,
        waterFrequencyDays: json['waterFrequencyDays'] as int? ?? 7,
        lightRequirement: json['lightRequirement'] as String? ?? 'indirect',
        humidityLevel: json['humidityLevel'] as String? ?? 'medium',
        imageUrl: json['imageUrl'] as String?,
        origin: json['origin'] as String?,
        family: json['family'] as String?,
        funFact: json['funFact'] as String?,
        difficulty: json['difficulty'] as String?,
      );
}

class CarePlan {
  final String id;
  final int wateringDays;
  final int fertilizingDays;
  final int repottingDays;
  final String? notes;

  const CarePlan({
    required this.id,
    required this.wateringDays,
    required this.fertilizingDays,
    required this.repottingDays,
    this.notes,
  });

  factory CarePlan.fromJson(Map<String, dynamic> json) => CarePlan(
        id: json['id'] as String,
        wateringDays: json['wateringDays'] as int? ?? 7,
        fertilizingDays: json['fertilizingDays'] as int? ?? 30,
        repottingDays: json['repottingDays'] as int? ?? 365,
        notes: json['notes'] as String?,
      );
}
