import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../logic/auth_cubit.dart';
import '../logic/auth_state.dart';

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _clientCodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _clientCodeFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  late final TabController _tabController;

  late final AnimationController _headerController;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _headerFade;

  late final AnimationController _cardController;
  late final Animation<Offset> _cardSlide;

  Timer? _errorTimer;
  String? _errorBanner;

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: Curves.easeOutCubic,
      ),
    );
    _headerFade = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    );

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _cardController,
        curve: Curves.easeOutCubic,
      ),
    );

    _headerController.forward();
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _cardController.forward();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _errorTimer?.cancel();
    _headerController.dispose();
    _cardController.dispose();
    _clientCodeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _clientCodeFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _scheduleErrorDismiss() {
    _errorTimer?.cancel();
    _errorTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _errorBanner = null);
      }
    });
  }

  void _onSubmit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    
    if (_tabController.index == 0) {
      context.read<AuthCubit>().loginAsClient(
            _clientCodeController.text.trim(),
            _passwordController.text,
          );
    } else {
      context.read<AuthCubit>().loginAsAdmin(
            _emailController.text.trim(),
            _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              flex: 2,
              child: _buildHeader(context),
            ),
            Expanded(
              flex: 3,
              child: _buildFormCard(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
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
        bottom: false,
        child: SlideTransition(
          position: _headerSlide,
          child: FadeTransition(
            opacity: _headerFade,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    Image.asset(
                        'assets/images/asian_powers_logo.png',
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Asian Powers',
                        style: AppTextStyles.textTheme.headlineLarge!.copyWith(
                          color: AppColors.surface,
                          fontWeight: FontWeight.w700,
                          fontSize: 34,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Food from all over the world',
                        style: AppTextStyles.textTheme.titleMedium?.copyWith(
                          color: AppColors.surface.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return SlideTransition(
      position: _cardSlide,
      child: Material(
        color: AppColors.surface,
        elevation: 0,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(32),
        ),
        clipBehavior: Clip.antiAlias,
        child: BlocConsumer<AuthCubit, AuthState>(
          listenWhen: (previous, current) =>
              current is AuthSuccess || current is AuthFailure,
          listener: (context, state) {
            if (state is AuthSuccess) {
              final role = getIt<StorageService>().getRole();
              if (role == 'admin') {
                context.go('/admin');
              } else {
                context.go('/home');
              }
            } else if (state is AuthFailure) {
              setState(() => _errorBanner = state.message);
              _scheduleErrorDismiss();
            }
          },
          builder: (context, state) {
            final loading = state is AuthLoading;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.primaryGreen,
                      labelColor: AppColors.primaryGreen,
                      unselectedLabelColor: AppColors.textSecondary,
                      labelStyle: AppTextStyles.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      onTap: (_) => setState(() {
                        _errorBanner = null;
                      }),
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.person_outline_rounded),
                          text: 'Client Login',
                        ),
                        Tab(
                          icon: Icon(Icons.admin_panel_settings_outlined),
                          text: 'Admin Login',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: _errorBanner == null
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: const Duration(milliseconds: 320),
                                curve: Curves.easeOutCubic,
                                builder: (context, t, child) {
                                  return Transform.translate(
                                    offset: Offset(0, (1 - t) * -12),
                                    child: Opacity(opacity: t, child: child),
                                  );
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _errorBanner!,
                                    style: AppTextStyles.textTheme.bodyMedium
                                        ?.copyWith(color: AppColors.surface),
                                  ),
                                ),
                              ),
                            ),
                    ),
                    if (_tabController.index == 0)
                      TextFormField(
                        controller: _clientCodeController,
                        focusNode: _clientCodeFocus,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [_UpperCaseTextFormatter()],
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_passwordFocus),
                        decoration: InputDecoration(
                          labelText: 'Client Code',
                          prefixIcon: const Icon(
                            Icons.person_outline_rounded,
                            color: AppColors.textSecondary,
                          ),
                          labelStyle: AppTextStyles.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        style: AppTextStyles.textTheme.bodyLarge,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Client code is required';
                          }
                          return null;
                        },
                      )
                    else
                      TextFormField(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_passwordFocus),
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: AppColors.textSecondary,
                          ),
                          labelStyle: AppTextStyles.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        style: AppTextStyles.textTheme.bodyLarge,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!v.contains('@')) {
                            return 'Invalid email address';
                          }
                          return null;
                        },
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _onSubmit(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: AppColors.textSecondary,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        labelStyle: AppTextStyles.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      style: AppTextStyles.textTheme.bodyLarge,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Password is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primaryGreen,
                            AppColors.success,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGreen.withValues(
                              alpha: 0.35,
                            ),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: loading ? null : _onSubmit,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            shadowColor: AppColors.surface.withValues(alpha: 0),
                            backgroundColor: AppColors.surface.withValues(
                              alpha: 0,
                            ),
                            foregroundColor: AppColors.surface,
                            disabledForegroundColor:
                                AppColors.surface.withValues(alpha: 0.7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: loading
                                ? SizedBox(
                                    key: const ValueKey('loading'),
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppColors.surface,
                                    ),
                                  )
                                : Text(
                                    'Sign In',
                                    key: const ValueKey('label'),
                                    style: AppTextStyles.textTheme.titleMedium
                                        ?.copyWith(
                                      color: AppColors.surface,
                                      fontWeight: FontWeight.w600,
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
          },
        ),
      ),
    );
  }
}
