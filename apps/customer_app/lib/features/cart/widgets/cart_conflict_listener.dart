import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/router/app_router.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';

/// App-level listener mounted in `MaterialApp.builder`:
///
/// 1. `pendingAddition` → shows the SRS QA-02 dialog ("কার্ট খালি করে
///    নতুন রেস্তোরাঁর খাবার যোগ করবেন?") from ANY screen — home, menu,
///    detail sheet — and dispatches the user's decision back to the bloc.
/// 2. `notice` → one-shot snackbar (coupon feedback etc.).
class CartConflictListener extends StatelessWidget {
  const CartConflictListener({super.key, required this.child});

  final Widget child;

  Future<void> _showConflictDialog(
    CartBloc cartBloc,
    CartState state,
  ) async {
    final BuildContext? navigatorContext =
        AppRouter.navigatorKey.currentContext;
    if (navigatorContext == null) {
      cartBloc.add(const CartAdditionCancelled());
      return;
    }
    final bool? confirmed = await showDialog<bool>(
      context: navigatorContext,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('নতুন রেস্তোরাঁর অর্ডার?'),
        content: Text(
          'আপনার কার্টে "${state.restaurantName}"-এর খাবার আছে। '
          '"${state.pendingAddition!.restaurantName}" থেকে অর্ডার করতে '
          'চাইলে আগের কার্টটি খালি করতে হবে।',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('খালি করে যোগ করুন'),
          ),
        ],
      ),
    );
    cartBloc.add(
      confirmed == true
          ? const CartAdditionConfirmed()
          : const CartAdditionCancelled(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CartBloc, CartState>(
      listenWhen: (CartState previous, CartState current) =>
          (current.pendingAddition != null &&
              previous.pendingAddition == null) ||
          (current.notice != null && current.notice != previous.notice),
      listener: (BuildContext context, CartState state) {
        if (state.notice != null) {
          AppRouter.scaffoldMessengerKey.currentState
            ?..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.notice!),
                duration: const Duration(seconds: 2),
              ),
            );
          context.read<CartBloc>().add(const CartNoticeCleared());
        }
        if (state.pendingAddition != null) {
          _showConflictDialog(context.read<CartBloc>(), state);
        }
      },
      child: child,
    );
  }
}
