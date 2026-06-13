import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/no_internet_widget.dart';
import '../../orders/logic/cart_cubit.dart';
import '../../orders/logic/cart_state.dart';
import '../data/models/product_model.dart';
import '../logic/products_cubit.dart';
import '../logic/products_state.dart';

String _formatRs(double value) {
  final fmt = NumberFormat('#,##0', 'en_US');
  return 'Rs. ${fmt.format(value)}';
}

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  late final AnimationController _searchAnim;
  bool _searchOpen = false;

  @override
  void initState() {
    super.initState();
    _searchAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void dispose() {
    _searchAnim.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (_searchOpen) {
        _searchAnim.forward();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFocus.requestFocus();
        });
      } else {
        _searchAnim.reverse();
        _searchController.clear();
        _searchFocus.unfocus();
        context.read<ProductsCubit>().searchProducts('');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Products',
          style: AppTextStyles.textTheme.titleLarge?.copyWith(
            color: AppColors.primaryGreen,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          BlocBuilder<CartCubit, CartState>(
            buildWhen: (p, c) => p != c,
            builder: (context, cart) {
              final count = cart.totalItems;
              return IconButton(
                tooltip: 'Cart',
                onPressed: () => context.push('/cart'),
                icon: Badge(
                  label: Text(
                    '$count',
                    style: AppTextStyles.textTheme.labelMedium?.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  isLabelVisible: count > 0,
                  backgroundColor: AppColors.accentOrange,
                  child: Icon(
                    Icons.shopping_cart_outlined,
                    color: AppColors.primaryGreen,
                  ),
                ),
              );
            },
          ),
          IconButton(
            onPressed: _toggleSearch,
            tooltip: 'Search',
            icon: Icon(
              _searchOpen ? Icons.close_rounded : Icons.search_rounded,
              color: AppColors.primaryGreen,
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRect(
            child: SizeTransition(
              sizeFactor: CurvedAnimation(
                parent: _searchAnim,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              ),
              axisAlignment: -1,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Focus(
                  onFocusChange: (_) => setState(() {}),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    style: AppTextStyles.textTheme.bodyLarge,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search products',
                      hintStyle: AppTextStyles.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textHint,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.textSecondary,
                      ),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                context
                                    .read<ProductsCubit>()
                                    .searchProducts('');
                                setState(() {});
                              },
                              icon: const Icon(
                                Icons.clear_rounded,
                                color: AppColors.textSecondary,
                              ),
                            ),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.primaryGreen,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                      context.read<ProductsCubit>().searchProducts(value);
                    },
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<ProductsCubit, ProductsState>(
              builder: (context, state) {
                if (state is ProductsLoading ||
                    state is ProductsInitial ||
                    state is ProductSearching) {
                  return RefreshIndicator(
                    color: AppColors.primaryGreen,
                    onRefresh: () => context.read<ProductsCubit>().refresh(),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          sliver: _ProductGridShimmer(),
                        ),
                      ],
                    ),
                  );
                }

                if (state is ProductsError) {
                  final isNetworkError = state.message.toLowerCase().contains('internet') ||
                      state.message.toLowerCase().contains('network') ||
                      state.message.toLowerCase().contains('connection');

                  if (isNetworkError) {
                    return RefreshIndicator(
                      color: AppColors.primaryGreen,
                      onRefresh: () => context.read<ProductsCubit>().refresh(),
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: NoInternetWidget(
                              message: state.message,
                              onRetry: () =>
                                  context.read<ProductsCubit>().loadProducts(),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.primaryGreen,
                    onRefresh: () => context.read<ProductsCubit>().refresh(),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _ProductsError(
                            message: state.message,
                            onRetry: () =>
                                context.read<ProductsCubit>().loadProducts(),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (state is ProductsLoaded) {
                  if (state.products.isEmpty) {
                    return RefreshIndicator(
                      color: AppColors.primaryGreen,
                      onRefresh: () => context.read<ProductsCubit>().refresh(),
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: EmptyState(
                              title: 'No products found',
                              subtitle: 'Try a different search',
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.primaryGreen,
                    onRefresh: () => context.read<ProductsCubit>().refresh(),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childAspectRatio: 0.50,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final product = state.products[index];
                                return BlocBuilder<CartCubit, CartState>(
                                  buildWhen: (p, c) => p != c,
                                  builder: (context, cart) {
                                    final qty = context
                                        .read<CartCubit>()
                                        .getQuantity(product.id);
                                    return _ProductCard(
                                      product: product,
                                      cartQuantity: qty,
                                    );
                                  },
                                );
                              },
                              childCount: state.products.length,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductGridShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.50,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => const _ProductCardShimmer(),
        childCount: 6,
      ),
    );
  }
}

class _ProductCardShimmer extends StatelessWidget {
  const _ProductCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12,
                    width: double.infinity,
                    color: AppColors.divider,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 120,
                    color: AppColors.divider,
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

class _ProductsError extends StatelessWidget {
  const _ProductsError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 56,
            color: AppColors.error.withValues(alpha: 0.9),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Retry',
              style: AppTextStyles.textTheme.titleSmall?.copyWith(
                color: AppColors.surface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.cartQuantity,
  });

  final ProductModel product;
  final int cartQuantity;

  void _openDetail(BuildContext context) {
    context.push('/home/products/${product.id}');
  }

  @override
  Widget build(BuildContext context) {
    final imageWidget = Hero(
      tag: product.id,
      child: Material(
        color: AppColors.surface.withValues(alpha: 0),
        child: product.imageUrl == null || product.imageUrl!.isEmpty
            ? Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryGreen.withValues(alpha: 0.92),
                      AppColors.success.withValues(alpha: 0.92),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: AppColors.surface,
                  size: 46,
                ),
              )
            : ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Container(
                  height: 140,
                  width: double.infinity,
                  color: AppColors.surface,
                  padding: const EdgeInsets.all(8),
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl!,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );

    return Material(
      color: AppColors.surface,
      elevation: 1,
      shadowColor: AppColors.textPrimary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () => _openDetail(context),
            child: SizedBox(height: 140, child: imageWidget),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _openDetail(context),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.internalCode,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatRs(product.pricePerCarton),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${product.itemsPerCarton} items/carton',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: cartQuantity <= 0
                ? Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      height: 32,
                      child: FilledButton(
                        onPressed: () {
                          context.read<CartCubit>().addToCart(product, 1);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accentOrange,
                          foregroundColor: AppColors.surface,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Add to Cart',
                          style:
                              AppTextStyles.textTheme.labelMedium?.copyWith(
                            color: AppColors.surface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  )
                : Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _GridQtyChip(
                          icon: Icons.remove_rounded,
                          bg: AppColors.divider,
                          fg: AppColors.textPrimary,
                          onTap: () => context.read<CartCubit>().updateQuantity(
                                product.id,
                                cartQuantity - 1,
                              ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '$cartQuantity',
                            style: AppTextStyles.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        _GridQtyChip(
                          icon: Icons.add_rounded,
                          bg: AppColors.primaryGreen,
                          fg: AppColors.surface,
                          onTap: () => context.read<CartCubit>().addToCart(
                                product,
                                1,
                              ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _GridQtyChip extends StatelessWidget {
  const _GridQtyChip({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  final IconData icon;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(icon, size: 18, color: fg),
        ),
      ),
    );
  }
}
