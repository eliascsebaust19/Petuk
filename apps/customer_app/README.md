# Foodie Birganj — Customer App (Phase 1 MVP) 🍛

The **Petuk / Foodie Birganj** customer app: Birganj Pourashava's hyperlocal
food-delivery platform, built exactly to the finalized SRS
(`birganj_4_apps_srs_report.pdf`, `birganj_food_delivery_srs_report.pdf`).

> Branding note: the SRS calls the product **Foodie Birganj (ফুডি বীরগঞ্জ)**;
> the final brand mark is **Petuk (পেটুক)** — the logo and rider animation in
> `assets/images/` are the Petuk assets from the repo root.

- **Platform:** Flutter (latest stable, 100% null safety), Android & iOS
- **State management:** `flutter_bloc` (BLoC/Cubit pattern)
- **Theme:** Deep Teal `#0D9488` · Food Amber `#F59E0B` · Dark Slate `#0F172A`
- **Typography:** Hind Siliguri — **bundled** (4 weights) for instant Bangla
  rendering on 2G/3G with zero runtime font downloads
- **Money:** whole-BDT integer math, Bengali digits everywhere (৳৩৫০)

---

## 🚀 Getting started

The repo ships all Dart code, assets and platform **overlays**; the
machine-generated `android/`/`ios/` runner projects are created by the
Flutter tool via a one-time bootstrap:

```bash
cd apps/customer_app
./tool/bootstrap.sh     # flutter create . + overlays + pub get
flutter run             # attached Android device / emulator / iOS simulator
```

Other commands:

```bash
flutter test            # CartBloc rules + BD phone validation unit tests
flutter analyze         # static analysis (flutter_lints + strict rules)
flutter build apk --release
```

Requirements: Flutter **≥ 3.29** (latest stable recommended), Dart ≥ 3.7.

## 🧪 Demo mode (Phase 1 backend)

Phase 1 of the SRS intentionally runs **without partner apps** — orders are
forwarded to the ops team manually. This build ships complete, runnable
*mock repositories* implementing the same contracts the real API will use:

| Area | Demo behavior |
| --- | --- |
| **OTP** | A real random 6-digit code is generated and shown in an amber "ডেমো মোড" banner (tap to copy). Expiry (5 min), 60 s resend cooldown and the 3-wrong → 5-min lock are all enforced. |
| **Session** | Persisted via `shared_preferences` — login survives restarts. Logout from the home header avatar menu. |
| **Catalog** | The 8 launch partners of Birganj with full menus, variants (১:১ / ১:২, ৬"/৯", পাউন্ড, কেজি), spice levels, cake-writing notes, one stock-out item and one closed restaurant. |
| **Coupons** | `FIRSTFREE` (free delivery), `WELCOME40` (flat ৳40, min ৳150), `PETUK10` (10%, cap ৳60, min ৳250). |
| **Orders** | Placing an order starts the timed pipeline: PENDING → (15 s) PREPARING → (40 s) rider assigned, ON_THE_WAY → (80 s) DELIVERED. A seeded delivered order from "yesterday" fills the history tab. |
| **Wallets** | bKash/Nagad run as Send-Money to a merchant number + TrxID capture (the real Phase-1 ops flow). Numbers in `AppConstants` are placeholders — replace before launch. |

Swap point: `lib/main.dart` — replace the three `Mock*Repository` instances
with API-backed implementations of the same interfaces. `core/network/`
already contains the production Dio client (timeouts, bearer-token
interceptor, localized error mapping) and endpoint table
(`--dart-define=PETUK_API_BASE_URL=…`).

## 📁 Project structure (feature-first)

```
lib/
├── main.dart                  # DI entry point (swap mocks → API here)
├── app.dart                   # Repositories → app-wide BLoCs → MaterialApp
├── core/
│   ├── constants/             # business rules, asset paths, API endpoints
│   ├── theme/                 # SRS palette + Hind Siliguri theme
│   ├── network/               # Dio client + ApiException (Phase 2 ready)
│   ├── router/                # named routes + global navigator keys
│   ├── utils/                 # BD phone validation, Bangla formatting
│   └── widgets/               # PrimaryButton, QuantityStepper, BillRow, …
├── data/
│   ├── models/                # Restaurant, FoodItem, CartItem, Coupon,
│   │                          # DeliveryAddress, Order, Rider, UserSession…
│   ├── repositories/          # abstract contracts + mock implementations
│   └── sources/               # bundled Birganj launch catalog
└── features/
    ├── auth/                  # splash (logo fade), phone login (rider GIF),
    │   │                      # OTP (60 s timer, autofill, 3-strike lock)
    │   ├── bloc/              # AuthBloc, PhoneLoginCubit, OtpBloc
    │   ├── pages/  └── widgets/
    ├── home/                  # shell + tabs, location zones, search,
    │   │                      # category chips, promo banners, menu page,
    │   │                      # food detail sheet (variants/spice/notes)
    ├── cart/                  # ⭐ CartBloc (single-restaurant rule) + UI
    ├── checkout/              # landmark address form + COD/bKash/Nagad
    └── orders/                # live list, 4-step tracking, rider card,
                               # handover OTP card
```

## ⭐ CartBloc — the core rules

`features/cart/bloc/` (`cart_event.dart`, `cart_state.dart`, `cart_bloc.dart`)

1. **Single restaurant (QA-02):** adding from a different restaurant never
   mutates the cart — the bloc emits `pendingAddition`, a global listener
   shows the *"কার্ট খালি করে যোগ করুন?"* dialog from any screen, and
   `CartAdditionConfirmed` / `CartAdditionCancelled` resolve it.
2. **Merge identity:** same food + variant + spice level + note merges
   quantity (max 20/line); any difference is a separate line.
3. **Derived bill:** `subtotal + flat ৳30 fee − coupon discount = grand
   total` — all computed getters, never stored, so they cannot drift.
4. **Coupon lifecycle:** validated against the repository, re-checked on
   every mutation; drops below minimum → auto-removed with a notice.
   Empty cart → restaurant + coupon reset.

These invariants are covered by `test/cart_bloc_test.dart`.

## 🗺️ SRS traceability

| SRS requirement | Where |
| --- | --- |
| FR-C01 OTP (+880, 6-digit, 60 s resend, auto-read) | `features/auth/` + `core/utils/bd_phone.dart` |
| FR-C02 discovery (open/busy, 30–45 min ETA, distance) | `features/home/` + `RestaurantCard` |
| FR-C03 search, chips, variants, spice, notes | `HomeBloc`, `FoodDetailSheet` |
| FR-C04 single-restaurant cart, promo, landmark address | `CartBloc`, `CheckoutPage` |
| FR-C05 COD + bKash/Nagad, flat ৳30 | `PaymentMethodSelector`, `BillSummary` |
| FR-C06 4-step tracking + rider + handover OTP | `features/orders/` |
| QA-01 wrong-OTP lockout | `OtpBloc` (3 strikes → 5 min) |
| QA-02 cart-clear prompt | `CartConflictListener` |
| QA-04 slow network | bundled font, offline catalog, emoji visuals, cached images |
| NFR security | passwordless OTP, persisted token, TLS-ready Dio client |

## 📌 Phase-1 scope notes

- Cart & orders live in memory (session persists); hydration/`hydrated_bloc`
  and FCM push arrive with the Phase-2 backend.
- `imageUrl` fields are null in the bundled catalog (lightweight emoji
  visuals); `CachedNetworkImage` renders real photos automatically once
  the API supplies URLs.
- Rider GPS map view lands with the Rider App (Phase 3); tracking here is
  the 4-step pipeline + rider contact, per the Phase-1 SRS.
- Replace demo phone numbers in `core/constants/app_constants.dart`
  (ops SIM, bKash/Nagad merchants) before the Play Store launch.
