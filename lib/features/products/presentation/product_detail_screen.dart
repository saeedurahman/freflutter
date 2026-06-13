import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../orders/logic/cart_cubit.dart';
import '../data/models/product_model.dart';
import '../data/repositories/product_repository.dart';

String _formatRs(double value) {
  final fmt = NumberFormat('#,##0', 'en_US');
  return 'Rs. ${fmt.format(value)}';
}

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    required this.productId,
    super.key,
  });

  final String productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  late Future<ProductModel> _future;
  int _quantity = 1;
  late final AnimationController _ctaPulse;
  late final Animation<double> _ctaScale;

  @override
  void initState() {
    super.initState();
    _ctaPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _ctaScale = Tween<double>(begin: 1, end: 0.94).animate(
      CurvedAnimation(parent: _ctaPulse, curve: Curves.easeInOut),
    );
    _reload();
  }

  void _reload() {
    _future = getIt<ProductRepository>().getProductById(widget.productId);
    _quantity = 1;
  }

  @override
  void dispose() {
    _ctaPulse.dispose();
    super.dispose();
  }

  double get _total => _quantity * _lastPrice;

  double _lastPrice = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<ProductModel>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryGreen,
              ),
            );
          }
          if (snapshot.hasError) {
            final err = snapshot.error;
            final message = err is ProductRepositoryException
                ? err.message
                : 'Could not load product.';
            return _ErrorView(
              message: message,
              onRetry: () => setState(_reload),
            );
          }
          final product = snapshot.data;
          if (product == null) {
            return _ErrorView(
              message: 'Product not found.',
              onRetry: () => context.pop(),
            );
          }

          _lastPrice = product.pricePerCarton;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 300,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _HeroImage(product: product),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10, top: 6),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            color: AppColors.surface,
                            shape: const CircleBorder(),
                            elevation: 2,
                            shadowColor:
                                AppColors.textPrimary.withValues(alpha: 0.15),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => context.pop(),
                              child: const SizedBox(
                                width: 44,
                                height: 44,
                                child: Icon(
                                  Icons.arrow_back_rounded,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textPrimary.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: AppTextStyles.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Text(
                            product.internalCode,
                            style: AppTextStyles.textTheme.labelMedium?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          '${_formatRs(product.pricePerCarton)} / carton',
                          style: AppTextStyles.textTheme.headlineSmall?.copyWith(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${product.itemsPerCarton} items per carton',
                          style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Divider(color: AppColors.divider),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              'Quantity',
                              style: AppTextStyles.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            _QtyButton(
                              icon: Icons.remove_rounded,
                              background: AppColors.divider,
                              foreground: AppColors.textPrimary,
                              onTap: () {
                                setState(() {
                                  _quantity = (_quantity - 1).clamp(1, 999999);
                                });
                              },
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 18),
                              child: Text(
                                '$_quantity',
                                style: AppTextStyles.textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            _QtyButton(
                              icon: Icons.add_rounded,
                              background: AppColors.primaryGreen,
                              foreground: AppColors.surface,
                              onTap: () {
                                setState(() => _quantity += 1);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Total: ${_formatRs(_total)}',
                          style: AppTextStyles.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        ScaleTransition(
                          scale: _ctaScale,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.accentOrange,
                                  AppColors.accentOrangeLight,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accentOrange.withValues(
                                    alpha: 0.35,
                                  ),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () async {
                                  await _ctaPulse.forward();
                                  await _ctaPulse.reverse();
                                  if (!context.mounted) return;
                                  context.read<CartCubit>().addToCart(
                                        product,
                                        _quantity,
                                      );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${product.name} added to cart',
                                        style: AppTextStyles.textTheme.bodyMedium
                                            ?.copyWith(color: AppColors.surface),
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: AppColors.primaryGreen,
                                    ),
                                  );
                                },
                                child: Center(
                                  child: Text(
                                    'Add to Cart',
                                    style: AppTextStyles.textTheme.titleMedium
                                        ?.copyWith(
                                      color: AppColors.surface,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final hasUrl =
        product.imageUrl != null && product.imageUrl!.trim().isNotEmpty;

    final child = hasUrl
        ? CachedNetworkImage(
            imageUrl: product.imageUrl!,
            fit: BoxFit.contain,
            width: double.infinity,
            height: 300,
            placeholder: (context, url) => Container(
              color: AppColors.shimmerBase,
              alignment: Alignment.center,
              child: const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: AppColors.shimmerBase,
              alignment: Alignment.center,
              child: const Icon(
                Icons.broken_image_outlined,
                color: AppColors.textSecondary,
                size: 44,
              ),
            ),
          )
        : Container(
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
            alignment: Alignment.center,
            child: const Icon(
              Icons.shopping_bag_outlined,
              size: 72,
              color: AppColors.surface,
            ),
          );

    return Hero(
      tag: product.id,
      child: Material(
        color: AppColors.surface,
        child: child,
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: foreground),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onRetry,
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
}
