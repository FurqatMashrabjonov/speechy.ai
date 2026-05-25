import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_coach/app/theme/app_colors.dart';
import 'package:speech_coach/app/theme/app_typography.dart';
import 'package:speech_coach/core/extensions/context_extensions.dart';
import 'package:speech_coach/app/theme/app_images.dart';
import 'package:speech_coach/core/analytics/analytics_service.dart';
import 'package:speech_coach/features/paywall/domain/track_tier.dart';
import 'package:speech_coach/features/paywall/presentation/providers/subscription_provider.dart';
import 'package:speech_coach/shared/widgets/tappable.dart';

class PaywallScreen extends ConsumerWidget {
  final String trackId;
  final String trackTitle;

  const PaywallScreen({
    super.key,
    required this.trackId,
    required this.trackTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(subscriptionProvider);

    ref.listen<SubscriptionState>(subscriptionProvider, (prev, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.error!)));
      }
      final purchased = next.tierForTrack(trackId);
      if (purchased != null && prev?.tierForTrack(trackId) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Track unlocked! Happy practicing.')),
        );
        context.pop();
      }
    });

    final bannerPath = AppImages.trackBannerMap[trackId];
    final bg = context.background;
    const tier = TrackTier.full;
    final price = sub.packageForTrack(trackId)?.storeProduct.priceString ??
        tier.fallbackPrice;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Banner fading into background
          if (bannerPath != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 260,
              child: ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.transparent],
                  stops: [0.55, 1.0],
                ).createShader(rect),
                blendMode: BlendMode.dstIn,
                child: SizedBox.expand(
                  child: Image.asset(bannerPath, fit: BoxFit.cover),
                ),
              ),
            ),

          SafeArea(
            child: Column(
              children: [
                // Close
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      Tappable(
                        onTap: () => context.pop(),
                        child:
                            const Icon(Icons.close_rounded, size: 24),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 110),

                        Text(
                          'Unlock $trackTitle',
                          style: AppTypography.headlineMedium(),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 60.ms, duration: 300.ms),

                        const SizedBox(height: 4),
                        Text(
                          'Buy once, own forever.',
                          style: AppTypography.bodySmall(
                              color: context.textSecondary),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

                        const SizedBox(height: 28),

                        // Feature card
                        _FeatureCard(price: price)
                            .animate()
                            .fadeIn(delay: 140.ms, duration: 280.ms)
                            .slideY(
                                begin: 0.06,
                                end: 0,
                                duration: 280.ms,
                                curve: Curves.easeOut),

                        const SizedBox(height: 16),

                        // Free session note
                        Text(
                          'First session always free — no card required.',
                          style: AppTypography.bodySmall(
                              color: context.textTertiary),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 200.ms, duration: 280.ms),
                      ],
                    ),
                  ),
                ),

                // Sticky CTA
                Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    MediaQuery.of(context).padding.bottom + 12,
                  ),
                  decoration: BoxDecoration(
                    color: bg,
                    border: Border(top: BorderSide(color: context.divider)),
                  ),
                  child: _PurchaseButton(
                    trackId: trackId,
                    price: price,
                    isLoading: sub.isPurchasing,
                  ).animate().fadeIn(delay: 240.ms),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feature Card ──────────────────────────────────────────────────────────────

class _FeatureCard extends StatelessWidget {
  final String price;

  const _FeatureCard({required this.price});

  static const _features = [
    (Icons.lock_open_rounded, 'All 15 steps unlocked'),
    (Icons.replay_rounded, '3 attempts per step — retry until you nail it'),
    (Icons.bolt_rounded, 'Real-time AI coach · low-latency audio'),
    (Icons.star_rounded, 'Detailed score card after every session'),
    (Icons.all_inclusive_rounded, 'Yours forever · no subscription'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Full Access',
                style: AppTypography.titleLarge()
                    .copyWith(fontWeight: FontWeight.w800),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: AppTypography.titleLarge(color: AppColors.primary)
                        .copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'one-time',
                    style:
                        AppTypography.labelSmall(color: context.textTertiary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(f.$1, size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      f.$2,
                      style: AppTypography.bodyMedium(
                          color: context.textPrimary),
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

// ── Purchase Button ───────────────────────────────────────────────────────────

class _PurchaseButton extends ConsumerWidget {
  final String trackId;
  final String price;
  final bool isLoading;

  const _PurchaseButton({
    required this.trackId,
    required this.price,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tappable(
      onTap: isLoading
          ? null
          : () {
              AnalyticsService.instance.logPurchaseInitiated(
                trackId: trackId,
                tier: TrackTier.full.revenueCatIdentifier,
              );
              ref.read(subscriptionProvider.notifier).purchaseTier(
                    trackId: trackId,
                    tier: TrackTier.full,
                  );
            },
      child: AnimatedOpacity(
        opacity: isLoading ? 0.7 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  ),
                )
              : Text(
                  'Unlock Track — $price',
                  style: AppTypography.titleMedium(color: Colors.white)
                      .copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
        ),
      ),
    );
  }
}
