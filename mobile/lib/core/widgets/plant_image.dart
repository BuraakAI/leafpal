import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../constants/api_constants.dart';

const _speciesImageMap = <String, String>{
  'monstera deliciosa': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f6/Monstera_deliciosa2.jpg/480px-Monstera_deliciosa2.jpg',
  'ficus lyrata': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Ficus_lyrata_%28Tenerife%29.jpg/480px-Ficus_lyrata_%28Tenerife%29.jpg',
  'epipremnum aureum': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9b/Epipremnum_aureum_31082012.jpg/480px-Epipremnum_aureum_31082012.jpg',
  'spathiphyllum': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/bd/Spathiphyllum_cochlearispathum_RTBG.jpg/480px-Spathiphyllum_cochlearispathum_RTBG.jpg',
  'sansevieria trifasciata': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fb/Snake_Plant_%28Sansevieria_trifasciata_%27Laurentii%27%29.jpg/480px-Snake_Plant_%28Sansevieria_trifasciata_%27Laurentii%27%29.jpg',
  'dracaena trifasciata': 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fb/Snake_Plant_%28Sansevieria_trifasciata_%27Laurentii%27%29.jpg/480px-Snake_Plant_%28Sansevieria_trifasciata_%27Laurentii%27%29.jpg',
  'ficus elastica': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/78/Ficus_elastica_-_K%C3%B6ln_-_Botanischer_Garten_-_0001.jpg/480px-Ficus_elastica_-_K%C3%B6ln_-_Botanischer_Garten_-_0001.jpg',
  'aloe vera': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/Aloe_vera_flower_inset.png/480px-Aloe_vera_flower_inset.png',
  'chlorophytum comosum': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/bf/Chlorophytum_comosum_%270Vittatum%27.jpg/480px-Chlorophytum_comosum_%270Vittatum%27.jpg',
  'pothos': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9b/Epipremnum_aureum_31082012.jpg/480px-Epipremnum_aureum_31082012.jpg',
  'philodendron': 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/00/Philodendron_hederaceum_var_oxycardium.jpg/480px-Philodendron_hederaceum_var_oxycardium.jpg',
  'calathea': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6b/Calathea_ornata.jpg/480px-Calathea_ornata.jpg',
  'peace lily': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/bd/Spathiphyllum_cochlearispathum_RTBG.jpg/480px-Spathiphyllum_cochlearispathum_RTBG.jpg',
  'zantedeschia': 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5b/White_Calla_Lily.jpg/480px-White_Calla_Lily.jpg',
};

String? fallbackImageUrl(String? scientificName) {
  if (scientificName == null) return null;
  final lower = scientificName.toLowerCase();
  for (final entry in _speciesImageMap.entries) {
    if (lower.contains(entry.key)) return entry.value;
  }
  final genus = lower.split(' ').first;
  for (final entry in _speciesImageMap.entries) {
    if (entry.key.startsWith(genus)) return entry.value;
  }
  return null;
}

class PlantImage extends StatelessWidget {
  final String? imageUrl;
  final String? scientificName;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;

  const PlantImage({
    super.key,
    this.imageUrl,
    this.scientificName,
    this.width,
    this.height,
    this.borderRadius = 16,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final url = _resolveUrl();

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: url != null
          ? CachedNetworkImage(
              imageUrl: url,
              width: width,
              height: height,
              fit: fit,
              placeholder: (_, __) => _GradientPlaceholder(scientificName: scientificName, width: width, height: height),
              errorWidget: (_, __, ___) => _GradientPlaceholder(scientificName: scientificName, width: width, height: height),
            )
          : _GradientPlaceholder(scientificName: scientificName, width: width, height: height),
    );
  }

  String? _resolveUrl() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      // Relative upload paths → prepend backend base URL
      if (imageUrl!.startsWith('/uploads/')) {
        return '${ApiConstants.baseUrl}$imageUrl';
      }
      return imageUrl;
    }
    return fallbackImageUrl(scientificName);
  }
}

class _GradientPlaceholder extends StatelessWidget {
  final String? scientificName;
  final double? width;
  final double? height;

  const _GradientPlaceholder({this.scientificName, this.width, this.height});

  List<Color> _colors() {
    final palettes = [
      [const Color(0xFFD8F3DC), const Color(0xFFB7E4C7)],
      [const Color(0xFFCCE3DE), const Color(0xFFA2C4C9)],
      [const Color(0xFFD4E8C2), const Color(0xFFB5CCAD)],
      [const Color(0xFFE8F4EA), const Color(0xFFD0E8D4)],
      [const Color(0xFFE2EDDB), const Color(0xFFC5DCBA)],
    ];
    final idx = (scientificName?.hashCode ?? 0).abs() % palettes.length;
    return palettes[idx];
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colors();

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: 0.42,
            child: Image.asset(
              'assets/images/devetabani.webp',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.08),
                  AppColors.primary.withValues(alpha: 0.22),
                ],
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.eco_rounded,
              size: (height ?? 80) * 0.22,
              color: AppColors.primary.withValues(alpha: 0.38),
            ),
          ),
        ],
      ),
    );
  }
}
