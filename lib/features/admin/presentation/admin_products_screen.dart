import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/no_internet_widget.dart';
import '../../../../core/widgets/image_picker_widget.dart';
import '../data/models/admin_product_model.dart';
import '../logic/admin_products_cubit.dart';
import '../logic/admin_products_state.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  String _selectedStatus = 'all';

  void _openProductSheet(BuildContext ctx, [AdminProductModel? product]) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => BlocProvider.value(
        value: ctx.read<AdminProductsCubit>(),
        child: _AddEditProductSheet(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AdminProductsCubit>()..loadProducts(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              surfaceTintColor: AppColors.surface,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Text(
                'Products',
                style: AppTextStyles.textTheme.titleLarge?.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () => _openProductSheet(context),
                  icon: const Icon(Icons.add_rounded, color: AppColors.primaryGreen),
                  tooltip: 'Add Product',
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
                          context.read<AdminProductsCubit>().loadProducts();
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Active',
                        isSelected: _selectedStatus == 'active',
                        onTap: () {
                          setState(() => _selectedStatus = 'active');
                          context.read<AdminProductsCubit>().loadProducts(isActive: true);
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Inactive',
                        isSelected: _selectedStatus == 'inactive',
                        onTap: () {
                          setState(() => _selectedStatus = 'inactive');
                          context.read<AdminProductsCubit>().loadProducts(isActive: false);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            body: BlocConsumer<AdminProductsCubit, AdminProductsState>(
              listener: (context, state) {
                if (state is AdminProductCreated || state is AdminProductUpdated) {
                  context.read<AdminProductsCubit>().loadProducts(
                    isActive: _selectedStatus == 'all'
                        ? null
                        : _selectedStatus == 'active',
                  );
                } else if (state is AdminProductsError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
              buildWhen: (p, c) => c is! AdminProductCreating && c is! AdminProductUpdating && c is! AdminProductCreated && c is! AdminProductUpdated,
              builder: (context, state) {
                if (state is AdminProductsLoading || state is AdminProductsInitial) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryGreen),
                  );
                }

                if (state is AdminProductsError) {
                  final isNetworkError = state.message.toLowerCase().contains('internet') ||
                      state.message.toLowerCase().contains('network') ||
                      state.message.toLowerCase().contains('connection');

                  if (isNetworkError) {
                    return NoInternetWidget(
                      message: state.message,
                      onRetry: () => context.read<AdminProductsCubit>().loadProducts(
                            isActive: _selectedStatus == 'all'
                                ? null
                                : _selectedStatus == 'active',
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
                            onPressed: () => context.read<AdminProductsCubit>().loadProducts(
                                  isActive: _selectedStatus == 'all'
                                      ? null
                                      : _selectedStatus == 'active',
                                ),
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

                if (state is AdminProductsLoaded) {
                  if (state.products.isEmpty) {
                    return Center(
                      child: Text(
                        'No products found.',
                        style: AppTextStyles.textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    color: AppColors.primaryGreen,
                    onRefresh: () => context.read<AdminProductsCubit>().loadProducts(
                          isActive: _selectedStatus == 'all'
                              ? null
                              : _selectedStatus == 'active',
                        ),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      itemCount: state.products.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _AdminProductTile(
                          product: state.products[index],
                          onTap: () => _openProductSheet(context, state.products[index]),
                          onToggle: () {
                            // Only toggle active/inactive here. 
                            // If it's active, we can deactivate. If inactive, update to active.
                            // The API provides `PATCH /admin/products/{id}` and `DELETE /admin/products/{id}`.
                            if (state.products[index].isActive) {
                              context.read<AdminProductsCubit>().deactivateProduct(state.products[index].id);
                            } else {
                              context.read<AdminProductsCubit>().updateProduct(
                                state.products[index].id,
                                {'is_active': true},
                              );
                            }
                          },
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

class _AdminProductTile extends StatelessWidget {
  const _AdminProductTile({
    required this.product,
    required this.onTap,
    required this.onToggle,
  });

  final AdminProductModel product;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: AppColors.surface,
        elevation: 1,
        shadowColor: AppColors.textPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: product.imageUrl?.isNotEmpty == true
                    ? Container(
                        width: 60,
                        height: 60,
                        color: AppColors.surface,
                        padding: const EdgeInsets.all(4),
                        child: CachedNetworkImage(
                          imageUrl: product.imageUrl!,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => Container(
                            color: AppColors.divider,
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.divider,
                            child: const Icon(Icons.broken_image_outlined, color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: AppColors.primaryGreen.withValues(alpha: 0.1),
                        child: const Icon(Icons.inventory_2_outlined, color: AppColors.primaryGreen),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: AppTextStyles.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      product.internalCode,
                      style: AppTextStyles.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rs. ${product.pricePerCarton} • ${product.itemsPerCarton} items/ctn',
                      style: AppTextStyles.textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: product.isActive,
                onChanged: (_) => onToggle(),
                activeTrackColor: AppColors.primaryGreen,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddEditProductSheet extends StatefulWidget {
  const _AddEditProductSheet({this.product});
  final AdminProductModel? product;

  @override
  State<_AddEditProductSheet> createState() => _AddEditProductSheetState();
}

class _AddEditProductSheetState extends State<_AddEditProductSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _itemsCtrl;
  late String? _imageUrl;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _codeCtrl = TextEditingController(text: p?.internalCode);
    _nameCtrl = TextEditingController(text: p?.name);
    _priceCtrl = TextEditingController(text: p?.pricePerCarton.toString());
    _itemsCtrl = TextEditingController(text: p?.itemsPerCarton.toString());
    _imageUrl = p?.imageUrl;
    _isActive = p?.isActive ?? true;
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _itemsCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final data = {
      if (widget.product == null) 'internal_code': _codeCtrl.text.trim(),
      'name': _nameCtrl.text.trim(),
      'price_per_carton': double.parse(_priceCtrl.text.trim()),
      'items_per_carton': int.parse(_itemsCtrl.text.trim()),
      'is_active': _isActive,
      if (_imageUrl != null) 'image_url': _imageUrl,
    };

    if (widget.product == null) {
      context.read<AdminProductsCubit>().createProduct(data);
    } else {
      context.read<AdminProductsCubit>().updateProduct(widget.product!.id, data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminProductsCubit, AdminProductsState>(
      listener: (context, state) {
        if (state is AdminProductCreated || state is AdminProductUpdated) {
          context.pop();
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.product == null ? 'Add Product' : 'Edit Product',
                  style: AppTextStyles.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _codeCtrl,
                  decoration: const InputDecoration(labelText: 'Internal Code', border: OutlineInputBorder()),
                  enabled: widget.product == null,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Price/Carton', border: OutlineInputBorder()),
                        validator: (v) => v == null || double.tryParse(v) == null ? 'Invalid' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _itemsCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(labelText: 'Items/Carton', border: OutlineInputBorder()),
                        validator: (v) => v == null || int.tryParse(v) == null ? 'Invalid' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: ImagePickerWidget(
                    initialImageUrl: _imageUrl,
                    onImageChanged: (url) => setState(() => _imageUrl = url),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Is Active'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  activeTrackColor: AppColors.primaryGreen,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),
                BlocBuilder<AdminProductsCubit, AdminProductsState>(
                  builder: (context, state) {
                    final loading = state is AdminProductCreating || state is AdminProductUpdating;
                    return FilledButton(
                      onPressed: loading ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: loading
                          ? const CircularProgressIndicator(color: AppColors.surface)
                          : const Text('Save Product'),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
