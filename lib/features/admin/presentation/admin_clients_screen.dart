import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/no_internet_widget.dart';
import '../data/models/admin_client_model.dart';
import '../logic/admin_clients_cubit.dart';
import '../logic/admin_clients_state.dart';

class AdminClientsScreen extends StatefulWidget {
  const AdminClientsScreen({super.key});

  @override
  State<AdminClientsScreen> createState() => _AdminClientsScreenState();
}

class _AdminClientsScreenState extends State<AdminClientsScreen> {
  void _openAddClientSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => BlocProvider.value(
        value: ctx.read<AdminClientsCubit>(),
        child: const _AddClientSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AdminClientsCubit>()..loadClients(),
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
                'Clients',
                style: AppTextStyles.textTheme.titleLarge?.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () => _openAddClientSheet(context),
                  icon: const Icon(Icons.add_rounded, color: AppColors.primaryGreen),
                  tooltip: 'Add Client',
                ),
              ],
            ),
            body: BlocConsumer<AdminClientsCubit, AdminClientsState>(
              listener: (context, state) {
                if (state is AdminClientCreated) {
                  context.read<AdminClientsCubit>().loadClients();
                } else if (state is AdminClientsError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
              buildWhen: (p, c) => c is! AdminClientCreating && c is! AdminClientCreated && c is! AdminClientDetailLoaded,
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
                      onRetry: () => context.read<AdminClientsCubit>().loadClients(),
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
                            onPressed: () => context.read<AdminClientsCubit>().loadClients(),
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

                if (state is AdminClientsLoaded) {
                  if (state.clients.isEmpty) {
                    return Center(
                      child: Text(
                        'No clients found.',
                        style: AppTextStyles.textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    color: AppColors.primaryGreen,
                    onRefresh: () => context.read<AdminClientsCubit>().loadClients(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: state.clients.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _AdminClientTile(client: state.clients[index]);
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

class _AdminClientTile extends StatelessWidget {
  const _AdminClientTile({required this.client});
  final AdminClientModel client;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/admin/clients/${client.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: AppColors.surface,
        elevation: 1,
        shadowColor: AppColors.textPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.1),
                child: Text(
                  client.name.isNotEmpty ? client.name[0].toUpperCase() : 'C',
                  style: AppTextStyles.textTheme.titleLarge?.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            client.name,
                            style: AppTextStyles.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: client.isActive
                                ? AppColors.success.withValues(alpha: 0.1)
                                : AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            client.isActive ? 'Active' : 'Inactive',
                            style: AppTextStyles.textTheme.labelSmall?.copyWith(
                              color: client.isActive ? AppColors.success : AppColors.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Code: ${client.clientCode}',
                      style: AppTextStyles.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tax ID: ${client.taxId}',
                      style: AppTextStyles.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddClientSheet extends StatefulWidget {
  const _AddClientSheet();

  @override
  State<_AddClientSheet> createState() => _AddClientSheetState();
}

class _AddClientSheetState extends State<_AddClientSheet> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _taxCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _taxCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AdminClientsCubit>().createClient({
      'client_code': _codeCtrl.text.trim(),
      'name': _nameCtrl.text.trim(),
      'tax_id': _taxCtrl.text.trim(),
      'password': _passCtrl.text,
    });
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
                  'Add Client',
                  style: AppTextStyles.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Client Code', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _taxCtrl,
                  decoration: const InputDecoration(labelText: 'Tax ID', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
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
                          : const Text('Save Client'),
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
