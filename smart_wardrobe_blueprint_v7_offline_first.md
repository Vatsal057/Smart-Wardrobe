# Smart Wardrobe — Complete Product Blueprint
> Version 7.0 · FINAL · Offline-First Android · Flutter + sqflite
>
> **Hand this document to Antigravity to build the full product.**
> Every section is self-contained. Every function called is defined somewhere here.
> Build Phase 1 completely — it produces a working APK with zero backend dependency.

---

## 0. Executive Summary

An offline-first AI-powered wardrobe management Android app built with Flutter.

**Core promise to user:**
1. Open the app → see exactly what to wear today
2. Sunday evening → see your full week planned
3. Before you run out of clean clothes → app warns you to wash

**Cost:** Free forever. No subscription. No ads.
**Platform:** Android (Flutter) — all data stored locally on-device via SQLite.
**Architecture:** Fully self-contained. No backend server needed for Phase 1.

### Phase Roadmap

| Phase | Scope | Status |
|-------|-------|--------|
| **Phase 1** (this blueprint) | Offline-first Flutter app, sqflite, local scoring, all 11 screens, debug APK | **BUILD THIS** |
| Phase 2 (future) | Google OAuth, FastAPI backend, cloud sync | Planned |
| Phase 3 (future) | Push notifications (Firebase FCM), scheduled jobs | Planned |
| Phase 4 (future) | Gemini AI photo polish, template generation, style notes | Planned |
| Phase 5 (future) | Nano Banana custom icon set, PC web frontend (Streamlit) | Planned |

---

## 1. Architecture (Phase 1 — Offline-First)

```
┌──────────────────────────────────────┐
│         Android Phone                │
│                                      │
│  ┌────────────────────────────────┐  │
│  │     Flutter App (Dart)         │  │
│  │                                │  │
│  │  ┌────────┐  ┌──────────────┐  │  │
│  │  │ Screens │  │  ApiService   │  │  │
│  │  │  (11)   │──│  (local ops) │  │  │
│  │  └────────┘  └──────┬───────┘  │  │
│  │                     │          │  │
│  │              ┌──────▼───────┐  │  │
│  │              │ LocalDatabase│  │  │
│  │              │  (sqflite)   │  │  │
│  │              └──────────────┘  │  │
│  │                                │  │
│  │  ┌──────────────────────────┐  │  │
│  │  │ Photo Storage            │  │  │
│  │  │ (app documents dir)      │  │  │
│  │  └──────────────────────────┘  │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```

**Key design decision:** `ApiService` is a static class with the **same method signatures** you'd use for an HTTP client. Every screen calls `ApiService.xyz()`. In Phase 2, you swap the implementation to HTTP calls — screens stay unchanged.

---

## 2. Tech Stack (Phase 1)

| Layer | Technology | Why |
|-------|-----------|-----|
| Framework | Flutter 3.x (Dart) | Single codebase, native performance |
| Local DB | sqflite | SQLite on-device, no server needed |
| State | Provider (ChangeNotifier) | Simple, built-in Flutter pattern |
| Auth | Local username (SharedPreferences) | No Google OAuth needed for offline |
| Photos | Local filesystem (path_provider) | Camera/gallery → app documents dir |
| Outfit scoring | Dart math (formality + color + freshness) | Deterministic, no ML needed |
| Color harmony | Classic combo lookup table | Deterministic |
| Wear + wash tracking | Counter + threshold logic | Simple, reliable |
| Typography | Google Fonts (Cormorant Garamond + DM Sans) | Matches design language |
| Icons | Material Icons | Placeholder — Nano Banana SVGs in Phase 5 |

### Flutter Dependencies (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
  provider: ^6.1.0
  shared_preferences: ^2.2.0
  image_picker: ^1.0.0
  cached_network_image: ^3.3.0
  google_fonts: ^6.2.0
  intl: ^0.20.0
  path_provider: ^2.1.0
  sqflite: ^2.3.0
  path: ^1.9.0
```

> **Note:** `http` and `cached_network_image` are kept for Phase 2 compatibility but are not used in Phase 1.

---

## 3. Project File Structure

```
smart_wardrobe_app/
├── pubspec.yaml
├── lib/
│   ├── main.dart                    ← App entry, Provider setup, routing
│   ├── theme.dart                   ← Design system (§5)
│   ├── providers/
│   │   └── auth_provider.dart       ← Auth state management
│   ├── services/
│   │   ├── api.dart                 ← ALL data operations (local sqflite)
│   │   └── local_database.dart      ← SQLite schema + CRUD helpers
│   ├── screens/
│   │   ├── login_screen.dart        ← Name entry (no server URL)
│   │   ├── today_screen.dart        ← Daily outfit recommendation
│   │   ├── wardrobe_screen.dart     ← Grid of all items
│   │   ├── add_item_screen.dart     ← Add new clothing item
│   │   ├── week_screen.dart         ← 7-day outfit planner
│   │   ├── wash_screen.dart         ← Wash tracking + batch wash
│   │   ├── generate_screen.dart     ← Generate by occasion
│   │   ├── packing_screen.dart      ← Trip packing list
│   │   ├── insights_screen.dart     ← Health ring + capsule analysis
│   │   ├── stats_screen.dart        ← Wardrobe statistics
│   │   └── settings_screen.dart     ← User prefs + logout
│   └── components/
│       ├── outfit_card.dart         ← Outfit display with score + actions
│       ├── clothing_photo.dart      ← Photo widget (local file + network)
│       ├── score_labels.dart        ← Score breakdown pills
│       ├── wash_badge.dart          ← Wash status indicator
│       ├── health_ring.dart         ← Animated health score ring
│       └── streak_badge.dart        ← Streak counter
├── android/
│   └── (standard Flutter Android project)
└── test/
    └── widget_test.dart
```

### Build Order
1. `theme.dart` — design system tokens
2. `local_database.dart` — SQLite schema
3. `api.dart` — all business logic
4. `auth_provider.dart` — auth state
5. Components: `clothing_photo` → `outfit_card` → `wash_badge` → `health_ring` → `streak_badge` → `score_labels`
6. Screens: `login_screen` → `today_screen` → `wardrobe_screen` → `add_item_screen` → `week_screen` → `wash_screen` → `generate_screen` → `packing_screen` → `insights_screen` → `stats_screen` → `settings_screen`
7. `main.dart` — tie everything together

---

## 4. Database Schema (SQLite / sqflite)

`local_database.dart` creates all tables on first launch.

```sql
CREATE TABLE IF NOT EXISTS users (
    id                      INTEGER PRIMARY KEY AUTOINCREMENT,
    username                TEXT UNIQUE NOT NULL,
    name                    TEXT,
    email                   TEXT,
    city                    TEXT DEFAULT 'Mumbai',
    streak_count            INTEGER DEFAULT 0,
    streak_updated          TEXT,
    api_key                 TEXT,
    notify_enabled          INTEGER DEFAULT 1,
    weekly_plan_enabled     INTEGER DEFAULT 1,
    wash_notify_enabled     INTEGER DEFAULT 1,
    weather_anomaly_enabled INTEGER DEFAULT 1,
    created_at              TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS wardrobe (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id             TEXT NOT NULL,
    name                TEXT NOT NULL,
    category            TEXT NOT NULL DEFAULT 'top',  -- top | bottom | shoes | accessory
    color               TEXT DEFAULT 'black',
    warmth              INTEGER DEFAULT 5,            -- 1–10
    formality           INTEGER DEFAULT 5,            -- 1–10
    waterproof          INTEGER DEFAULT 0,
    season              TEXT DEFAULT 'all',            -- all | summer | winter | monsoon
    photo_url           TEXT,                          -- local file path
    photo_template_url  TEXT,
    photo_status        TEXT DEFAULT 'none',           -- none | processing | ready | failed
    gemini_description  TEXT,
    wear_count          INTEGER DEFAULT 0,
    first_worn          TEXT,
    last_worn           TEXT,
    wash_count          INTEGER DEFAULT 0,
    wash_threshold      INTEGER DEFAULT 3,
    needs_wash          INTEGER DEFAULT 0,
    last_washed         TEXT,
    preference          REAL DEFAULT 50.0,             -- EMA score 0–100
    is_archived         INTEGER DEFAULT 0,
    created_at          TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS outfit_memory (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id     TEXT NOT NULL,
    item_ids    TEXT NOT NULL,          -- comma-separated IDs
    occasion    TEXT DEFAULT 'casual',
    worn_date   TEXT,
    created_at  TEXT DEFAULT CURRENT_TIMESTAMP
);
```

### Wash threshold defaults by category
```dart
const washDefaults = {
  'top':       2,     // shirts/tees — wash after 2 wears
  'bottom':    5,     // jeans/trousers — realistic for hostel life
  'shoes':     15,
  'accessory': 10,
};
```

---

## 5. UI Design Language

> **Aesthetic Direction: Leica × Fashion Editorial**
>
> Not tech. Not startup. Not "clean and modern."
> Think: the weight of a Leica camera. The precision of a Braun clock.
> A fashion magazine printed on thick paper.
> Dark, precise, warm gold as a single signature accent.
> Every screen should feel designed once, correctly, and never needing to change.

### 5.1 Core Principles

| Principle | In practice |
|-----------|------------|
| **Restraint** | One accent color. Two font families. No gradients except hero button. |
| **Photography First** | Clothing photos are the visual hero. UI chrome recedes behind them. |
| **Purposeful Density** | Not too sparse, not cluttered. Every element earns its pixel. |
| **Tactile Depth** | Surfaces feel layered through subtle opacity — not drop shadows. |
| **Timeless Typography** | Serif for emotion. Geometric sans for precision. |
| **Motion with Restraint** | One entry animation per screen. Micro-interactions on tap only. Never looping. |

### 5.2 Color System

Implement as a `class AppColors` with static const `Color` values.

```
Background layers:
  bgBase:      #09090B
  bgSurface1:  #111114
  bgSurface2:  #17171A
  bgSurface3:  #1E1E22

Borders:
  borderSubtle:  #252529
  borderDefault: #2E2E33
  borderFocus:   #3E3E46

Gold accent — used SPARINGLY, max 3 elements per screen:
  gold:       #C9A96E
  goldHi:     #DFBE84
  goldDim:    #8A7045
  goldFaint:  #C9A96E14  (8% opacity)
  goldTint:   #C9A96E28  (16% opacity)

Text:
  textPrimary:   #EDE8DE
  textSecondary: #8A8A96
  textTertiary:  #4A4A54
  textGold:      #C9A96E

Semantic — max 2 semantic colors per screen:
  green:       #5DBB8C    greenFaint: #5DBB8C14
  red:         #D96464    redFaint:   #D9646414
  amber:       #D4A846    amberFaint: #D4A84614
```

### 5.3 Typography

Implement using `google_fonts` package. Create named `TextStyle` constants in `AppTheme`.

```
Display font:  Cormorant Garamond (serif)
  → outfit headlines, screen titles, hero moments
  → weights: 300 (light), 400 (regular), 600 (semibold)

UI font:       DM Sans (geometric sans-serif)
  → all UI labels, buttons, data, metadata, inputs
  → weights: 300, 400, 500 — NEVER 600+

Type Scale (AppTheme static getters):
  display:    Cormorant 44px / w300 / height 1.15
  title:      Cormorant 32px / w400 / height 1.2
  subtitle:   Cormorant 22px / w400 italic / height 1.3
  body:       DM Sans 15px  / w400 / height 1.7
  label:      DM Sans 12px  / w500 / letterSpacing 0.06em / UPPERCASE
  caption:    DM Sans 11px  / w400 / textSecondary
  micro:      DM Sans 10px  / w500 / letterSpacing 0.10em / UPPERCASE
  button:     DM Sans 15px  / w500 / color #1A1208 (warm dark)
  metricValue: Cormorant 32px / w300 / textPrimary
```

### 5.4 Spacing & Layout

Implement as `class AppSpacing` with static const `double` values.

```
Base unit: 4px

Scale:  xs=4  sm=8  md=16  lg=24  xl=36  xxl=56

Border radius:
  radiusSm=8  radiusMd=12  radiusLg=18  radiusXl=24  radiusFull=9999

Standard card:
  background:    bgSurface1
  border:        0.5px solid borderSubtle
  border-radius: radiusLg (18)
  padding:       lg (24)
  gap:           md (16)

Screen edge padding: xl (36)
Bottom nav height:   72px + safe area
```

### 5.5 Iconography

**Phase 1:** Use Material Icons as placeholders. Map icon names to Material equivalents:

| Function | Material Icon |
|----------|--------------|
| Today | `Icons.wb_sunny_outlined` |
| Wardrobe | `Icons.checkroom` |
| Week | `Icons.calendar_today_outlined` |
| Wash | `Icons.local_laundry_service_outlined` |
| Generate | `Icons.auto_awesome` |
| Packing | `Icons.luggage_outlined` |
| Stats | `Icons.bar_chart` |
| Insights | `Icons.diamond_outlined` |
| Settings | `Icons.settings_outlined` |

**Phase 5 (future):** Replace with custom Nano Banana thin-stroke SVG icons. Each icon generated with this prompt template:
```
"Minimal single-color SVG icon for [icon_name].
Style: ultra-thin stroke, 1.5px weight, rounded line caps and joins,
no fill, pure outline. 24×24px viewbox.
Aesthetic: premium fashion app, Leica-inspired precision.
Color: #C9A96E on transparent background.
No gradients, no shadows, no decorative elements."
```

### 5.6 Component Specifications

**Bottom Navigation Bar** (MainShell in `main.dart`)
```
Height: 72px + safe area
Background: bgSurface1 @ 85% opacity
Border top: 0.5px solid borderSubtle
Active tab: icon + label gold
Inactive: icon + label textTertiary
Font: DM Sans 10px / w500 / UPPERCASE
Tabs: Today | Wardrobe | Week | Generate | Settings
  → Other screens accessible via navigation from these tabs
```

**Primary Button (Gold gradient)**
```
Background: LinearGradient(gold → goldHi)
Text: #1A1208 (warm dark), DM Sans 15px / w500
Padding: 14px 24px · Height: 52px · Radius: radiusSm (8)
Loading state: CircularProgressIndicator replaces text
```

**Card**
```
Background: bgSurface1 · Border: 0.5px solid borderSubtle · Radius: radiusLg (18)
Padding: lg (24)
```

**Input Field**
```
Background: bgSurface2 · Border: 1px solid borderSubtle → focus: goldDim
Radius: radiusSm (8) · Padding: 12px 16px · Height: 52px
Font: DM Sans 15px / w400 · Text: textPrimary · Hint: textTertiary
```

**Status Badge (pill shape)**
```
Font: DM Sans 10px / w500 / UPPERCASE / 0.10em
Padding: 3px 10px · Radius: radiusFull (pill)
Background: semantic-faint · Text: semantic color · Border: 1px solid semantic @ 30%
```

### 5.7 Outfit Card Visual Design

```
Photo display: ClothingPhoto widgets for each item in the outfit
  → Items shown in a horizontal scrollable strip (44×56px thumbnails)

Score badge:
  Background: bgSurface2 · Text: gold, DM Sans 13px / w500

Outfit headline:
  Cormorant 22px / w300 / italic · e.g. "Perfect casual look with Blue Oxford"

Action row (two buttons):
  "Next look →" (ghost)  |  "✓ Wearing this" (gold gradient)
```

---

## 6. Authentication (`auth_provider.dart` + `login_screen.dart`)

### Phase 1 (Offline)
- Login screen shows only a **name field** — no server URL, no password
- On submit: create or retrieve user in local SQLite
- Store username in `SharedPreferences` for auto-login on app restart
- Logout: clear SharedPreferences, reset user state

### Phase 2 (Future — Google OAuth)
- Replace name login with Google Sign-In button
- Backend issues Fernet-encrypted session tokens
- `ApiService` switches to HTTP calls with `X-Session-Token` header

---

## 7. Core Service Layer

### `local_database.dart` — SQLite CRUD

Provides raw database operations:
- `createOrGetUser(username)` → user map
- `getUser(username)` → user map or null
- `updateUser(username, fields)` → updated user
- `getWardrobe(userId)` → list of item maps
- `addWardrobeItem(userId, itemData)` → created item
- `getItem(id)` → item map
- `updateItem(id, fields)` → updated item
- `deleteItem(id)` → void
- `addOutfitMemory(userId, itemIds, occasion, date)` → void
- `getRecentOutfits(userId, occasion)` → list of outfit maps

### `api.dart` — Business Logic (Static Methods)

All screens call `ApiService.xyz()`. **Every method is static and returns `Future<Map/List>`.**

#### Auth Methods
```dart
static Future<void> init()                              // Load saved session
static Future<Map> login(username, {name, email})       // Create/get user
static Future<void> logout()                            // Clear session
static Future<Map> getMe()                              // Get current user
static Future<Map> updateMe(fields)                     // Update user prefs
static bool get isLoggedIn                              // Check session
```

#### Wardrobe Methods
```dart
static Future<List> getWardrobe({includeArchived})      // All items
static Future<Map> addWardrobeItem({name, category, color, warmth, formality, waterproof, season, photo})
static Future<void> deleteWardrobeItem(id)              // Delete + photo cleanup
static Future<Map> updateWardrobeItem(id, fields)       // Update item
static Future<Map> polishPhoto(itemId)                  // Stub (Phase 4)
```

#### Wear + Wash Methods
```dart
static Future<Map> wearItems(itemIds, {occasion})       // Wear count+, wash count+, streak, memory
static Future<Map> washItems(itemIds)                   // Reset wash counts
static Future<Map> getWashStatus()                      // Full wash status object
```

#### Recommendations
```dart
static Future<Map> getRecommendations({occasion, weatherOverride})  // Top 5 scored outfits
```

#### Planner
```dart
static Future<Map> getWeekPlan()                        // Current week plan
static Future<Map> generatePlan({occasions})            // Regenerate plan
static Future<void> markDayWorn(date)                   // Mark day as worn
```

#### Insights
```dart
static Future<Map> getHealthScore()                     // 0-100 score + components
static Future<Map> getCapsule()                         // Versatile, orphans, gaps, color story
static Future<Map> getStreak()                          // Current streak + message
```

#### Packing
```dart
static Future<Map> generatePackingList({destination, days})  // Smart packing list
```

#### Stats
```dart
static Future<Map> getStats()                           // Full stats object
```

---

## 8. Wash Tracking System

Built into `ApiService.wearItems()` and `ApiService.getWashStatus()`.

**Logic:**
- Every `wearItems()` call increments `wash_count` for each worn item
- `needs_wash = (wash_count >= wash_threshold)`
- `washItems()` resets `wash_count = 0`, sets `last_washed = today`
- Smart batching: urgency based on total count rather than per-item nagging

**Wash urgency levels:**
- `critical` — 4+ items need washing
- `medium` — 1–3 items need washing
- `low` — all clean

**Wash status response shape:**
```json
{
  "urgency": "medium",
  "message": "3 item(s) need washing.",
  "needs_wash_count": 3,
  "clean_tops": 5,
  "clean_bottoms": 3,
  "items_needing_wash": [...],
  "wash_soon_items": [...]
}
```

---

## 9. 7-Day Outfit Planner

Built into `ApiService.getWeekPlan()` and `ApiService.generatePlan()`.

**Algorithm:**
1. Get all clean, unarchived items
2. For each day (Mon–Sun), select top + bottom (+ optional shoes/accessory)
3. Enforce rotation: track used items, prefer unused ones per week
4. Score each outfit using the recommendation algorithm (§12)
5. Assign occasions: weekdays=casual/smart_casual, Saturday=date, Sunday=casual

**Response shape:**
```json
{
  "days": [
    {
      "date": "2026-03-23",
      "day_name": "Monday",
      "occasion": "casual",
      "outfit": {"item_ids": [...], "items": [...], "headline": "...", "score": 78.5},
      "weather": {"temp_c": 28, "rain_pct": 15},
      "confirmed": false,
      "worn": false
    }
  ]
}
```

---

## 10. Wardrobe Intelligence

### 10.1 Wardrobe Health Score

Single 0–100 score shown as an animated ring on the Insights screen.

**Components:**
| Component | Weight | Calculation |
|-----------|--------|-------------|
| utilization | 40% | items worn at least once / total |
| rotation | 30% | 1 − (stdev of wear_counts / mean) — clamped 0–1 |
| freshness | 20% | clean items (not needs_wash) / total |
| wash | 10% | items within wash threshold / total |

**Score = utilization×40 + rotation×30 + freshness×20 + wash×10** (rounded integer)

### 10.2 Capsule Wardrobe Analysis

Four analyses, all computed locally from wardrobe data:

1. **Most Versatile** — top 3 items by wear_count
2. **Orphan Items** — items with wear_count = 0 (never worn)
3. **Wardrobe Gaps** — check for missing categories or low counts
4. **Color Story** — count items per color, surface top 5 colors

### 10.3 Streak Tracking

Built into `ApiService.wearItems()`:
- If items worn today and yesterday was a wear day → increment streak
- If gap → reset to 1
- Messages escalate: Day 1 → Week 1 (🔥) → 2 weeks (🔥🔥) → Month (🔥🔥🔥)

---

## 11. Photo Storage (Phase 1)

- Camera/gallery images saved to app's documents directory: `wardrobe_photos/`
- Filename: `photo_{timestamp}.jpg`
- `ClothingPhoto` widget detects local paths vs network URLs:
  - Path starts with `/` or contains `\` → `Image.file()`
  - Otherwise → `Image.network()`
- On item delete, photo file is also deleted

---

## 12. Recommendation Algorithm

**Filter before scoring:**
```
available = items where:
  needs_wash = 0 (FALSE)
  is_archived = 0 (FALSE)
```

**Scoring function (Dart):**
```
score = 60 (base)

+ formality match:  (10 - |item.formality - target|) × 1.5 per item
    target by occasion: casual=3, smart_casual=5, semi_formal=7, formal=9,
                       date=6, outdoor=3, party=6

+ color harmony:    +5 for variety (>1 color), +8 for classic combos
    classic combos: black+white, navy+white, navy+khaki, blue+brown,
                   grey+navy, white+blue, cream+navy, denim+white, etc.

+ freshness:        +3 per never-worn item

+ preference:       (item.preference - 50) / 10 per item

- memory penalty:   -8 if ≥75% overlap with last 10 outfits for same occasion
```

**Generate headline:**
```
"{adj} {occasion} look with {top_name}"
  adj: score>80→Perfect, >65→Great, >50→Good, else→Decent
```

**Return top 5 outfits sorted by score.**

---

## 13. Screen Specifications

### 13.1 LoginScreen
- Cormorant display: "Smart" (textPrimary) + "Wardrobe" (gold)
- Subtitle: "Your personal wardrobe intelligence."
- Caption: "All data stored locally on your device."
- Name text field with person icon
- Gold gradient "Enter Wardrobe" button
- Error text in red if name is empty

### 13.2 TodayScreen
- Title: "Today" (Cormorant title)
- Weather row: temperature + rain % (from recommendation data)
- Wash warning banner (amber) if present
- OutfitCard showing current recommendation
- "Next look →" and "✓ Wearing this" actions
- Pull-to-refresh to regenerate
- Empty state: "Add items to your wardrobe" with checkroom icon

### 13.3 WardrobeScreen
- Title: "Wardrobe" (Cormorant title)
- Grid view of all items (2 columns)
- Each item: ClothingPhoto + name + category/color labels
- Tap item → detail bottom sheet with delete option
- FAB: "+" → navigates to AddItemScreen
- Polish button on each item (stub message in Phase 1)

### 13.4 AddItemScreen
- AppBar: "Add Item" with close button
- Photo picker area (camera or gallery)
- Name text field
- Category segmented: top | bottom | shoes | accessory
- Color picker: 21 color circles with check mark on selected
- Warmth slider: 1–10 (Cool/breathable ↔ Very warm)
- Formality slider: 1–10 (Very casual ↔ Very formal)
- Season segmented: all | summer | monsoon | winter
- Waterproof toggle switch
- Gold gradient "Add to Wardrobe" button
- Returns `true` to previous screen on success

### 13.5 WeekScreen
- Title: "Week" (Cormorant title)
- Rotation score percentage
- Wash alert banner (amber) if present
- Horizontal scrollable day cards (130px wide):
  - Day name (3-letter uppercase) + date
  - Weather: temp + rain %
  - Outfit headline (2-line max)
  - Wash warning icon if applicable
  - Gold border if confirmed
- Below: detailed OutfitCard for each day with "Wearing this" action
- FAB: refresh icon → regenerate plan

### 13.6 WashScreen
- Title: "Wash" (Cormorant title)
- Urgency banner (color-coded: red/amber/green)
- Stats row: Clean tops | Clean bottoms | Needs wash
- "NEEDS WASH" section with checkboxes
- "WASH SOON" section
- Empty state: "All clean!" with green check icon
- Bottom action bar: "Mark N as washed" (gold gradient)

### 13.7 GenerateScreen
- Title: "Generate" (Cormorant title)
- Occasion selector: casual, smart_casual, semi_formal, formal, date, outdoor, party
- Gold gradient "Generate Outfits" button
- OutfitCard with "Wearing this" action + outfit counter (1/5)
- "Next" to cycle through generated outfits

### 13.8 PackingScreen
- Title: "Packing" (Cormorant title)
- Destination text field
- Days selector: 3 | 5 | 7 | 10 (tappable boxes)
- Gold gradient "Generate Packing List" button
- Tip banner (gold-faint)
- Packing list grouped by category with item names

### 13.9 InsightsScreen
- Title: "Insights" (Cormorant title)
- StreakBadge (lg) with message
- HealthRing (animated SVG-style circle, fills 0→score)
  - Color: red(0–39) → amber(40–59) → gold(60–89) → green(90–100)
  - Center: score number + label
- 4 component chips: Utilization | Rotation | Freshness | Wash (as %)
- Capsule analysis cards:
  - Most Versatile (star icon)
  - Orphan Items (help icon)
  - Wardrobe Gaps (lightbulb icon)
  - Color Story (palette icon)

### 13.10 StatsScreen
- Title: "Stats" (Cormorant title)
- Metric cards (2-column grid): Total Items | Total Wears | Never Worn | With Photos | Clean | Needs Wash
- "BY CATEGORY" — horizontal bar chart per category
- "MOST WORN" — ranked list with wear count
- "HIGHEST PREFERENCE" — ranked list with preference %

### 13.11 SettingsScreen
- Title: "Settings" (Cormorant title)
- User info card: avatar circle (first letter) + name + email
- City text field (editable, submit on enter)
- Notification toggles: Daily Outfit | Weekly Plan | Wash Reminders | Weather Alerts
- Gemini API key field (Phase 4, kept as UI placeholder)
- Logout button (red-faint background)

---

## 14. Main App Structure (`main.dart`)

```dart
// Entry point:
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..init(),
      child: const SmartWardrobeApp(),
    ),
  );
}

// SmartWardrobeApp:
//   - MaterialApp with dark theme
//   - Routes: '/' → LoginScreen or MainShell (based on auth state)
//   - '/add' → AddItemScreen

// MainShell:
//   - BottomNavigationBar with 5 tabs
//   - IndexedStack of 5 screens (preserve state)
//   - Tab 0: TodayScreen
//   - Tab 1: WardrobeScreen
//   - Tab 2: WeekScreen
//   - Tab 3: GenerateScreen
//   - Tab 4: SettingsScreen
//   - Other screens (Wash, Packing, Insights, Stats) accessible via
//     navigation from the main tabs or settings
```

---

## 15. Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Offline-first with sqflite | App works immediately on install, no server setup needed |
| ApiService as static class | Same signatures for local and future HTTP modes — zero screen changes when switching |
| Wash filter before scoring | Dirty clothes are not available for outfits |
| Smart wash batching (3+ threshold) | Per-item nagging is annoying. Batch when it's a real load |
| Bottom wash threshold = 5 | Jeans in hostel/PG life are worn 4-6 times before washing |
| `outfit_memory` table | Prevents repeating same outfit at same occasion |
| Health Score as animated ring | Universally understood as progress. Legible at a glance |
| Leica × Editorial UI | Restraint is harder than decoration. Designed once, correctly |
| Cormorant + DM Sans | Cormorant for emotion (headlines). DM Sans for clarity (data) |
| Single gold accent | One accent used sparingly feels like a signature |
| Material Icons (Phase 1) | Fast to implement. Nano Banana SVGs replace in Phase 5 |
| Local photo storage | No R2/cloud needed. Camera photos go straight to app dir |
| No subscription | Daily habit is the product's value. Paywalls break the habit loop |

---

## 16. Build & Verification

### Create Project
```bash
flutter create --org com.smartwardrobe --project-name smart_wardrobe_app --platforms android ./smart_wardrobe_app
```

### Build APK
```bash
cd smart_wardrobe_app
flutter pub get
flutter analyze          # Must show 0 errors
flutter build apk --debug
```

### Verification Checklist
1. APK installs on phone without errors
2. App opens to login screen — NO server URL field
3. Enter name → taps "Enter Wardrobe" → enters main app
4. Bottom nav shows 5 tabs, all load without errors
5. Add Item: can take photo, fill all fields, save successfully
6. Today: shows recommendation (or empty state if no items)
7. Wardrobe: shows grid of added items with photos
8. Week: shows 7-day plan, can regenerate
9. Wash: shows clean/dirty status, can batch wash
10. Generate: can pick occasion and generate outfits
11. Packing: can enter destination/days and generate list
12. Insights: health ring displays, capsule analysis shows
13. Stats: metrics display correctly
14. Settings: can change city, toggle notifications, logout
15. After logout, app returns to login screen

---

## 17. Future Phases (NOT part of Phase 1 build)

### Phase 2 — Google OAuth + Backend
- Add FastAPI backend with PostgreSQL
- Google OAuth 2.0 (both mobile and web)
- `ApiService` switches to HTTP calls
- Cloud sync between devices
- Cloudflare R2 for photo storage

### Phase 3 — Push Notifications
- Firebase FCM integration
- Notification types: daily_outfit, weekly_plan, template_ready, wash_reminder, weather_anomaly, first_wear, streak_milestone, season_transition
- APScheduler for scheduled jobs
- One notification per type per user per day

### Phase 4 — Gemini AI Integration
- `rembg` for background removal (server-side)
- Gemini 2.0 Flash for template generation (user API key)
- Gemini 1.5 Flash for style notes (user API key)
- Photo pipeline: original → remove background → generate template → extract style tags

### Phase 5 — Polish
- Custom Nano Banana thin-stroke SVG icon set (40+ icons)
- PC web frontend (Streamlit)
- iOS support (APNs)
- Advanced: combo-level preference learning, outfit calendar view

---

*End of blueprint v7.0 — FINAL. Build Phase 1 to get a working APK.*
