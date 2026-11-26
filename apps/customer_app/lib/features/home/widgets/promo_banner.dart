import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';

class _Promo {
  const _Promo({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.colors,
    this.code,
    this.darkText = false,
  });

  final String title;
  final String subtitle;
  final String emoji;
  final List<Color> colors;
  final String? code;
  final bool darkText;
}

/// Swipeable launch-offer banners (marketing plan §7). Tapping a coupon
/// banner copies its code; the cake banner jumps to the cake category.
class PromoBanner extends StatefulWidget {
  const PromoBanner({super.key, this.onCakeTap});

  final VoidCallback? onCakeTap;

  @override
  State<PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends State<PromoBanner> {
  final PageController _controller =
      PageController(viewportFraction: 0.94);
  int _index = 0;

  static const List<_Promo> _promos = <_Promo>[
    _Promo(
      title: 'প্রথম অর্ডারে ফ্রি ডেলিভারি!',
      subtitle: 'বীরগঞ্জ পৌর এলাকায় ৩০–৪৫ মিনিটে',
      emoji: '🎉',
      colors: <Color>[AppColors.primaryDark, AppColors.primary],
      code: 'FIRSTFREE',
    ),
    _Promo(
      title: '৳৪০ ফ্ল্যাট ছাড়',
      subtitle: 'ন্যূনতম ৳১৫০ অর্ডারে',
      emoji: '🍔',
      colors: <Color>[Color(0xFFF59E0B), Color(0xFFFBBF24)],
      code: 'WELCOME40',
      darkText: true,
    ),
    _Promo(
      title: 'বাথডে কেক পৌঁছে যাবে ঘরেই',
      subtitle: 'ক্যান্ডেল, ছুরি ও উইশিং কার্ড ফ্রি',
      emoji: '🎂',
      colors: <Color>[Color(0xFFEC4899), Color(0xFFF472B6)],
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onTap(_Promo promo) async {
    final String? code = promo.code;
    if (code != null) {
      await Clipboard.setData(ClipboardData(text: code));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'কুপন কোড "$code" কপি হয়েছে — কার্টে ব্যবহার করুন',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      widget.onCakeTap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      children: <Widget>[
        SizedBox(
          height: 124,
          child: PageView.builder(
            controller: _controller,
            itemCount: _promos.length,
            onPageChanged: (int index) => setState(() => _index = index),
            itemBuilder: (BuildContext context, int index) {
              final _Promo promo = _promos[index];
              final Color foreground =
                  promo.darkText ? AppColors.slate : Colors.white;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Material(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _onTap(promo),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: promo.colors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    promo.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: text.titleMedium?.copyWith(
                                      color: foreground,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    promo.subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: text.bodySmall?.copyWith(
                                      color: foreground.withValues(
                                        alpha: 0.85,
                                      ),
                                    ),
                                  ),
                                  if (promo.code != null) ...<Widget>[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: foreground.withValues(
                                          alpha: 0.18,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'কোড: ${promo.code} • ট্যাপ করে কপি',
                                        style:
                                            text.labelSmall?.copyWith(
                                          color: foreground,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              promo.emoji,
                              style: const TextStyle(fontSize: 42),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(_promos.length, (int index) {
            final bool active = index == _index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}
