import 'package:flutter_bloc/flutter_bloc.dart';

/// Bottom-navigation index of the main shell (0 হোম, 1 অর্ডার, 2 কার্ট).
class ShellCubit extends Cubit<int> {
  ShellCubit() : super(0);

  void goHome() => emit(0);

  void goOrders() => emit(1);

  void goCart() => emit(2);

  void setIndex(int index) => emit(index);
}
