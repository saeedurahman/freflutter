import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/no_internet_widget.dart';
import '../data/models/admin_order_model.dart';
import '../data/repositories/admin_order_repository.dart';
import '../logic/admin_orders_cubit.dart';
import '../logic/admin_orders_state.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  const AdminOrderDetailScreen({required this.orderId, super.key});
  final String orderId;

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  AdminOrderModel? _order;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = getIt<AdminOrderRepository>();
      final order = await repo.getOrderById(widget.orderId);
      if (mounted) {
        setState(() {
          _order = order;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

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

  String _formatRs(double value) {
    return 'Rs. ${NumberFormat('#,##0', 'en_US').format(value)}';
  }

  String _short(String id) =>
      id.length >= 8 ? '#${id.substring(0, 8)}' : '#$id';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AdminOrdersCubit>(),
      child: Builder(builder: (context) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            surfaceTintColor: AppColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Order #${widget.orderId.length > 8 ? widget.orderId.substring(0, 8) : widget.orderId}',
              style: AppTextStyles.textTheme.titleLarge?.copyWith(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: _buildBody(context),
          bottomNavigationBar: _order != null ? _buildBottomActions(context) : null,
        );
      }),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      );
    }
    if (_error != null) {
      final isNetwork = _error!.toLowerCase().contains('internet') ||
          _error!.toLowerCase().contains('network') ||
          _error!.toLowerCase().contains('connection');
      if (isNetwork) {
        return NoInternetWidget(
          message: _error!,
          onRetry: _load,
        );
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    final order = _order!;
    final dateStr = order.createdAt != null
        ? DateFormat('MMM d, yyyy · HH:mm').format(order.createdAt!.toLocal())
        : '—';

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Material(
              color: AppColors.surface,
              elevation: 1,
              shadowColor: AppColors.textPrimary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Details',
                      style: AppTextStyles.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _InfoRow('Order ID', _short(order.id)),
                    const SizedBox(height: 12),
                    _InfoRow('Client', _short(order.clientId)),
                    const SizedBox(height: 12),
                    _InfoRow('Location', _short(order.locationId)),
                    const SizedBox(height: 12),
                    _InfoRow('Date', dateStr),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Status',
                          style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(order.status)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            order.status.toUpperCase(),
                            style: AppTextStyles.textTheme.labelSmall?.copyWith(
                              color: _getStatusColor(order.status),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Items (${order.totalLineQuantity})',
              style: AppTextStyles.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = order.items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: AppColors.surface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: AppColors.divider.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Product ID: ${item.productId}',
                                  style: AppTextStyles.textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Qty: ${item.quantity}',
                                  style: AppTextStyles.textTheme.bodySmall
                                      ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatRs(item.priceAtOrder * item.quantity),
                            style: AppTextStyles.textTheme.titleMedium?.copyWith(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              childCount: order.items.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: Material(
              color: AppColors.surface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.divider),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount',
                      style: AppTextStyles.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _formatRs(order.totalAmount),
                      style: AppTextStyles.textTheme.titleLarge?.copyWith(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return BlocConsumer<AdminOrdersCubit, AdminOrdersState>(
      listener: (context, state) {
        if (state is AdminOrderStatusUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Status updated successfully')),
          );
          _load(); // refresh order
        } else if (state is AdminOrdersError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final loading = state is AdminOrderStatusUpdating;
        final order = _order!;
        
        String? nextStatus;
        String buttonText = '';
        Color buttonColor = AppColors.primaryGreen;

        if (order.status == 'pending') {
          nextStatus = 'confirmed';
          buttonText = 'Confirm Order';
          buttonColor = Colors.blue;
        } else if (order.status == 'confirmed') {
          nextStatus = 'completed';
          buttonText = 'Mark Completed';
          buttonColor = AppColors.success;
        }

        if (nextStatus == null) {
          return Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              child: FilledButton(
                onPressed: null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.divider,
                  foregroundColor: AppColors.textSecondary,
                  minimumSize: const Size.fromHeight(56),
                ),
                child: const Text('Order Completed'),
              ),
            ),
          );
        }

        return Container(
          color: AppColors.surface,
          padding: const EdgeInsets.all(16),
          child: SafeArea(
            child: FilledButton(
              onPressed: loading
                  ? null
                  : () {
                      context
                          .read<AdminOrdersCubit>()
                          .updateStatus(order.id, nextStatus!);
                    },
              style: FilledButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: AppColors.surface,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.surface,
                      ),
                    )
                  : Text(
                      buttonText,
                      style: AppTextStyles.textTheme.titleMedium?.copyWith(
                        color: AppColors.surface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          softWrap: true,
        ),
      ],
    );
  }
}
