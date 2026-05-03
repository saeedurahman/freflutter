import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/models/order_model.dart';

class OrderSuccessExtra {
  OrderSuccessExtra({
    required this.order,
    required this.locationLabel,
    required this.totalItems,
    required this.totalAmount,
  });

  final OrderModel order;
  final String locationLabel;
  final int totalItems;
  final double totalAmount;
}

String _formatRs(double value) {
  final fmt = NumberFormat('#,##0', 'en_US');
  return 'Rs. ${fmt.format(value)}';
}

class OrderSuccessScreen extends StatefulWidget {
  const OrderSuccessScreen({
    required this.extra,
    super.key,
  });

  final OrderSuccessExtra extra;

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> {
  double _checkScale = 0;
  int _secondsLeft = 5;
  Timer? _countdown;
  Timer? _redirect;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _checkScale = 1);
    });

    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _secondsLeft--;
      });
      if (_secondsLeft <= 0) {
        t.cancel();
      }
    });

    _redirect = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      context.go('/home?tab=orders');
    });
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _redirect?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final extra = widget.extra;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryGreen,
              AppColors.success,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                AnimatedScale(
                  scale: _checkScale,
                  duration: const Duration(milliseconds: 520),
                  curve: Curves.elasticOut,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.surface,
                      size: 72,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Order Placed!',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.textTheme.headlineMedium?.copyWith(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  extra.order.id,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.textTheme.bodySmall?.copyWith(
                    color: AppColors.surface.withValues(alpha: 0.95),
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your order has been received',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.textTheme.titleMedium?.copyWith(
                    color: AppColors.surface.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textPrimary.withValues(alpha: 0.12),
                        blurRadius: 22,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order summary',
                        style: AppTextStyles.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _row(
                        'Total items',
                        '${extra.totalItems}',
                      ),
                      const SizedBox(height: 8),
                      _row(
                        'Total amount',
                        _formatRs(extra.totalAmount),
                        highlight: true,
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: AppColors.divider),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'Status',
                            style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentOrange.withValues(
                                alpha: 0.14,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Pending',
                              style:
                                  AppTextStyles.textTheme.labelMedium?.copyWith(
                                color: AppColors.accentOrange,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Location',
                        style: AppTextStyles.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        extra.locationLabel,
                        style: AppTextStyles.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  _secondsLeft > 0
                      ? 'Opening orders in $_secondsLeft…'
                      : 'Opening orders…',
                  style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                    color: AppColors.surface.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () {
                      _redirect?.cancel();
                      context.go('/home?tab=orders');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.surface, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'View Orders',
                      style: AppTextStyles.textTheme.titleSmall?.copyWith(
                        color: AppColors.surface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () {
                      _redirect?.cancel();
                      context.go('/home?tab=products');
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Continue Shopping',
                      style: AppTextStyles.textTheme.titleSmall?.copyWith(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: highlight
              ? AppTextStyles.textTheme.titleMedium?.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w900,
                )
              : AppTextStyles.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
        ),
      ],
    );
  }
}
