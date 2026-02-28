import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sakasama/core/constants/app_colors.dart';
import 'package:sakasama/core/constants/app_dimensions.dart';
import 'package:sakasama/core/constants/app_strings.dart';
import 'package:sakasama/data/providers/database_providers.dart';

/// Permissions rationale screen — fourth and final step of onboarding.
///
/// Explains why camera, microphone, and storage permissions are needed,
/// then actually requests them via the OS dialogs.
class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> {
  final Map<Permission, bool> _granted = {
    Permission.camera: false,
    Permission.microphone: false,
  };
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _checkCurrent();
  }

  /// Check which permissions are already granted.
  Future<void> _checkCurrent() async {
    final camStatus = await Permission.camera.status;
    final micStatus = await Permission.microphone.status;
    if (mounted) {
      setState(() {
        _granted[Permission.camera] = camStatus.isGranted;
        _granted[Permission.microphone] = micStatus.isGranted;
      });
    }
  }

  /// Request all permissions sequentially.
  Future<void> _requestAll() async {
    setState(() => _isRequesting = true);

    try {
      // Request camera
      final camResult = await Permission.camera.request();
      if (mounted) {
        setState(() => _granted[Permission.camera] = camResult.isGranted);
      }

      // Request microphone
      final micResult = await Permission.microphone.request();
      if (mounted) {
        setState(() => _granted[Permission.microphone] = micResult.isGranted);
      }

      // Mark onboarding as completed and navigate to dashboard
      if (mounted) {
        await _completeOnboarding();
        if (mounted) context.go('/');
      }
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  /// Request a single permission.
  Future<void> _requestSingle(Permission permission) async {
    final status = await permission.status;

    if (status.isPermanentlyDenied) {
      // Open app settings if permanently denied
      if (mounted) {
        final opened = await openAppSettings();
        if (!opened && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Buksan ang Settings para i-allow ang permission.'),
            ),
          );
        }
      }
      return;
    }

    final result = await permission.request();
    if (mounted) {
      setState(() => _granted[permission] = result.isGranted);
    }
  }

  bool get _allGranted => _granted.values.every((v) => v);

  /// Persist onboarding completion to SharedPreferences and local DB.
  Future<void> _completeOnboarding() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    // Save to SharedPreferences for fast router checks
    if (userId != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed_$userId', true);
    }

    // Also save to local DB
    if (userId != null) {
      await ref
          .read(userProfileDaoProvider)
          .markOnboardingCompleted(
            userId,
            email: Supabase.instance.client.auth.currentUser?.email,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/onboarding/farm-setup'),
          tooltip: AppStrings.back,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppDimensions.itemSpacing),

              // ── Title ─────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      color: AppColors.primaryGreen,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.itemSpacing),
                  Expanded(
                    child: Text(
                      AppStrings.permissionsTitle,
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: AppDimensions.smallSpacing),

              Text(
                'Para gumana nang maayos ang Sakasama, kailangan namin ang mga sumusunod na pahintulot.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textGrey),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

              const SizedBox(height: AppDimensions.sectionSpacing),

              // ── Permission Items ──────────────────────────────────
              _buildPermissionCard(
                    context,
                    icon: Icons.camera_alt_rounded,
                    title: AppStrings.cameraPermission,
                    description: AppStrings.cameraPermissionDesc,
                    color: const Color(0xFF1565C0),
                    isGranted: _granted[Permission.camera] ?? false,
                    onRequest: () => _requestSingle(Permission.camera),
                  )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 400.ms)
                  .slideX(begin: 0.1, end: 0),

              const SizedBox(height: AppDimensions.itemSpacing),

              _buildPermissionCard(
                    context,
                    icon: Icons.mic_rounded,
                    title: AppStrings.micPermission,
                    description: AppStrings.micPermissionDesc,
                    color: const Color(0xFF6A1B9A),
                    isGranted: _granted[Permission.microphone] ?? false,
                    onRequest: () => _requestSingle(Permission.microphone),
                  )
                  .animate()
                  .fadeIn(delay: 450.ms, duration: 400.ms)
                  .slideX(begin: 0.1, end: 0),

              const SizedBox(height: AppDimensions.itemSpacing),

              _buildPermissionCard(
                    context,
                    icon: Icons.folder_rounded,
                    title: AppStrings.storagePermission,
                    description: AppStrings.storagePermissionDesc,
                    color: const Color(0xFFE65100),
                    isGranted:
                        true, // Not needed on Android 10+ (scoped storage)
                    onRequest: null,
                  )
                  .animate()
                  .fadeIn(delay: 600.ms, duration: 400.ms)
                  .slideX(begin: 0.1, end: 0),

              const Spacer(),

              // ── Privacy Note ──────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.cardPadding),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.inputRadius,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.info,
                      size: 24,
                    ),
                    const SizedBox(width: AppDimensions.smallSpacing),
                    Expanded(
                      child: Text(
                        'Ang lahat ng iyong datos ay nananatili sa iyong device lamang.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.info,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 800.ms, duration: 400.ms),

              const SizedBox(height: AppDimensions.itemSpacing),

              // ── Allow All Button ──────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: AppDimensions.primaryButtonHeight,
                child: ElevatedButton(
                  onPressed: _isRequesting
                      ? null
                      : _allGranted
                      ? () async {
                          await _completeOnboarding();
                          if (mounted) context.go('/');
                        }
                      : _requestAll,
                  child: _isRequesting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: AppColors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _allGranted
                                  ? Icons.check_circle_rounded
                                  : Icons.security_rounded,
                            ),
                            const SizedBox(width: AppDimensions.smallSpacing),
                            Text(
                              _allGranted ? 'Magpatuloy' : AppStrings.allowAll,
                            ),
                          ],
                        ),
                ),
              ).animate().fadeIn(delay: 900.ms, duration: 400.ms),

              const SizedBox(height: AppDimensions.smallSpacing),

              // ── Skip Option ───────────────────────────────────────
              Center(
                child: TextButton(
                  onPressed: () async {
                    await _completeOnboarding();
                    if (mounted) context.go('/');
                  },
                  child: const Text('Mamaya na lang'),
                ),
              ),

              const SizedBox(height: AppDimensions.screenPadding),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required bool isGranted,
    VoidCallback? onRequest,
  }) {
    return GestureDetector(
      onTap: isGranted ? null : onRequest,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          border: isGranted
              ? Border.all(
                  color: AppColors.success.withValues(alpha: 0.4),
                  width: 1.5,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isGranted
                    ? AppColors.success.withValues(alpha: 0.1)
                    : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isGranted ? Icons.check_rounded : icon,
                color: isGranted ? AppColors.success : color,
                size: 28,
              ),
            ),
            const SizedBox(width: AppDimensions.cardPadding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textGrey),
                  ),
                ],
              ),
            ),
            if (!isGranted && onRequest != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Allow',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              )
            else if (isGranted)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
