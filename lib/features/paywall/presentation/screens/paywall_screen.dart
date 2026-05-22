import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_coach/app/theme/app_colors.dart';
import 'package:speech_coach/app/theme/app_typography.dart';
import 'package:speech_coach/core/extensions/context_extensions.dart';
import 'package:speech_coach/features/paywall/presentation/providers/subscription_provider.dart';
import 'package:speech_coach/shared/widgets/tappable.dart';

/// Paywall screen with custom UI.
class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(subscriptionProvider);

    ref.listen<SubscriptionState>(subscriptionProvider, (prev, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error!)));
      }
      if (prev?.isPro != true && next.isPro) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome to Pro! Enjoy unlimited access.'),
          ),
        );
        context.pop();
      }
    });

    return _CustomPaywallFallback(sub: sub, ref: ref);
  }
}

/// Custom paywall UI used as fallback before RevenueCat products are set up.
class _CustomPaywallFallback extends StatelessWidget {
  final SubscriptionState sub;
  final WidgetRef ref;

  const _CustomPaywallFallback({required this.sub, required this.ref});

  @override
  Widget build(BuildContext context) {
    final monthlyPkg = sub.monthlyPackage;
    final yearlyPkg = sub.yearlyPackage;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Close button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Tappable(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.close_rounded, size: 24),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // Premium icon
                    Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.workspace_premium_rounded,
                            color: AppColors.white,
                            size: 40,
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          curve: Curves.easeOutBack,
                        ),
                    const SizedBox(height: 20),

                    Text(
                      'Unlock Your Track',
                      style: AppTypography.displaySmall(),
                    ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                    const SizedBox(height: 8),
                    Text(
                      'You\'ve used your 3 free sessions. Buy once, own it forever — no subscription.',
                      style: AppTypography.bodyMedium(
                        color: context.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                    const SizedBox(height: 32),

                    // Feature comparison
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE5E5E5),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          _FeatureRow(
                            feature: 'Sessions',
                            free: '3 total',
                            pro: 'Unlimited',
                          ),
                          const Divider(height: 24),
                          _FeatureRow(
                            feature: 'Session length',
                            free: '3 min',
                            pro: '5 min',
                          ),
                          const Divider(height: 24),
                          _FeatureRow(
                            feature: 'Score cards',
                            free: 'Basic',
                            pro: 'Detailed',
                          ),
                          const Divider(height: 24),
                          _FeatureRow(
                            feature: 'All categories',
                            free: '',
                            pro: '',
                            freeIcon: Icons.check_rounded,
                            proIcon: Icons.check_rounded,
                          ),
                          const Divider(height: 24),
                          _FeatureRow(
                            feature: 'Progress analytics',
                            free: '',
                            pro: '',
                            freeIcon: Icons.close_rounded,
                            proIcon: Icons.check_rounded,
                            freeIconColor: context.textTertiary,
                          ),
                          const Divider(height: 24),
                          _FeatureRow(
                            feature: 'Priority support',
                            free: '',
                            pro: '',
                            freeIcon: Icons.close_rounded,
                            proIcon: Icons.check_rounded,
                            freeIconColor: context.textTertiary,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                    const SizedBox(height: 24),

                    // Pricing cards — one-time purchases
                    Row(
                      children: [
                        Expanded(
                          child: _PricingCard(
                            title: 'This Track',
                            price: monthlyPkg?.storeProduct.priceString ?? '\$9.99',
                            period: 'one-time',
                            isPopular: false,
                            isLoading: sub.isPurchasing,
                            onTap: () => ref
                                .read(subscriptionProvider.notifier)
                                .purchase(monthlyPkg),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PricingCard(
                            title: 'All 5 Tracks',
                            price: yearlyPkg?.storeProduct.priceString ?? '\$34.99',
                            period: 'one-time',
                            savings: 'Save 65%',
                            isPopular: true,
                            isLoading: sub.isPurchasing,
                            onTap: () => ref
                                .read(subscriptionProvider.notifier)
                                .purchase(yearlyPkg),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                    const SizedBox(height: 16),

                    // What you get
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'What you get',
                            style: AppTypography.titleMedium(color: AppColors.primary),
                          ),
                          const SizedBox(height: 12),
                          for (final item in [
                            '15 progressive sessions (easy → hard)',
                            'AI adapts to your pace and level',
                            'XP, streak & achievement badges',
                            'Smart daily notifications',
                            'No subscription — own it forever',
                          ])
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded,
                                      size: 16, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(item,
                                        style: AppTypography.bodySmall(
                                            color: AppColors.primaryDark)),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
                    const SizedBox(height: 24),

                    // Restore Purchases
                    TextButton(
                      onPressed: sub.isRestoring
                          ? null
                          : () => ref
                                .read(subscriptionProvider.notifier)
                                .restore(),
                      child: sub.isRestoring
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Restore Purchases',
                              style: AppTypography.bodySmall(
                                color: context.textSecondary,
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),

                    // Social proof
                    Text(
                      'Join 10,000+ speakers improving daily',
                      style: AppTypography.bodySmall(
                        color: context.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String feature;
  final String free;
  final String pro;
  final IconData? freeIcon;
  final IconData? proIcon;
  final Color? freeIconColor;

  const _FeatureRow({
    required this.feature,
    required this.free,
    required this.pro,
    this.freeIcon,
    this.proIcon,
    this.freeIconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(feature, style: AppTypography.bodySmall()),
        ),
        Expanded(
          flex: 2,
          child: Center(
            child: freeIcon != null
                ? Icon(
                    freeIcon,
                    size: 18,
                    color: freeIconColor ?? AppColors.success,
                  )
                : Text(
                    free,
                    style: AppTypography.labelSmall(
                      color: context.textSecondary,
                    ),
                  ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Center(
            child: proIcon != null
                ? Icon(proIcon, size: 18, color: AppColors.success)
                : Text(
                    pro,
                    style: AppTypography.labelSmall(color: AppColors.primary),
                  ),
          ),
        ),
      ],
    );
  }
}

class _PricingCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final String? savings;
  final bool isPopular;
  final bool isLoading;
  final VoidCallback onTap;

  const _PricingCard({
    required this.title,
    required this.price,
    required this.period,
    this.savings,
    required this.isPopular,
    this.isLoading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: isLoading ? null : onTap,
      child: Opacity(
        opacity: isLoading ? 0.6 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isPopular ? AppColors.primaryLight : AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPopular ? AppColors.primary : const Color(0xFFE5E5E5),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              if (isPopular)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Most Popular',
                    style: AppTypography.labelSmall(color: AppColors.white),
                  ),
                ),
              Text(title, style: AppTypography.labelMedium()),
              const SizedBox(height: 4),
              Text(price, style: AppTypography.headlineLarge()),
              Text(
                period,
                style: AppTypography.labelSmall(color: context.textSecondary),
              ),
              if (savings != null) ...[
                const SizedBox(height: 4),
                Text(
                  savings!,
                  style: AppTypography.labelSmall(color: AppColors.success),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
