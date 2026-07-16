# Smart Wardrobe — Implementation Plan

Build an AI-powered wardrobe management app: **Python FastAPI backend** (local SQLite, local file storage) + **Flutter/Dart Android app** following the Leica × Editorial design language from the blueprint.

## User Review Required

> [!IMPORTANT]
> **Local-only development**: No cloud services. SQLite replaces PostgreSQL, local file storage replaces R2, in-memory dict replaces Redis, push notifications are stubbed. All can be swapped to cloud later.

> [!IMPORTANT]
> **Auth simplification**: Google OAuth is stubbed for local dev. The app will use a simple username-based login that creates a local session token. The OAuth flow structure is preserved so it can be swapped in later.

> [!WARNING]
> **rembg + onnxruntime**: These are large dependencies (~500MB). The photo background removal pipeline will be included but may take time to install. If this is a concern, I can stub it initially.

> [!IMPORTANT]
> **Gemini API for template generation**: The blueprint uses the user's own Gemini API key. For local dev, the template generation and style notes will be stubbed with placeholder responses. The API key input screen is still built so it works when a key is provided.

---

## Proposed Changes

### Backend — Core Infrastructure

#### [NEW] [database.py](file:///c:/Users/Vatsal/Desktop/SMart%20wardrobe/backend/database.py)
- SQLite via `aiosqlite` (drop-in for local dev, same schema as blueprint §4)
- All 7 tables: `users`, `wardrobe`, `weekly_plan`, `outfit_memory`, `device_tokens`, `notification_log`, `capsule_cache`
- All indexes, auto-create on startup

#### [NEW] [storage.py](file:///c:/Users/Vatsal/Desktop/SMart%20wardrobe/backend/storage.py)
- Local file storage in `./uploads/` directory
- Same API shape as R2 (upload, get_url, delete)

#### [NEW] [cache.py](file:///c:/Users/Vatsal/Desktop/SMart%20wardrobe/backend/cache.py)
- In-memory dict with TTL support (replaces Redis)

#### [NEW] [job_queue.py](file:///c:/Users/Vatsal/Desktop/SMart%20wardrobe/backend/job_queue.py)
- asyncio.Semaphore-based queue for rate-limiting Gemini calls

---

### Backend — Intelligence Modules

#### [NEW] [weather_client.py](file:///c:/Users/Vatsal/Desktop/SMart%20wardrobe/backend/modules/weather_client.py)
- Open-Meteo API wrapper (free, no key needed)
- 7-day forecast by city name (geocode → forecast)

#### [NEW] [color_harmony.py](file:///c:/Users/Vatsal/Desktop/SMart%20wardrobe/backend/modules/color_harmony.py)
- HSL-based color harmony scoring for outfit combinations
- Complementary, analogous, triadic harmony detection

#### [NEW] [fuzzy_scorer.py](file:///c:/Users/Vatsal/Desktop/SMart%20wardrobe/backend/modules/fuzzy_scorer.py)
- scikit-fuzzy outfit scoring: warmth, waterproof, formality, color, preference, freshness

#### [NEW] [wash_tracker.py](file:///c:/Users/Vatsal/Desktop/SMart%20wardrobe/backend/wash_tracker.py)
- Pure functions: check wash status, compute urgency levels, generate wash alerts

#### [NEW] [health_score.py](file:///c:/Users/Vatsal/Desktop/SMart%20wardrobe/backend/health_score.py)
- 0–100 health score: utilization (40%), rotation (30%), freshness (20%), wash (10%)

#### [NEW] [capsule_analysis.py](file:///c:/Users/Vatsal/Desktop/SMart%20wardrobe/backend/capsule_analysis.py)
- Versatility matrix, orphan items, wardrobe gaps, color story

#### [NEW] [planner.py](file:///c:/Users/Vatsal/Desktop/SMart%20wardrobe/backend/planner.py)
- 7-day outfit planner using weather + fuzzy scorer + rotation constraints

---

### Backend — API & Services

#### [NEW] [main.py](file:///c:/Users/Vatsal/Desktop/SMart%20wardrobe/backend/main.py)
- FastAPI app with all endpoints from blueprint §11
- Auth, Wardrobe, Recommendations, Planner, Insights, Packing, Stats
- Lifespan: init DB, start scheduler

#### [NEW] [photo_pipeline.py](file:///c:/Users/Vatsal/Desktop/SMart%20wardrobe/backend/photo_pipeline.py)
- rembg background removal, thumbnail generation
- Gemini visual description + style tags (stubbed without API key)

#### [NEW] [scheduler.py](file:///c:/Users/Vatsal/Desktop/SMart%20wardrobe/backend/scheduler.py)
- APScheduler with all 6 jobs (stubbed notifications for local)

#### [NEW] [notifications.py](file:///c:/Users/Vatsal/Desktop/SMart%20wardrobe/backend/notifications.py)
- Stub implementation (logs notifications instead of sending FCM)

#### [NEW] [requirements.txt](file:///c:/Users/Vatsal/Desktop/SMart%20wardrobe/backend/requirements.txt)
- All Python dependencies (adapted for local: `aiosqlite` instead of `asyncpg`)

---

### Flutter App — Foundation

#### [NEW] Flutter project scaffolded via `flutter create`
- Package: `smart_wardrobe_app` in `c:\Users\Vatsal\Desktop\SMart wardrobe\`

#### [NEW] [theme.dart](file:///c:/Users/Vatsal/Desktop/SMart%20wardrobe/lib/theme.dart)
- Full design system from §5: colors, typography (Cormorant Garamond + DM Sans), spacing, component styles

#### [NEW] [api.dart](file:///c:/Users/Vatsal/Desktop/SMart%20wardrobe/lib/services/api.dart)
- HTTP client using `http` package, all endpoint methods, session token management

#### [NEW] [auth_provider.dart](file:///c:/Users/Vatsal/Desktop/SMart%20wardrobe/lib/providers/auth_provider.dart)
- ChangeNotifier for auth state, login/logout, user data

---

### Flutter App — 11 Screens

Each screen follows blueprint §14 specifications adapted for Flutter with Material Icons:

| Screen | Key Features |
|---|---|
| `LoginScreen` | Simple username login (local dev) |
| `ApiKeyScreen` | Gemini API key input |
| `TodayScreen` | Daily outfit card with score, notes, actions |
| `WeekScreen` | Horizontal day cards, bottom sheet outfit detail |
| `WardrobeScreen` | Grid of clothing items with photos, add FAB |
| `AddItemScreen` | Form with camera/gallery photo, category, color, warmth, formality |
| `WashScreen` | Urgency banner, category sections, batch wash |
| `GenerateScreen` | Occasion selector, weather override, generate outfits |
| `PackingScreen` | Destination, days, occasions, generate packing list |
| `InsightsScreen` | Health ring, capsule cards, streak badge |
| `StatsScreen` | Metric cards with wardrobe statistics |
| `SettingsScreen` | Notification toggles, city, preferences |

---

### Flutter App — Shared Components

| Component | Description |
|---|---|
| `OutfitCard` | Photo grid, score badge, AI notes, action buttons |
| `ClothingPhoto` | Cached image with processing/status overlay |
| `ScoreLabels` | Score breakdown chips |
| `HealthRing` | Animated circular progress with color coding |
| `WashBadge` | Color-coded wash status pill |
| `WeekDayCard` | Day card with weather, occasion, outfit preview |
| `StreakBadge` | Fire icon with streak count, milestone animation |
| `TemplateStatus` | Processing/ready/failed indicator |

---

## Verification Plan

### Automated Tests

1. **Backend API tests**: Script that tests all endpoints sequentially
   ```
   cd backend
   pip install -r requirements.txt
   python -m pytest test_api.py -v
   ```
   Tests: health check, create user, add wardrobe item, get recommendations, wear item, wash item, get stats, get insights

2. **Flutter analysis**: Verify no Dart analysis errors
   ```
   flutter analyze
   ```

3. **Flutter build**: Verify the APK builds
   ```
   flutter build apk --debug
   ```

### Manual Verification

1. **Start backend**: `cd backend && python main.py` — verify it starts on `localhost:8000` with no errors
2. **Start Flutter app**: `flutter run` on Android emulator or physical device
3. **End-to-end flow**:
   - Login with test username
   - Add 5+ wardrobe items with photos
   - Get daily outfit recommendation
   - Tap "Wearing this" to confirm
   - Check wash status updates
   - Generate weekly plan
   - View insights and stats
4. **Ask user to test on their Android device** since I cannot run an Android emulator
