import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bn_format.dart';
import '../../cart/bloc/cart_bloc.dart';
import '../../cart/bloc/cart_state.dart';
import '../../cart/pages/cart_page.dart';
import '../../orders/pages/orders_page.dart';
import '../../profile/pages/profile_page.dart';
import '../bloc/shell_cubit.dart';
import 'home_page.dart';

/// Bottom-tab shell: হোম / অর্ডার / কার্ট / প্রোফাইল (with live cart badge).
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ShellCubit>(
      create: (BuildContext context) => ShellCubit(),
      child: const _ShellView(),
    );
  }
}

class _ShellView extends StatelessWidget {
  const _ShellView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShellCubit, int>(
      builder: (BuildContext context, int index) {
        return Scaffold(
          body: IndexedStack(
            index: index,
            children: const <Widget>[
              HomePage(),
              OrdersPage(),
              CartPage(),
              ProfilePage(),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 12,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: BlocBuilder<CartBloc, CartState>(
              buildWhen: (CartState p, CartState c) =>
                  p.totalQuantity != c.totalQuantity,
              builder: (BuildContext context, CartState cart) {
                return NavigationBar(
                  selectedIndex: index,
                  onDestinationSelected: (int value) =>
                      context.read<ShellCubit>().setIndex(value),
                  destinations: <Widget>[
                    const NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: 'হোম',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.receipt_long_outlined),
                      selectedIcon: Icon(Icons.receipt_long_rounded),
                      label: 'অর্ডার',
                    ),
                    NavigationDestination(
                      icon: _CartIcon(
                        icon: Icons.shopping_cart_outlined,
                        count: cart.totalQuantity,
                      ),
                      selectedIcon: _CartIcon(
                        icon: Icons.shopping_cart_rounded,
                        count: cart.totalQuantity,
                      ),
                      label: 'কার্ট',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.person_outline_rounded),
                      selectedIcon: Icon(Icons.person_rounded),
                      label: 'প্রোফাইল',
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _CartIcon extends StatelessWidget {
  const _CartIcon({required this.icon, required this.count});

  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return Icon(icon);
    return Badge(
      backgroundColor: AppColors.tertiary,
      label: Text(
        BnFormat.digits(count),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      child: Icon(icon),
    );
  }
}
