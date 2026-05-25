# Speechy AI — Monetization & Pricing Plan

## Model: Track Unlock + Coin Economy

User buys a track once (lifetime curriculum access) + coin bundle.
Coins consumed in real-time during AI sessions (1 coin = 1 minute).
When coins run out → buy top-up pack. No subscription.

---

## Cost Structure (per session)

```
Session duration:          5 minutes
Gemini Live API (compressed): $0.076
Infrastructure overhead:   $0.024
Total cost per session:    $0.100
Store fee:                 15% (Small Business Program)
```

Context compression is active: triggerTokens=12000, slidingWindow=6000
Cuts API cost ~51% vs uncompressed sessions.

NOTE: ThinkingConfig not available in LiveGenerationConfig (Firebase AI
Flutter SDK v3.12.1). Monitor future SDK releases. If exposed, set
thinkingLevel = minimal to prevent hidden reasoning token charges.

---

## Track Structure

```
Average steps per track:   15 scenarios
1 step = 1 session = 5 min = 5 coins

Complete track (1x):       15 sessions = 75 coins
Complete track (with retry): 30 sessions = 150 coins
```

---

## Pricing Tiers (Track Unlock — one-time, lifetime)

Decoy effect applied: mid-tier priced higher per-coin to push Power Pack.

| Tier        | Price | Coins | Sessions | $/coin  | Use case                        |
|-------------|-------|-------|----------|---------|---------------------------------|
| Quick Prep  | $1.99 | 15    | 3        | $0.133  | "Interview tomorrow"            |
| Full Access | $4.99 | 75    | 15       | $0.066  | Complete track once             |
| Power Pack  | $7.99 | 175   | 35       | $0.045  | Full track + retries (BEST)     |

Asymmetric dominance: Power Pack is 2.3x coins for 1.6x price vs Full Access.
Target: 60% of buyers self-select Power Pack.

### Unit Economics (100% coin usage, worst case)

| Tier        | Net Revenue | API Cost | Profit | Margin |
|-------------|-------------|----------|--------|--------|
| Quick Prep  | $1.69       | $0.30    | $1.39  | 82%    |
| Full Access | $4.24       | $1.50    | $2.74  | 64%    |
| Power Pack  | $6.79       | $3.50    | $3.29  | 48%    |

Minimum $1.39 profit even at 100% usage. Average usage ~65% → margins higher.

---

## Consumable Coin Top-Up Packs

Same pricing as track tiers (after initial bundle exhausted):

| Pack   | Price | Coins | Sessions | $/coin  |
|--------|-------|-------|----------|---------|
| Bronze | $1.99 | 15    | 3        | $0.133  |
| Silver | $4.99 | 75    | 15       | $0.066  |
| Gold   | $7.99 | 175   | 35       | $0.045  |

---

## Onboarding

5 free coins on signup = 1 free 5-min session.
No credit card required. Immediate value before paywall.

---

## UI: Dual-Label (Always show coins + sessions)

Never show coins alone. Always pair:
  "75 Practice Coins — 15 full sessions"
  "175 Practice Coins — 35 full sessions"

Prevents confusion, builds trust.

---

## Paywall Timing

### Soft Gate (post-session, balance < 5 coins)
- Trigger: session ends, balance drops below 5
- Location: score card screen, after metrics shown
- Message: "Great work! Top up to continue your momentum."
- Non-blocking: user can dismiss

### Hard Gate (pre-session, balance = 0)
- Trigger: user taps "Start Session", balance < 5
- Location: blocking paywall screen
- Message: "You need 5 coins to start a session. Top up to begin."
- Blocking: cannot dismiss without top-up

### NEVER
- Mid-session interruption (breaks flow, causes anxiety)
- Balance warnings during active conversation

---

## Coin Economy: Firestore Structure

```
users/{uid}/data/coins
  balance: 175          ← current coin balance
  lifetimeEarned: 180   ← for analytics
  lifetimeSpent: 5      ← for analytics
  lastUpdated: timestamp
```

### Pre-session check (BLOCKING)
Before WebSocket opens:
  Firestore read → balance >= 5 → allow
  balance < 5 → show hard gate paywall

### Real-time deduction (during session)
Timer: every 60 seconds → FieldValue.increment(-1) on balance
If balance hits 0 mid-session → send graceful end signal to AI → close WebSocket

### Post-session reconciliation
After session: deduct remaining seconds as fractional coins
(floor to nearest whole minute already charged)

---

## Regional Pricing (Day 1 via RevenueCat + App Store)

| Region           | Quick Prep | Full Access | Power Pack |
|------------------|------------|-------------|------------|
| US / Tier 1      | $1.99      | $4.99       | $7.99      |
| Western Europe   | €1.99      | €4.99       | €7.99      |
| Brazil           | R$4.99     | R$12.99     | R$19.99    |
| Mexico           | MXN$19     | MXN$49      | MXN$79     |
| India            | ₹59        | ₹149        | ₹249       |
| Indonesia        | Rp12,000   | Rp29,000    | Rp49,000   |
| Philippines      | ₱39        | ₱99         | ₱159       |

Configure via App Store Connect → Pricing & Availability → per-country.
RevenueCat reads localized price strings automatically.

---

## RevenueCat Products (to configure)

### Track unlock products (non-consumable, per-track)
Each track needs 3 products:
  {trackId}_quick    → Quick Prep
  {trackId}_full     → Full Access  
  {trackId}_power    → Power Pack

### Coin top-up products (consumable, global)
  coins_bronze       → Bronze pack
  coins_silver       → Silver pack
  coins_gold         → Gold pack

### Entitlements
  speechyai_quick    → unlocks track at Quick level
  speechyai_full     → unlocks track at Full level
  speechyai_power    → unlocks track at Power level

---

## Retention Mechanics

### 1. Calendar Integration
Onboarding question: "Do you have an upcoming event?"
If yes → countdown push notifications as event approaches
  "Interview in 48 hours — run a 5-min warmup now"

### 2. Streak Freeze (5 coins)
User about to lose streak → offer streak freeze for 5 coins
Recycles coins back into economy, triggers top-up sooner

### 3. Daily Micro-Warmup (free, 1 min)
Free 1-min warmup daily, no coins required
3 consecutive days → +1 free coin reward
Habit loop → keeps app top-of-mind between events

---

## Implementation Roadmap

### Phase 1 — Done ✅
- [x] Context window compression (51% cost reduction)
- [x] Free session counter → Firestore (prevents multi-device abuse)
- [x] Analytics gaps filled
- [x] Crashlytics wired

### Phase 2 — Pricing Fix (this sprint)
- [ ] TrackTier pricing: Quick $1.99 / Full $4.99 / Power $7.99
- [ ] TrackTier coins: 15 / 75 / 175
- [ ] PaywallScreen: dual-label UI
- [ ] PaywallScreen: 3 tiers with decoy visual hierarchy

### Phase 3 — Coin Economy
- [ ] coins_remote_repository.dart (Firestore balance R/W)
- [ ] coin_provider.dart (StateNotifier, pre-session check)
- [ ] conversation_provider.dart: real-time deduction (1 coin/min timer)
- [ ] conversation_provider.dart: graceful end when balance = 0
- [ ] score_card_screen.dart: soft gate post-session
- [ ] scenario_detail_screen.dart: hard gate pre-session

### Phase 4 — RevenueCat + Regional Pricing
- [ ] Production API keys (iOS + Android)
- [ ] Per-track product IDs in App Store Connect + Google Play
- [ ] Consumable coin pack products
- [ ] Regional pricing (15 countries)
- [ ] RevenueCat entitlement mapping

### Phase 5 — Retention
- [ ] Calendar event input (onboarding)
- [ ] Push notification triggers (event countdown)
- [ ] Streak freeze mechanic (5 coins)
- [ ] Daily micro-warmup (free 1 min)
- [ ] +1 coin reward after 3-day streak

---

## Key Rules (Never Violate)

1. Balance < 5 → session cannot start. Hard block.
2. Balance hits 0 mid-session → graceful end, no abrupt cut.
3. Never interrupt mid-session with payment UI.
4. Always show coins + sessions together (dual-label).
5. Coins never expire.
6. Track curriculum access never expires after purchase.
