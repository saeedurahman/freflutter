import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/no_internet_widget.dart';
import '../logic/profile_cubit.dart';
import '../logic/profile_state.dart';
import '../../orders/data/models/location_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileCubit>()..loadProfile(),
      child: const _ProfileBody(),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody();

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
          'Profile',
          style: AppTextStyles.textTheme.titleLarge?.copyWith(
            color: AppColors.primaryGreen,
            fontWeight: FontWeight.w700,
          ),
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
      ),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading || state is ProfileInitial) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            );
          }

          if (state is ProfileFailure) {
            final message = state.message.toLowerCase();
            final isNetworkError = message.contains('internet') ||
                message.contains('network') ||
                message.contains('connection');

            if (isNetworkError) {
              return NoInternetWidget(
                message: state.message,
                onRetry: () => context.read<ProfileCubit>().loadProfile(),
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
                          context.read<ProfileCubit>().loadProfile(),
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

          if (state is ProfileLoaded) {
            final user = state.user;
            final locations = user.locations ?? const <LocationModel>[];
            final locationWidgets = locations.isEmpty
                ? <Widget>[
                    Material(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'No locations found. Add a location in your profile or contact support.',
                          style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ]
                : locations
                    .map(
                      (location) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  location.label,
                                  style: AppTextStyles.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  location.address,
                                  style: AppTextStyles.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList();

            return RefreshIndicator(
              color: AppColors.primaryGreen,
              onRefresh: () => context.read<ProfileCubit>().loadProfile(),
              child: ListView(
                padding: const EdgeInsets.all(24),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        user.name?.isNotEmpty == true
                            ? user.name![0].toUpperCase()
                            : user.clientCode.isNotEmpty
                                ? user.clientCode[0].toUpperCase()
                                : 'U',
                        style: AppTextStyles.textTheme.displaySmall?.copyWith(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    user.name ?? 'Client',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.clientCode,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: user.isActive
                            ? AppColors.primaryGreen.withValues(alpha: 0.12)
                            : AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        user.isActive ? 'Active' : 'Inactive',
                        style: AppTextStyles.textTheme.bodySmall?.copyWith(
                          color: user.isActive ? AppColors.primaryGreen : AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _InfoTile(
                    icon: Icons.badge_outlined,
                    label: 'Client Code',
                    value: user.clientCode,
                  ),
                  const SizedBox(height: 12),
                  _InfoTile(
                    icon: Icons.receipt_long_outlined,
                    label: 'Tax ID',
                    value: user.taxId ?? 'Not provided',
                  ),
                  if (user.email != null && user.email!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _InfoTile(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: user.email!,
                    ),
                  ],
                  if (user.phone != null && user.phone!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _InfoTile(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: user.phone!,
                    ),
                  ],
                  if (user.address != null && user.address!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _InfoTile(
                      icon: Icons.location_on_outlined,
                      label: 'Address',
                      value: user.address!,
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Locations',
                    style: AppTextStyles.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...locationWidgets,
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () async {
                      await getIt<StorageService>().clearAll();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Logout',
                      style: AppTextStyles.textTheme.titleMedium?.copyWith(
                        color: AppColors.surface,
                        fontWeight: FontWeight.w700,
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
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.textPrimary.withValues(alpha: 0.05),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppColors.primaryGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: AppTextStyles.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
