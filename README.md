# Petuk 🍛 — Foodie Birganj

Hyperlocal food delivery for **Birganj Upazila, Dinajpur, Bangladesh**.
Petuk (পেটুক) connects Birganj Pourashava's customers, restaurants and
part-time college riders on one platform — with a fair **10–12% commission**,
**COD-first payments** (bKash/Nagad supported), landmark-based addresses and
a flat **৳30** delivery fee.

![Petuk logo](Max_a_achhaaa_Petuk_er_jnn.png)

## Repository layout

| Path | What it is |
| --- | --- |
| **`apps/customer_app/`** | 📱 **Customer App (Phase 1 MVP)** — complete Flutter codebase (BLoC, Bangla-first UI, OTP auth, cart, checkout, live order tracking). See its [README](apps/customer_app/README.md) to run it. |
| `birganj_4_apps_srs_report.pdf` | SRS: 4-app ecosystem + phased development roadmap (Customer → Admin → Rider → Restaurant POS) |
| `birganj_food_delivery_srs_report.pdf` | Full proposal: architecture, UI/UX guide, DB schema, API integrations, test plan |
| `birganj_food_delivery_report.pdf` | Market analysis & business plan (unit economics, break-even ≈ 13–15 orders/day, launch strategy) |
| `Max_a_achhaaa_Petuk_er_jnn.png` | Petuk brand wordmark (source asset) |
| `petuk_intro.mp4` / `petuk_rider.gif` | Intro video & rider animation (the GIF ships in the app as the login animation) |

## Quick start (customer app)

```bash
cd apps/customer_app
./tool/bootstrap.sh   # one-time: generates android/ios runners + pub get
flutter run
```

Requires Flutter (latest stable). The app runs end-to-end in **demo mode**
(mock OTP banner, bundled Birganj catalog, timed order pipeline) until the
central backend goes live — see the app README for details and the
Phase-2 swap points.

## Roadmap (from the SRS)

1. **Phase 1 (Day 1–25):** Customer App MVP ← *this repo*
2. **Phase 2 (Day 26–45):** Super Admin web dashboard (Next.js)
3. **Phase 3 (20–25+ orders/day):** Rider App (Flutter, live GPS, OTP handover)
4. **Phase 4 (10+ restaurants):** Restaurant POS app (Flutter tablet)

## License

[MIT](LICENSE) © 2026 Md Elias Ahmad
