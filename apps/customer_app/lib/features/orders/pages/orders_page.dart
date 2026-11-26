import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../data/models/order.dart';
import '../../home/bloc/shell_cubit.dart';
import '../bloc/orders_bloc.dart';
import '../widgets/order_card.dart';

/// All orders, newest first: চলমান (live) and আগের (history) sections.
class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('আমার অর্ডার')),
      body: BlocBuilder<OrdersBloc, OrdersState>(
        builder: (BuildContext context, OrdersState state) {
          if (state.status == OrdersStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == OrdersStatus.failure) {
            return ErrorView(
              message: 'অর্ডারের তালিকা লোড করা যায়নি।',
              onRetry: () =>
                  context.read<OrdersBloc>().add(const OrdersStarted()),
            );
          }
          if (state.orders.isEmpty) {
            return EmptyState(
              emoji: '🧾',
              title: 'এখনো কোনো অর্ডার নেই',
              message: 'প্রথম অর্ডারটি করলেই এখানে লাইভ ট্র্যাকিং দেখা যাবে।',
              actionLabel: 'খাবার দেখুন',
              onAction: () {
                final ShellCubit? shell = context.read<ShellCubit?>();
                if (shell != null) {
                  shell.goHome();
                } else {
                  Navigator.of(context).maybePop();
                }
              },
            );
          }
          final List<Order> active = state.active;
          final List<Order> past = state.past;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: <Widget>[
              if (active.isNotEmpty) ...<Widget>[
                Text('চলমান অর্ডার', style: text.titleMedium),
                const SizedBox(height: 4),
                for (final Order order in active)
                  OrderCard(
                    order: order,
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRoutes.tracking,
                      arguments: order.id,
                    ),
                  ),
              ],
              if (past.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                Text('আগের অর্ডার', style: text.titleMedium),
                const SizedBox(height: 4),
                for (final Order order in past)
                  OrderCard(
                    order: order,
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRoutes.tracking,
                      arguments: order.id,
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
