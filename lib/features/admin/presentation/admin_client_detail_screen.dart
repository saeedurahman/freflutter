import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/no_internet_widget.dart';
import '../logic/admin_clients_cubit.dart';
import '../logic/admin_clients_state.dart';

class AdminClientDetailScreen extends StatefulWidget {
  const AdminClientDetailScreen({required this.clientId, super.key});
  final String clientId;

  @override
  State<AdminClientDetailScreen> createState() => _AdminClientDetailScreenState();
}

class _AdminClientDetailScreenState extends State<AdminClientDetailScreen> {
  void _openAddLocationSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => BlocProvider.value(
        value: ctx.read<AdminClientsCubit>(),
        child: _AddLocationSheet(clientId: widget.clientId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AdminClientsCubit>()..loadClientDetail(widget.clientId),
      child: Builder(
        builder: (context) {
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
                'Client Details',
                style: AppTextStyles.textTheme.titleLarge?.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            body: BlocConsumer<AdminClientsCubit, AdminClientsState>(
              listener: (context, state) {
                if (state is AdminClientCreated) {
                  context.read<AdminClientsCubit>().loadClientDetail(widget.clientId);
                } else if (state is AdminClientsError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
              buildWhen: (p, c) => c is! AdminClientCreating && c is! AdminClientCreated && c is! AdminClientsLoaded,
              builder: (context, state) {
                if (state is AdminClientsLoading || state is AdminClientsInitial) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryGreen),
                  );
                }

                if (state is AdminClientsError) {
                  final isNetworkError = state.message.toLowerCase().contains('internet') ||
                      state.message.toLowerCase().contains('network') ||
                      state.message.toLowerCase().contains('connection');

                  if (isNetworkError) {
                    return NoInternetWidget(
                      message: state.message,
                      onRetry: () => context.read<AdminClientsCubit>().loadClientDetail(widget.clientId),
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
                            onPressed: () => context.read<AdminClientsCubit>().loadClientDetail(widget.clientId),
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

                if (state is AdminClientDetailLoaded) {
                  final client = state.client;
                  final locs = state.locations;

                  return RefreshIndicator(
                    color: AppColors.primaryGreen,
                    onRefresh: () => context.read<AdminClientsCubit>().loadClientDetail(widget.clientId),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Material(
                              color: AppColors.surface,
                              elevation: 1,
                              shadowColor: AppColors.textPrimary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 40,
                                      backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.1),
                                      child: Text(
                                        client.name.isNotEmpty ? client.name[0].toUpperCase() : 'C',
                                        style: AppTextStyles.textTheme.headlineLarge?.copyWith(
                                          color: AppColors.primaryGreen,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      client.name,
                                      style: AppTextStyles.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Code: ${client.clientCode}  •  Tax ID: ${client.taxId}',
                                      style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: client.isActive
                                            ? AppColors.success.withValues(alpha: 0.1)
                                            : AppColors.error.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        client.isActive ? 'Active Client' : 'Inactive Client',
                                        style: AppTextStyles.textTheme.labelMedium?.copyWith(
                                          color: client.isActive ? AppColors.success : AppColors.error,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Locations',
                                  style: AppTextStyles.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => _openAddLocationSheet(context),
                                  icon: const Icon(Icons.add_location_alt_outlined),
                                  label: const Text('Add'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (locs.isEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'No locations found.',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final loc = locs[index];
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
                                            const Icon(
                                              Icons.location_on_rounded,
                                              color: AppColors.textSecondary,
                                              size: 28,
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        loc.label,
                                                        style: AppTextStyles.textTheme.titleSmall?.copyWith(
                                                          fontWeight: FontWeight.w700,
                                                        ),
                                                      ),
                                                      if (loc.isDefault) ...[
                                                        const SizedBox(width: 8),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: AppColors.primaryGreen.withValues(alpha: 0.1),
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          child: Text(
                                                            'Default',
                                                            style: AppTextStyles.textTheme.labelSmall?.copyWith(
                                                              color: AppColors.primaryGreen,
                                                              fontWeight: FontWeight.w700,
                                                              fontSize: 10,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    loc.address,
                                                    style: AppTextStyles.textTheme.bodySmall?.copyWith(
                                                      color: AppColors.textSecondary,
                                                      height: 1.3,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                childCount: locs.length,
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
          );
        },
      ),
    );
  }
}

class _AddLocationSheet extends StatefulWidget {
  const _AddLocationSheet({required this.clientId});
  final String clientId;

  @override
  State<_AddLocationSheet> createState() => _AddLocationSheetState();
}

class _AddLocationSheetState extends State<_AddLocationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _labelCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _isDefault = false;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AdminClientsCubit>().addLocation(
      widget.clientId,
      {
        'label': _labelCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'is_default': _isDefault,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminClientsCubit, AdminClientsState>(
      listener: (context, state) {
        if (state is AdminClientCreated) {
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
                  'Add Location',
                  style: AppTextStyles.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _labelCtrl,
                  decoration: const InputDecoration(labelText: 'Label (e.g. Main Store)', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Set as Default'),
                  value: _isDefault,
                  onChanged: (v) => setState(() => _isDefault = v),
                  activeTrackColor: AppColors.primaryGreen,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),
                BlocBuilder<AdminClientsCubit, AdminClientsState>(
                  builder: (context, state) {
                    final loading = state is AdminClientCreating;
                    return FilledButton(
                      onPressed: loading ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: loading
                          ? const CircularProgressIndicator(color: AppColors.surface)
                          : const Text('Save Location'),
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
