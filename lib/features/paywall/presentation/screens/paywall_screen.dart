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

class PaywallScreen extends ConsumerStatefulWidget {
  final String trackId;
  final String trackTitle;

  const PaywallScreen({
    super.key,
    required this.trackId,
    required this.trackTitle,
  });

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  TrackTier _selected = TrackTier.power;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logPaywallViewed(trackId: widget.trackId);
  }

  @override
  Widget build(BuildContext context) {
    final sub = ref.watch(subscriptionProvider);

    ref.listen<SubscriptionState>(subscriptionProvider, (prev, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.error!)));
      }
      final purchased = next.tierForTrack(widget.trackId);
      if (purchased != null && prev?.tierForTrack(widget.trackId) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${purchased.displayName} unlocked! ${purchased.coinsLabel} added.',
            ),
          ),
        );
        context.pop();
      }
    });

    final bannerPath = AppImages.trackBannerMap[widget.trackId];
    final bg = context.background;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // ── Banner background fading into screen color ──────────────
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

          // ── Main content on top ─────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Close button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      Tappable(
                        onTap: () => context.pop(),
                        child: const Icon(Icons.close_rounded, size: 24),
                      ),
                    ],
                  ),
                ),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 120),
                        Text(
                          'Unlock ${widget.trackTitle}',
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

                        const SizedBox(height: 20),

                        // Tier cards
                        ...TrackTier.values.map((tier) {
                          return _TierCard(
                            tier: tier,
                            isSelected: _selected == tier,
                            price: sub
                                    .packageForTier(tier)
                                    ?.storeProduct
                                    .priceString ??
                                tier.fallbackPrice,
                            onTap: () => setState(() => _selected = tier),
                          )
                              .animate(delay: ((tier.index + 1) * 60).ms)
                              .fadeIn(duration: 250.ms)
                              .slideY(
                                  begin: 0.06,
                                  end: 0,
                                  duration: 250.ms,
                                  curve: Curves.easeOut);
                        }),
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
                    tier: _selected,
                    trackId: widget.trackId,
                    price: sub
                            .packageForTier(_selected)
                            ?.storeProduct
                            .priceString ??
                        _selected.fallbackPrice,
                    isLoading: sub.isPurchasing,
                  ).animate().fadeIn(delay: 250.ms),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tier Card ─────────────────────────────────────────────────────────────────

class _TierCard extends StatelessWidget {
  final TrackTier tier;
  final bool isSelected;
  final String price;
  final VoidCallback onTap;

  const _TierCard({
    required this.tier,
    required this.isSelected,
    required this.price,
    required this.onTap,
  });

  static const _features = {
    TrackTier.quick: [
      'Access first 3 steps of the track',
      '1 retry per step',
    ],
    TrackTier.full: [
      'Complete all 15 steps — full curriculum',
      '2 retries per step',
    ],
    TrackTier.power: [
      'Complete all 15 steps — full curriculum',
      '3 retries — practice until you nail it',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final isBest = tier.isBestValue;
    final color = isSelected ? AppColors.primary : context.divider;

    return Tappable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.07)
              : context.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Radio indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : context.textTertiary,
                  width: isSelected ? 6 : 2,
                ),
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        tier.displayName,
                        style: AppTypography.titleMedium(
                          color: isSelected ? AppColors.primary : null,
                        ).copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (isBest) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Best Value',
                            style: AppTypography.labelSmall(color: Colors.white)
                                .copyWith(fontWeight: FontWeight.w700, fontSize: 9),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  // Dual-label: coins + sessions
                  Text(
                    tier.coinsLabel,
                    style: AppTypography.bodySmall(
                      color: isSelected
                          ? AppColors.primary
                          : context.textSecondary,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 5),
                  ..._features[tier]!.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_rounded,
                              size: 13,
                              color: isSelected
                                  ? AppColors.primary
                                  : context.textTertiary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                f,
                                style: AppTypography.bodySmall(
                                  color: isSelected
                                      ? context.textPrimary
                                      : context.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: AppTypography.titleLarge(
                    color: isSelected ? AppColors.primary : context.textPrimary,
                  ).copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  'one-time',
                  style: AppTypography.labelSmall(color: context.textTertiary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Purchase Button ───────────────────────────────────────────────────────────

class _PurchaseButton extends ConsumerWidget {
  final TrackTier tier;
  final String trackId;
  final String price;
  final bool isLoading;

  const _PurchaseButton({
    required this.tier,
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
                tier: tier.revenueCatIdentifier,
              );
              ref.read(subscriptionProvider.notifier).purchaseTier(
                trackId: trackId,
                tier: tier,
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
                  'Get ${tier.displayName} — $price',
                  style: AppTypography.titleMedium(color: Colors.white)
                      .copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
        ),
      ),
    );
  }
}
