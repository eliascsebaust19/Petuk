import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/food_category.dart';

/// Horizontal scrollable category chips with mouse-wheel & arrow support
/// so both mobile touch and desktop/web mice scroll smoothly.
class CategoryChips extends StatefulWidget {
  const CategoryChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  /// null = "সব".
  final FoodCategory? selected;
  final ValueChanged<FoodCategory?> onSelected;

  @override
  State<CategoryChips> createState() => _CategoryChipsState();
}

class _CategoryChipsState extends State<CategoryChips> {
  final ScrollController _scrollController = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_syncScrollButtons);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncScrollButtons());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_syncScrollButtons)
      ..dispose();
    super.dispose();
  }

  void _syncScrollButtons() {
    if (!mounted || !_scrollController.hasClients) return;
    final ScrollPosition pos = _scrollController.position;
    final bool left = pos.pixels > 4;
    final bool right = pos.pixels < pos.maxScrollExtent - 4;
    if (left != _canScrollLeft || right != _canScrollRight) {
      setState(() {
        _canScrollLeft = left;
        _canScrollRight = right;
      });
    }
  }

  void _scrollBy(double delta) {
    if (!_scrollController.hasClients) return;
    final ScrollPosition pos = _scrollController.position;
    final double target =
        (pos.pixels + delta).clamp(0.0, pos.maxScrollExtent);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Listener(
            onPointerSignal: (PointerSignalEvent event) {
              if (event is PointerScrollEvent &&
                  _scrollController.hasClients) {
                final double delta = event.scrollDelta.dy != 0
                    ? event.scrollDelta.dy
                    : event.scrollDelta.dx;
                final double next = (_scrollController.offset + delta).clamp(
                  0.0,
                  _scrollController.position.maxScrollExtent,
                );
                _scrollController.jumpTo(next);
              }
            },
            child: NotificationListener<ScrollMetricsNotification>(
              onNotification: (ScrollMetricsNotification _) {
                _syncScrollButtons();
                return false;
              },
              child: ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: FoodCategory.values.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (BuildContext context, int index) {
                  final FoodCategory? category =
                      index == 0 ? null : FoodCategory.values[index - 1];
                  final bool isSelected = widget.selected == category;
                  final String label = category == null
                      ? '🍽️ সব'
                      : '${category.emoji} ${category.labelBn}';
                  return Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => widget.onSelected(category),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: <Color>[
                                    AppColors.primary,
                                    AppColors.secondary,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isSelected
                              ? null
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border.withValues(alpha: 0.7),
                          ),
                          boxShadow: isSelected
                              ? const <BoxShadow>[
                                  BoxShadow(
                                    color: AppColors.tealGlow,
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ]
                              : const <BoxShadow>[
                                  BoxShadow(
                                    color: AppColors.cardShadow,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : AppColors.slate60,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (_canScrollLeft)
            Positioned(
              left: 4,
              child: _ScrollArrowButton(
                icon: Icons.chevron_left_rounded,
                onTap: () => _scrollBy(-180),
              ),
            ),
          if (_canScrollRight)
            Positioned(
              right: 4,
              child: _ScrollArrowButton(
                icon: Icons.chevron_right_rounded,
                onTap: () => _scrollBy(180),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScrollArrowButton extends StatelessWidget {
  const _ScrollArrowButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface.withValues(alpha: 0.95),
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: 20, color: AppColors.primaryDark),
        ),
      ),
    );
  }
}
