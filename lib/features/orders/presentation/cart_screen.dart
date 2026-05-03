import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/models/cart_item_model.dart';
import '../data/models/location_model.dart';
import '../logic/cart_cubit.dart';
import '../logic/cart_state.dart';
import '../logic/order_cubit.dart';
import '../logic/order_state.dart';
import 'order_success_screen.dart';

String _formatRs(double value) {
  final fmt = NumberFormat('#,##0', 'en_US');
  return 'Rs. ${fmt.format(value)}';
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.textPrimary,
        ),
        title: Text(
          'My Cart',
          style: AppTextStyles.textTheme.titleLarge?.copyWith(
            color: AppColors.primaryGreen,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          BlocBuilder<CartCubit, CartState>(
            builder: (context, cart) {
              final count = cart.totalItems;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Badge(
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
                    size: 26,
                  ),
                ),
              );
            },
          ),
          BlocBuilder<CartCubit, CartState>(
            builder: (context, cart) {
              if (cart.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => _confirmClear(context),
                child: Text(
                  'Clear All',
                  style: AppTextStyles.textTheme.titleSmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, cart) {
          if (cart.isEmpty) {
            return const _EmptyCartView();
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Dismissible(
                        key: ValueKey(item.product.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.surface,
                            size: 28,
                          ),
                        ),
                        onDismissed: (_) {
                          context
                              .read<CartCubit>()
                              .removeFromCart(item.product.id);
                        },
                        child: _CartLineCard(item: item),
                      ),
                    );
                  },
                ),
              ),
              _OrderSummaryBar(
                cart: cart,
                onCheckout: () =>
                    _showLocationSheet(context, cart.items),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Clear cart?',
          style: AppTextStyles.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Remove all items from your cart?',
          style: AppTextStyles.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: AppTextStyles.textTheme.titleSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Clear',
              style: AppTextStyles.textTheme.titleSmall?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<CartCubit>().clearCart();
    }
  }

  Future<void> _showLocationSheet(
    BuildContext context,
    List<CartItemModel> items,
  ) async {
    final cartCubit = context.read<CartCubit>();
    final orderCubit = context.read<OrderCubit>();

    await orderCubit.loadLocations();
    if (!context.mounted) return;

    final state = orderCubit.state;
    if (state is OrderFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final locations =
        state is LocationsLoaded ? state.locations : <LocationModel>[];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetCtx) {
        return _LocationPickerSheet(
          locations: locations,
          cartItems: items,
          cartCubit: cartCubit,
          orderCubit: orderCubit,
        );
      },
    );
  }
}

class _LocationPickerSheet extends StatefulWidget {
  const _LocationPickerSheet({
    required this.locations,
    required this.cartItems,
    required this.cartCubit,
    required this.orderCubit,
  });

  final List<LocationModel> locations;
  final List<CartItemModel> cartItems;
  final CartCubit cartCubit;
  final OrderCubit orderCubit;

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    final defaults = widget.locations.where((l) => l.isDefault);
    if (defaults.isNotEmpty) {
      _selectedId = defaults.first.id;
    } else if (widget.locations.isNotEmpty) {
      _selectedId = widget.locations.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: bottomInset + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Select Delivery Location',
            style: AppTextStyles.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose where this order should be delivered.',
            style: AppTextStyles.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.45,
            ),
            child: widget.locations.isEmpty
                ? SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No locations found. Add a location in your profile or contact support.',
                        style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: widget.locations.length,
                    itemBuilder: (context, index) {
                      final loc = widget.locations[index];
                      final selected = _selectedId == loc.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: selected
                              ? AppColors.primaryGreen.withValues(alpha: 0.06)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => setState(() => _selectedId = loc.id),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                loc.label,
                                                style: AppTextStyles
                                                    .textTheme.titleSmall
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            if (loc.isDefault)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryGreen
                                                      .withValues(alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          999),
                                                ),
                                                child: Text(
                                                  'Default',
                                                  style: AppTextStyles
                                                      .textTheme.labelMedium
                                                      ?.copyWith(
                                                    color:
                                                        AppColors.primaryGreen,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          loc.address,
                                          style: AppTextStyles
                                              .textTheme.bodySmall
                                              ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    selected
                                        ? Icons.radio_button_checked_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                    color: selected
                                        ? AppColors.primaryGreen
                                        : AppColors.textHint,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          BlocConsumer<OrderCubit, OrderState>(
            bloc: widget.orderCubit,
            listener: (context, state) {
              if (state is OrderFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            builder: (context, orderState) {
              final placing = orderState is OrderPlacing;
              final canSubmit =
                  _selectedId != null && widget.cartItems.isNotEmpty && !placing;

              return SizedBox(
                height: 54,
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primaryGreen,
                        AppColors.success,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Material(
                    color: AppColors.surface.withValues(alpha: 0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: !canSubmit
                          ? null
                          : () async {
                              final selectedId = _selectedId!;
                              final selectedLoc = widget.locations
                                  .firstWhere((e) => e.id == selectedId);
                              final snapshot =
                                  List<CartItemModel>.from(widget.cartItems);
                              final totalItems = snapshot.fold<int>(
                                0,
                                (s, e) => s + e.quantity,
                              );
                              final totalAmount = snapshot.fold<double>(
                                0,
                                (s, e) => s + e.totalPrice,
                              );

                              final order =
                                  await widget.orderCubit.placeOrder(
                                selectedId,
                                snapshot,
                              );

                              if (order == null || !context.mounted) return;

                              final router = GoRouter.of(context);
                              final extra = OrderSuccessExtra(
                                order: order,
                                locationLabel:
                                    '${selectedLoc.label} — ${selectedLoc.address}',
                                totalItems: totalItems,
                                totalAmount: totalAmount,
                              );

                              Navigator.of(context).pop();
                              router.pushReplacement(
                                '/order-success',
                                extra: extra,
                              );
                            },
                      child: Center(
                        child: placing
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.surface,
                                ),
                              )
                            : Text(
                                'Place Order',
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
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyCartView extends StatefulWidget {
  const _EmptyCartView();

  @override
  State<_EmptyCartView> createState() => _EmptyCartViewState();
}

class _EmptyCartViewState extends State<_EmptyCartView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = CurvedAnimation(parent: _bounce, curve: Curves.easeInOut);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _bounce,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -6 * t.value),
                  child: child,
                );
              },
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shopping_cart_outlined,
                  size: 64,
                  color: AppColors.primaryGreen.withValues(alpha: 0.85),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Your cart is empty',
              textAlign: TextAlign.center,
              style: AppTextStyles.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Browse products and add items',
              textAlign: TextAlign.center,
              style: AppTextStyles.textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () => context.go('/home?tab=products'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Browse Products',
                  style: AppTextStyles.textTheme.titleSmall?.copyWith(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartLineCard extends StatelessWidget {
  const _CartLineCard({required this.item});

  final CartItemModel item;

  @override
  Widget build(BuildContext context) {
    final p = item.product;

    final thumb = p.imageUrl != null && p.imageUrl!.isNotEmpty
        ? ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: p.imageUrl!,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 60,
                height: 60,
                color: AppColors.shimmerBase,
              ),
              errorWidget: (context, url, error) => _placeholderThumb(),
            ),
          )
        : _placeholderThumb();

    return Material(
      color: AppColors.surface,
      elevation: 1,
      shadowColor: AppColors.textPrimary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: 60, height: 60, child: thumb),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.internalCode,
                    style: AppTextStyles.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatRs(p.pricePerCarton),
                    style: AppTextStyles.textTheme.titleSmall?.copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MiniQtyIcon(
                      icon: Icons.remove_rounded,
                      bg: AppColors.divider,
                      fg: AppColors.textPrimary,
                      onTap: () => context.read<CartCubit>().updateQuantity(
                            p.id,
                            item.quantity - 1,
                          ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${item.quantity}',
                        style: AppTextStyles.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _MiniQtyIcon(
                      icon: Icons.add_rounded,
                      bg: AppColors.primaryGreen,
                      fg: AppColors.surface,
                      onTap: () => context.read<CartCubit>().updateQuantity(
                            p.id,
                            item.quantity + 1,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderThumb() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen.withValues(alpha: 0.85),
            AppColors.success.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.shopping_bag_outlined,
        color: AppColors.surface,
        size: 28,
      ),
    );
  }
}

class _MiniQtyIcon extends StatelessWidget {
  const _MiniQtyIcon({
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
          width: 32,
          height: 32,
          child: Icon(icon, size: 18, color: fg),
        ),
      ),
    );
  }
}

class _OrderSummaryBar extends StatelessWidget {
  const _OrderSummaryBar({
    required this.cart,
    required this.onCheckout,
  });

  final CartState cart;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Material(
      elevation: 12,
      shadowColor: AppColors.textPrimary.withValues(alpha: 0.12),
      color: AppColors.surface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 14, 16, bottom + 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Order Summary',
              style: AppTextStyles.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total items',
                  style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${cart.totalItems}',
                  style: AppTextStyles.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total amount',
                  style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  _formatRs(cart.totalPrice),
                  style: AppTextStyles.textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.primaryGreen,
                    AppColors.success,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: Material(
                  color: AppColors.surface.withValues(alpha: 0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: onCheckout,
                    child: Center(
                      child: Text(
                        'Select Location & Place Order',
                        style: AppTextStyles.textTheme.titleSmall?.copyWith(
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
    );
  }
}
