import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/no_internet_widget.dart';
import '../data/models/admin_order_model.dart';
import '../logic/admin_orders_cubit.dart';
import '../logic/admin_orders_state.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  String _selectedStatus = 'all';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AdminOrdersCubit>()..loadOrders(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              surfaceTintColor: AppColors.surface,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'ADMIN',
                      style: AppTextStyles.textTheme.labelSmall?.copyWith(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Orders',
                    style: AppTextStyles.textTheme.titleLarge?.copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () async {
                    await getIt<StorageService>().clearAll();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.error,
                  ),
                  tooltip: 'Logout',
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected: _selectedStatus == 'all',
                        onTap: () {
                          setState(() => _selectedStatus = 'all');
                          context.read<AdminOrdersCubit>().loadOrders();
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Pending',
                        isSelected: _selectedStatus == 'pending',
                        onTap: () {
                          setState(() => _selectedStatus = 'pending');
                          context
                              .read<AdminOrdersCubit>()
                              .loadOrders(status: 'pending');
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Confirmed',
                        isSelected: _selectedStatus == 'confirmed',
                        onTap: () {
                          setState(() => _selectedStatus = 'confirmed');
                          context
                              .read<AdminOrdersCubit>()
                              .loadOrders(status: 'confirmed');
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Completed',
                        isSelected: _selectedStatus == 'completed',
                        onTap: () {
                          setState(() => _selectedStatus = 'completed');
                          context
                              .read<AdminOrdersCubit>()
                              .loadOrders(status: 'completed');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            body: BlocBuilder<AdminOrdersCubit, AdminOrdersState>(
              builder: (context, state) {
                if (state is AdminOrdersLoading ||
                    state is AdminOrdersInitial) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGreen,
                    ),
                  );
                }

                if (state is AdminOrdersError) {
                  final isNetworkError =
                      state.message.toLowerCase().contains('internet') ||
                          state.message.toLowerCase().contains('network') ||
                          state.message.toLowerCase().contains('connection');

                  if (isNetworkError) {
                    return NoInternetWidget(
                      message: state.message,
                      onRetry: () => context.read<AdminOrdersCubit>().loadOrders(
                            status: _selectedStatus == 'all'
                                ? null
                                : _selectedStatus,
                          ),
                    );
                  }

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () =>
                                context.read<AdminOrdersCubit>().loadOrders(
                                      status: _selectedStatus == 'all'
                                          ? null
                                          : _selectedStatus,
                                    ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              foregroundColor: AppColors.surface,
                            ),
                            child: Text(
                              'Retry',
                              style:
                                  AppTextStyles.textTheme.titleSmall?.copyWith(
                                color: AppColors.surface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is AdminOrdersLoaded) {
                  if (state.orders.isEmpty) {
                    return Center(
                      child: Text(
                        'No orders found.',
                        style: AppTextStyles.textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    color: AppColors.primaryGreen,
                    onRefresh: () => context.read<AdminOrdersCubit>().loadOrders(
                          status: _selectedStatus == 'all'
                              ? null
                              : _selectedStatus,
                        ),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: state.orders.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _AdminOrderTile(
                          order: state.orders[index],
                          clientsMap: state.clientsMap,
                          locationsMap: state.locationsMap,
                        );
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.textTheme.labelLarge?.copyWith(
            color: isSelected ? AppColors.surface : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _AdminOrderTile extends StatelessWidget {
  const _AdminOrderTile({
    required this.order,
    required this.clientsMap,
    required this.locationsMap,
  });

  final AdminOrderModel order;
  final Map<String, String> clientsMap;
  final Map<String, String> locationsMap;

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.accentOrange;
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  String _short(String id) =>
      id.length >= 8 ? '#${id.substring(0, 8)}' : '#$id';

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }
    return DateFormat('MMM d').format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(order.status);
    final dateStr = _formatDate(order.createdAt);

    return InkWell(
      onTap: () => context.push('/admin/orders/${order.id}'),
      borderRadius: BorderRadius.circular(14),
      child: Material(
        color: AppColors.surface,
        elevation: 1,
        shadowColor: AppColors.textPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ──────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Order ${_short(order.id)}',
                      style: AppTextStyles.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      order.status.toUpperCase(),
                      style: AppTextStyles.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ── Client & Location row ────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _MetaChip(
                          icon: Icons.person_outline_rounded,
                          label: clientsMap[order.clientId] ??
                              'Client ${_short(order.clientId)}',
                        ),
                        _MetaChip(
                          icon: Icons.location_on_outlined,
                          label: locationsMap[order.locationId] ??
                              'Loc ${_short(order.locationId)}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateStr,
                    style: AppTextStyles.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 10),

              // ── Footer row ───────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.shopping_bag_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${order.totalLineQuantity} item${order.totalLineQuantity == 1 ? '' : 's'}',
                        style: AppTextStyles.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Rs. ${NumberFormat('#,##0', 'en_US').format(order.totalAmount)}',
                    style: AppTextStyles.textTheme.titleSmall?.copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primaryGreen),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.textTheme.labelSmall?.copyWith(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
