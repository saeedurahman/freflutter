import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'admin_clients_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_products_screen.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({
    this.initialTabIndex = 0,
    super.key,
  });

  final int initialTabIndex;

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialTabIndex;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _index,
        children: const [
          AdminOrdersScreen(),
          AdminProductsScreen(),
          AdminClientsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryGreen.withValues(alpha: 0.18),
        selectedIndex: _index,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: [
          NavigationDestination(
            icon: Icon(
              Icons.receipt_long_outlined,
              color: scheme.onSurfaceVariant,
            ),
            selectedIcon: const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.primaryGreen,
            ),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.inventory_2_outlined,
              color: scheme.onSurfaceVariant,
            ),
            selectedIcon: const Icon(
              Icons.inventory_2_rounded,
              color: AppColors.primaryGreen,
            ),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.people_outline_rounded,
              color: scheme.onSurfaceVariant,
            ),
            selectedIcon: const Icon(
              Icons.people_rounded,
              color: AppColors.primaryGreen,
            ),
            label: 'Clients',
          ),
        ],
      ),
    );
  }
}
