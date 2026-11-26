import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';

/// 6-box OTP input backed by a single invisible [TextField].
///
/// Supports keyboard typing, paste and iOS/Android SMS-code autofill
/// (`AutofillHints.oneTimeCode`) with zero extra packages.
class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    required this.length,
    required this.code,
    required this.onChanged,
    this.enabled = true,
    this.hasError = false,
    this.autofocus = true,
  });

  final int length;
  final String code;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final bool hasError;
  final bool autofocus;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.code);
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() => setState(() {});

  @override
  void didUpdateWidget(OtpInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // External clears (wrong code, resend) sync back into the field.
    if (widget.code != _controller.text) {
      _controller.text = widget.code;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int activeIndex = widget.code.length >= widget.length
        ? widget.length - 1
        : widget.code.length;
    return GestureDetector(
      onTap: widget.enabled ? () => _focusNode.requestFocus() : null,
      child: Stack(
        children: <Widget>[
          // The real (invisible) input driving everything.
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                autofocus: widget.autofocus && widget.enabled,
                keyboardType: TextInputType.number,
                maxLength: widget.length,
                autofillHints: const <String>[AutofillHints.oneTimeCode],
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: widget.onChanged,
                showCursor: false,
                cursorColor: Colors.transparent,
                enableSuggestions: false,
                autocorrect: false,
                style: const TextStyle(
                  color: Colors.transparent,
                  fontSize: 1,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
          ),
          // The visible boxes.
          Row(
            children: List<Widget>.generate(widget.length, (int index) {
              final String char = index < widget.code.length
                  ? widget.code[index]
                  : '';
              final bool isActive = widget.enabled &&
                  _focusNode.hasFocus &&
                  index == activeIndex;
              final Color borderColor = widget.hasError
                  ? AppColors.error
                  : isActive
                      ? AppColors.primary
                      : char.isNotEmpty
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : AppColors.border;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: widget.hasError
                          ? AppColors.errorSoft
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: borderColor,
                        width: isActive || widget.hasError ? 1.6 : 1,
                      ),
                    ),
                    child: Text(
                      char,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
