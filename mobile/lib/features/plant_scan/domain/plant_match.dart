class PlantMatch {
  final String scientificName;
  final String commonName;
  final String turkishName;
  final double confidence;
  final String imageUrl;
  final String description;
  final int waterFrequencyDays;
  final String lightRequirement;

  const PlantMatch({
    required this.scientificName,
    required this.commonName,
    required this.turkishName,
    required this.confidence,
    required this.imageUrl,
    required this.description,
    required this.waterFrequencyDays,
    required this.lightRequirement,
  });

  factory PlantMatch.fromJson(Map<String, dynamic> json) => PlantMatch(
        scientificName: json['scientificName'] as String,
        commonName: json['commonName'] as String,
        turkishName: json['turkishName'] as String? ?? json['commonName'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        imageUrl: json['imageUrl'] as String? ?? '',
        description: json['description'] as String? ?? '',
        waterFrequencyDays: json['waterFrequencyDays'] as int? ?? 7,
        lightRequirement: json['lightRequirement'] as String? ?? 'indirect',
      );
}
