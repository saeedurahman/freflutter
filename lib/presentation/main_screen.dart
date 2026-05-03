import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../core/di/injection.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../features/orders/data/models/order_model.dart';
import '../features/orders/logic/order_cubit.dart';
import '../features/orders/logic/order_state.dart';
import '../features/orders/presentation/orders_screen.dart';
import '../features/products/logic/products_cubit.dart';
import '../features/profile/logic/profile_cubit.dart';
import '../features/profile/logic/profile_state.dart';
import '../features/products/presentation/products_screen.dart';
import '../features/profile/presentation/profile_screen.dart';

String _formatRs(double value) {
  final fmt = NumberFormat('#,##0', 'en_US');
  return 'Rs. ${fmt.format(value)}';
}

class MainScreen extends StatefulWidget {
  const MainScreen({
    this.initialTabIndex = 0,
    super.key,
  });

  final int initialTabIndex;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialTabIndex.clamp(0, 3);
  }

  @override
  void didUpdateWidget(MainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTabIndex != widget.initialTabIndex) {
      _index = widget.initialTabIndex.clamp(0, 3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final profileState = context.watch<ProfileCubit>().state;
    final orderState = context.watch<OrderCubit>().state;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _index,
        children: [
          _HomeTab(
            onTabSelected: (i) => setState(() => _index = i),
            profileState: profileState,
            orderState: orderState,
          ),
          BlocProvider(
            create: (_) => getIt<ProductsCubit>()..loadProducts(),
            child: const ProductsScreen(),
          ),
          _OrdersTab(),
          _ProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        height: 72,
        elevation: 8,
        shadowColor: AppColors.textPrimary.withValues(alpha: 0.08),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryGreen.withValues(alpha: 0.18),
        selectedIndex: _index,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
              color: scheme.onSurfaceVariant,
            ),
            selectedIcon: const Icon(
              Icons.home_rounded,
              color: AppColors.primaryGreen,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.grid_view_outlined,
              color: scheme.onSurfaceVariant,
            ),
            selectedIcon: const Icon(
              Icons.grid_view_rounded,
              color: AppColors.primaryGreen,
            ),
            label: 'Products',
          ),
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
              Icons.person_outline_rounded,
              color: scheme.onSurfaceVariant,
            ),
            selectedIcon: const Icon(
              Icons.person_rounded,
              color: AppColors.primaryGreen,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.onTabSelected,
    required this.profileState,
    required this.orderState,
  });

  final void Function(int) onTabSelected;
  final ProfileState profileState;
  final OrderState orderState;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = profileState is ProfileLoaded ? (profileState as ProfileLoaded).user : null;
    final orders = orderState is OrdersLoaded ? (orderState as OrdersLoaded).orders : <OrderModel>[];
    final pendingOrders = orders
        .where((order) => order.status.toLowerCase().contains('pend'))
        .length;
    final recentOrders = orders.take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryGreen,
          onRefresh: () async {
            await Future.wait([
              context.read<OrderCubit>().loadMyOrders(),
              context.read<ProfileCubit>().loadProfile(),
            ]);
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_greeting()}, ${user?.name?.split(' ').first ?? 'there'}! 👋',
                        style: AppTextStyles.textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Here is your dashboard for today.',
                        style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Orders',
                          value: '${orders.length}',
                          icon: Icons.shopping_bag_rounded,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Pending',
                          value: '$pendingOrders',
                          icon: Icons.hourglass_bottom_rounded,
                          color: AppColors.accentOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: AppTextStyles.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.grid_view_rounded,
                              label: 'Browse\nProducts',
                              color: AppColors.primaryGreen,
                              onTap: () => onTabSelected(1),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.receipt_long_rounded,
                              label: 'My\nOrders',
                              color: AppColors.accentOrange,
                              onTap: () => onTabSelected(2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.person_rounded,
                              label: 'My\nProfile',
                              color: AppColors.primaryGreenDark,
                              onTap: () => onTabSelected(3),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Text(
                    'Recent Orders',
                    style: AppTextStyles.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (recentOrders.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Text(
                          'No recent orders yet. Place an order to see it here.',
                          style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final order = recentOrders[index];
                      final dateStr = order.createdAt != null
                          ? DateFormat('d MMM yyyy, h:mm a')
                              .format(order.createdAt!.toLocal())
                          : '—';
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                        child: Material(
                          color: AppColors.surface,
                          elevation: 1,
                          shadowColor: AppColors.textPrimary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => onTabSelected(2),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          order.id.length > 8
                                              ? order.id.substring(0, 8)
                                              : order.id,
                                          style: AppTextStyles.textTheme.bodySmall?.copyWith(
                                            color: AppColors.textSecondary,
                                            fontFamily: 'RobotoMono',
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          dateStr,
                                          style: AppTextStyles.textTheme.bodySmall?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryGreen.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                order.status.toUpperCase(),
                                                style: AppTextStyles.textTheme.labelSmall?.copyWith(
                                                  color: AppColors.primaryGreen,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              '${order.totalLineQuantity} items',
                                              style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _formatRs(order.totalAmount),
                                        style: AppTextStyles.textTheme.titleMedium?.copyWith(
                                          color: AppColors.primaryGreen,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 16,
                                        color: AppColors.textSecondary,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: recentOrders.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: AppTextStyles.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 2,
      shadowColor: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 16),
              Text(
                label,
                style: AppTextStyles.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context) {
    return const OrdersScreen();
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return const ProfileScreen();
  }
}
