/// Menu categories shown as scrollable chips on the home screen (SRS FR-C03).
enum FoodCategory {
  biryani,
  bhuna,
  burger,
  pizza,
  snacks,
  cake,
  mishti,
  drinks,
  chinese,
}

extension FoodCategoryX on FoodCategory {
  /// Bangla chip label.
  String get labelBn => switch (this) {
        FoodCategory.biryani => 'বিরিয়ানি',
        FoodCategory.bhuna => 'ভুনা ও পোলাও',
        FoodCategory.burger => 'বার্গার',
        FoodCategory.pizza => 'পিৎজা',
        FoodCategory.snacks => 'স্ন্যাক্স ও রোল',
        FoodCategory.cake => 'বার্থডে কেক',
        FoodCategory.mishti => 'মিষ্টি ও দই',
        FoodCategory.drinks => 'ড্রিংকস',
        FoodCategory.chinese => 'চাইনিজ',
      };

  /// Lightweight offline-first visual (no image download needed on 2G).
  String get emoji => switch (this) {
        FoodCategory.biryani => '🍛',
        FoodCategory.bhuna => '🍖',
        FoodCategory.burger => '🍔',
        FoodCategory.pizza => '🍕',
        FoodCategory.snacks => '🌯',
        FoodCategory.cake => '🎂',
        FoodCategory.mishti => '🍮',
        FoodCategory.drinks => '🥤',
        FoodCategory.chinese => '🥡',
      };
}
