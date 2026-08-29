# Smart Wardrobe

**[Open the live demo →](https://vatsal057.github.io/Smart-Wardrobe/)** — the same
Flutter code running in your browser, with SQLite compiled to WebAssembly and a
wardrobe already filled in so the outfit scoring has something to score. The web
build drops photo capture, because a browser has no app documents directory to
write the files to.

Offline-first, AI-powered wardrobe management app for Android, built with Flutter and SQLite.

The promise: open the app and see exactly what to wear today; on Sunday evening see your full week planned; get warned before you run out of clean clothes. Free, no ads, no subscription — all data stays on-device.

## Features

- **Today screen** — a scored outfit suggestion for the day, at a glance
- **7-day planner** — plan the week's outfits ahead of time
- **Wash tracking** — wear counts and wash badges warn you before clean clothes run out
- **Wardrobe insights** — capsule analysis, usage stats, streaks, and wardrobe "health" ring
- **Packing lists** — build trip packing from your actual wardrobe
- Leica × Editorial dark theme across 11 screens

## Repository layout

- `smart_wardrobe_app/` — the Flutter app (screens, components, providers, services)
- `smart_wardrobe_blueprint_v7_offline_first.md` — full product blueprint (final, offline-first)
- `smart_wardrobe_blueprint_v6_antigravity_v2.md` — earlier blueprint revision
- `implementation_plan.md`, `task.md`, `walkthrough.md` — build planning and walkthrough docs

## Build

```sh
cd smart_wardrobe_app
flutter pub get
flutter build apk --release
```

## License

MIT
