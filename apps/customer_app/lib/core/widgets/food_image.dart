import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../data/models/food_category.dart';

/// Soft category gradients used for offline-first food visuals.
List<Color> categoryGradient(FoodCategory category) => switch (category) {
      FoodCategory.biryani => const <Color>[Color(0xFFFEF3C7), Color(0xFFFDE68A)],
      FoodCategory.burger => const <Color>[Color(0xFFCCFBF1), Color(0xFF99F6E4)],
      FoodCategory.pizza => const <Color>[Color(0xFFFFEDD5), Color(0xFFFED7AA)],
      FoodCategory.cake => const <Color>[Color(0xFFFCE7F3), Color(0xFFFBCFE8)],
      FoodCategory.mishti => const <Color>[Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
    };

/// Food/restaurant visual.
///
/// When [imageUrl] is provided (Phase 2 API photos) it is loaded with
/// disk caching via [CachedNetworkImage]; otherwise a lightweight
/// gradient + emoji placeholder renders instantly with zero bytes —
/// the SRS slow-network strategy (QA-04).
class FoodImage extends StatelessWidget {
  const FoodImage({
    super.key,
    required this.category,
    this.imageUrl,
    this.size = 88,
    this.borderRadius = 12,
  });

  final FoodCategory category;
  final String? imageUrl;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final String? url = imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: (url != null && url.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (BuildContext context, String _) =>
                    _placeholder(),
                errorWidget:
                    (BuildContext context, String _, Object __) =>
                        _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: categoryGradient(category),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          category.emoji,
          style: TextStyle(fontSize: size * 0.45),
        ),
      ),
    );
  }
}
