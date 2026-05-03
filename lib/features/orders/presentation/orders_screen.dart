import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/no_internet_widget.dart';
import '../data/models/order_model.dart';
import '../logic/order_cubit.dart';
import '../logic/order_state.dart';

String _formatRs(double value) {
  final fmt = NumberFormat('#,##0', 'en_US');
  return 'Rs. ${fmt.format(value)}';
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OrderCubit>()..loadMyOrders(),
      child: const _OrdersBody(),
    );
  }
}

class _OrdersBody extends StatelessWidget {
  const _OrdersBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Orders',
          style: AppTextStyles.textTheme.titleLarge?.copyWith(
            color: AppColors.primaryGreen,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: BlocBuilder<OrderCubit, OrderState>(
        builder: (context, state) {
          if (state is OrderLoading || state is OrderInitial) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            );
          }
          if (state is OrderFailure) {
            final isNetworkError = state.message.toLowerCase().contains('internet') ||
                state.message.toLowerCase().contains('network') ||
                state.message.toLowerCase().contains('connection');

            if (isNetworkError) {
              return NoInternetWidget(
                message: state.message,
                onRetry: () => context.read<OrderCubit>().loadMyOrders(),
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
                          context.read<OrderCubit>().loadMyOrders(),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: AppColors.surface,
                      ),
                      child: Text(
                        'Retry',
                        style: AppTextStyles.textTheme.titleSmall?.copyWith(
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
          if (state is OrdersLoaded) {
            if (state.orders.isEmpty) {
              return Center(
                child: Text(
                  'No orders yet.',
                  style: AppTextStyles.textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }
            return RefreshIndicator(
              color: AppColors.primaryGreen,
              onRefresh: () => context.read<OrderCubit>().loadMyOrders(),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: state.orders.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _OrderTile(order: state.orders[index]);
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});

  final OrderModel order;

  Color _statusColor(String status) {
    final key = status.toLowerCase();
    if (key.contains('pending')) return AppColors.accentOrange;
    if (key.contains('delivered') || key.contains('completed')) return AppColors.primaryGreen;
    if (key.contains('cancel') || key.contains('rejected')) return AppColors.error;
    return AppColors.primaryGreen;
  }

  Color _statusBackground(String status) {
    return _statusColor(status).withValues(alpha: 0.12);
  }

  void _showOrderDetail(BuildContext context) {
    final locationLabel = order.locationName?.isNotEmpty == true
        ? order.locationName!
        : order.locationId.isNotEmpty
            ? 'Loc ${order.locationId.substring(0, 8)}'
            : 'Unknown location';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order ID',
                          style: AppTextStyles.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.id,
                          style: AppTextStyles.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _statusBackground(order.status),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      order.status.toUpperCase(),
                      style: AppTextStyles.textTheme.labelSmall?.copyWith(
                        color: _statusColor(order.status),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      locationLabel,
                      style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Items',
                style: AppTextStyles.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (order.items.isEmpty)
                Text(
                  'No item details available.',
                  style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )
              else
                ...order.items.map(
                  (item) {
                    final itemTotal = item.priceAtOrder * item.quantity;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Item ${item.productId}',
                                  style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.quantity} × ${_formatRs(item.priceAtOrder)}',
                                  style: AppTextStyles.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatRs(itemTotal),
                            style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 12),
              Divider(color: AppColors.textPrimary.withValues(alpha: 0.12), thickness: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount',
                    style: AppTextStyles.textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _formatRs(order.totalAmount),
                    style: AppTextStyles.textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = order.createdAt != null
        ? DateFormat('d MMM yyyy, h:mm a').format(order.createdAt!.toLocal())
        : '—';

    final shortId = order.id.length > 8 ? order.id.substring(0, 8) : order.id;
    final statusColor = _statusColor(order.status);

    return Material(
      color: AppColors.surface,
      elevation: 1,
      shadowColor: AppColors.textPrimary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showOrderDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      shortId,
                      style: AppTextStyles.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontFamily: 'RobotoMono',
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusBackground(order.status),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      order.status.toUpperCase(),
                      style: AppTextStyles.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                dateStr,
                style: AppTextStyles.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${order.totalLineQuantity} items',
                          style: AppTextStyles.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.locationName?.isNotEmpty == true
                              ? order.locationName!
                              : 'Location ${shortId.toUpperCase()}',
                          style: AppTextStyles.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatRs(order.totalAmount),
                        style: AppTextStyles.textTheme.titleSmall?.copyWith(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ],
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
