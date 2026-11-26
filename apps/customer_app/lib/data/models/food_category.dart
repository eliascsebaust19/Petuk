/// Menu categories shown as chips on the home screen (SRS FR-C03).
enum FoodCategory { biryani, burger, pizza, cake, mishti }

extension FoodCategoryX on FoodCategory {
  /// Bangla chip label.
  String get labelBn => switch (this) {
        FoodCategory.biryani => 'বিরিয়ানি',
        FoodCategory.burger => 'বার্গার',
        FoodCategory.pizza => 'পিৎজা',
        FoodCategory.cake => 'বার্থডে কেক',
        FoodCategory.mishti => 'মিষ্টি',
      };

  /// Lightweight offline-first visual (no image download needed on 2G).
  String get emoji => switch (this) {
        FoodCategory.biryani => '🍛',
        FoodCategory.burger => '🍔',
        FoodCategory.pizza => '🍕',
        FoodCategory.cake => '🎂',
        FoodCategory.mishti => '🍮',
      };
}
