# Smart Wardrobe — Complete Product Blueprint
> Version 6.0 · FINAL · Dual-Platform (PC + Android) · Production-Ready
>
> **Hand this document to Antigravity to build the full product.**
> Every section is self-contained. Every function called is defined somewhere here.

---

## 0. Executive Summary

A dual-platform AI-powered wardrobe management app.

**Core promise to user:**
1. Open the app → see exactly what to wear today
2. Sunday evening → see your full week planned
3. Before you run out of clean clothes → app warns you to wash

**Cost:** Free forever. No subscription. No ads.
**Platforms:** Android (React Native/Expo) + PC web app (Streamlit), same FastAPI backend.

---

## 1. Architecture

```
┌────────────────────┐    ┌─────────────────────┐
│  PC (Streamlit)    │    │  Android             │
│  localhost:8501    │    │  React Native/Expo   │
└────────┬───────────┘    └──────────┬───────────┘
         │  HTTP + X-Session-Token   │
         └─────────────┬─────────────┘
                       │
             ┌─────────▼──────────┐
             │   FastAPI Backend  │
             │   Railway (cloud)  │
             └───┬────┬────┬──────┘
                 │    │    │
        ┌────────▼┐ ┌─▼──┐ ┌▼──────────┐
        │Postgres │ │ R2 │ │  Firebase  │
        │(Railway)│ │    │ │    FCM     │
        └─────────┘ └────┘ └────────────┘
                            ┌────────────┐
                            │   Redis    │
                            │  (Railway) │
                            └────────────┘
```

---

## 2. Tech Stack

| Layer | Technology | Why |
|---|---|---|
| Backend | Python 3.11 + FastAPI | Async, serves both clients |
| PC Frontend | Streamlit | Rapid iteration |
| Android | React Native (Expo) | Cross-platform |
| Database | PostgreSQL (Railway) | Cloud, concurrent-safe |
| Auth | Google OAuth 2.0 | Both platforms |
| Background removal | `rembg` (server-side) | Free, offline |
| Template generation | Gemini 2.0 Flash Image (user key) | Free tier, queued |
| Style notes | Gemini 1.5 Flash (user key) | Free tier, cached |
| Outfit scoring | scikit-fuzzy (CI modules) | Deterministic, explainable |
| Color harmony | HSL module (CI) | Deterministic |
| Wear + wash tracking | EMA + threshold logic | Adaptive, free |
| Photo storage | Cloudflare R2 | Free 10GB, CDN |
| Push notifications | Firebase FCM | Free, no limits |
| Cache | Redis (Railway) | Persistent across restarts |
| Job queue | asyncio.Semaphore | Rate-limit safe |
| Scheduler | APScheduler | Daily jobs, wash checks |
| Weather | Open-Meteo API | Free, no key, 7-day forecast |

---

## 3. Project File Structure

```
smart_wardrobe/
│
├── backend/
│   ├── main.py
│   ├── photo_pipeline.py
│   ├── job_queue.py
│   ├── cache.py
│   ├── notifications.py
│   ├── scheduler.py
│   ├── storage.py
│   ├── database.py
│   ├── wash_tracker.py
│   ├── planner.py
│   ├── health_score.py
│   ├── capsule_analysis.py
│   ├── requirements.txt
│   ├── Procfile
│   ├── client_secrets.json
│   ├── firebase_service_account.json
│   └── modules/
│       ├── color_harmony.py         ← CI: HSL color scoring
│       ├── fuzzy_scorer.py          ← CI: scikit-fuzzy outfit scoring
│       └── weather_client.py        ← Open-Meteo wrapper
│
├── pc_frontend/
│   └── frontend.py
│
└── android/
    ├── app.json
    ├── App.tsx
    ├── google-services.json
    ├── src/
    │   ├── api.ts
    │   ├── auth.ts
    │   ├── notifications.ts
    │   ├── theme.ts
    │   ├── icons.ts
    │   ├── screens/
    │   │   ├── LoginScreen.tsx
    │   │   ├── ApiKeyScreen.tsx
    │   │   ├── TodayScreen.tsx
    │   │   ├── WeekScreen.tsx
    │   │   ├── WardrobeScreen.tsx
    │   │   ├── AddItemScreen.tsx
    │   │   ├── WashScreen.tsx
    │   │   ├── GenerateScreen.tsx
    │   │   ├── PackingScreen.tsx
    │   │   ├── StatsScreen.tsx
    │   │   ├── InsightsScreen.tsx
    │   │   └── SettingsScreen.tsx
    │   └── components/
    │       ├── OutfitCard.tsx
    │       ├── ClothingPhoto.tsx
    │       ├── ScoreLabels.tsx
    │       ├── TemplateStatus.tsx
    │       ├── WashBadge.tsx
    │       ├── HealthRing.tsx
    │       ├── WeekDayCard.tsx
    │       └── StreakBadge.tsx
    └── package.json
```

Build order:
- Backend: `database.py` → `storage.py` → `job_queue.py` → `cache.py` → `wash_tracker.py` → `health_score.py` → `capsule_analysis.py` → `planner.py` → `notifications.py` → `scheduler.py` → `photo_pipeline.py` → `main.py`
- Android: `theme.ts` → `icons.ts` → `api.ts` → `auth.ts` → `notifications.ts` → components → screens → `App.tsx`

---

## 4. Database Schema (PostgreSQL)

`database.py` creates all tables on startup if they don't exist.

```sql
CREATE TABLE IF NOT EXISTS users (
    google_id               TEXT PRIMARY KEY,
    email                   TEXT NOT NULL,
    name                    TEXT,
    picture_url             TEXT,
    api_key                 TEXT,
    city                    TEXT DEFAULT 'Mumbai',
    notify_enabled          BOOLEAN DEFAULT FALSE,
    notify_time             TEXT DEFAULT '08:00',
    notify_occasion         TEXT DEFAULT 'casual',
    weekly_plan_enabled     BOOLEAN DEFAULT FALSE,
    wash_notify_enabled     BOOLEAN DEFAULT FALSE,
    weather_anomaly_enabled BOOLEAN DEFAULT FALSE,
    wash_notify_urgency     TEXT DEFAULT 'medium',  -- medium | high | critical
    streak_count            INTEGER DEFAULT 0,
    streak_updated          DATE,
    created_at              TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS wardrobe (
    id                  SERIAL PRIMARY KEY,
    user_id             TEXT NOT NULL REFERENCES users(google_id),
    name                TEXT NOT NULL,
    category            TEXT NOT NULL,       -- top | bottom | shoes | accessory
    color               TEXT NOT NULL,
    warmth              INTEGER DEFAULT 5,   -- 1–10
    formality           INTEGER DEFAULT 5,   -- 1–10
    waterproof          BOOLEAN DEFAULT FALSE,
    wear_count          INTEGER DEFAULT 0,
    last_worn           DATE,
    first_worn          DATE,                -- NULL until first use
    preference          REAL DEFAULT 50.0,   -- EMA score 0–100
    photo_url           TEXT,
    photo_template_url  TEXT,
    photo_status        TEXT DEFAULT 'none', -- none | processing | ready | failed
    style_tags          JSONB DEFAULT '[]',
    visual_description  TEXT,
    dominant_colors     JSONB DEFAULT '[]',
    wash_count          INTEGER DEFAULT 0,
    last_washed         DATE,
    wash_threshold      INTEGER DEFAULT 3,
    needs_wash          BOOLEAN DEFAULT FALSE,
    season              TEXT DEFAULT 'all',  -- all | summer | winter | monsoon
    is_archived         BOOLEAN DEFAULT FALSE,
    created_at          DATE DEFAULT CURRENT_DATE
);

CREATE TABLE IF NOT EXISTS weekly_plan (
    id          SERIAL PRIMARY KEY,
    user_id     TEXT NOT NULL REFERENCES users(google_id),
    plan_date   DATE NOT NULL,
    item_ids    JSONB NOT NULL,
    occasion    TEXT DEFAULT 'casual',
    confirmed   BOOLEAN DEFAULT FALSE,
    worn        BOOLEAN DEFAULT FALSE,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, plan_date)
);

CREATE TABLE IF NOT EXISTS outfit_memory (
    id          SERIAL PRIMARY KEY,
    user_id     TEXT NOT NULL REFERENCES users(google_id),
    item_ids    JSONB NOT NULL,
    occasion    TEXT NOT NULL,
    worn_at     DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS device_tokens (
    id          SERIAL PRIMARY KEY,
    user_id     TEXT NOT NULL REFERENCES users(google_id),
    fcm_token   TEXT NOT NULL,
    platform    TEXT DEFAULT 'android',
    last_seen   TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, fcm_token)
);

CREATE TABLE IF NOT EXISTS notification_log (
    id          SERIAL PRIMARY KEY,
    user_id     TEXT NOT NULL REFERENCES users(google_id),
    type        TEXT NOT NULL,
    sent_at     TIMESTAMPTZ DEFAULT NOW(),
    payload     JSONB
);

CREATE TABLE IF NOT EXISTS capsule_cache (
    user_id     TEXT PRIMARY KEY REFERENCES users(google_id),
    analysis    JSONB NOT NULL,
    computed_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_wardrobe_user     ON wardrobe(user_id);
CREATE INDEX IF NOT EXISTS idx_wardrobe_category ON wardrobe(user_id, category);
CREATE INDEX IF NOT EXISTS idx_wardrobe_status   ON wardrobe(user_id, photo_status);
CREATE INDEX IF NOT EXISTS idx_wardrobe_wash     ON wardrobe(user_id, needs_wash);
CREATE INDEX IF NOT EXISTS idx_wardrobe_season   ON wardrobe(user_id, season, is_archived);
CREATE INDEX IF NOT EXISTS idx_weekly_plan_user  ON weekly_plan(user_id, plan_date);
CREATE INDEX IF NOT EXISTS idx_outfit_memory     ON outfit_memory(user_id, occasion, worn_at);
CREATE INDEX IF NOT EXISTS idx_tokens_user       ON device_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_notif_user        ON notification_log(user_id, sent_at);
```

### Wash threshold defaults by category
```python
WASH_DEFAULTS = {
    "top":       2,    # shirts/tees — wash after 2 wears
    "bottom":    5,    # jeans/trousers — realistic for hostel life
    "shoes":     15,
    "accessory": 10,
}
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
|---|---|
| **Restraint** | One accent color. Two font families. No gradients except hero background. |
| **Photography First** | Clothing photos are the visual hero. UI chrome recedes behind them. |
| **Purposeful Density** | Not too sparse, not cluttered. Every element earns its pixel. |
| **Tactile Depth** | Surfaces feel layered through subtle opacity — not drop shadows. |
| **Timeless Typography** | Serif for emotion. Geometric sans for precision. |
| **Motion with Restraint** | One entry animation per screen. Micro-interactions on tap only. Never looping. |

### 5.2 Color System

```
Background layers:
  --bg-base:      #09090B
  --bg-surface-1: #111114
  --bg-surface-2: #17171A
  --bg-surface-3: #1E1E22

Borders:
  --border-subtle:  #252529
  --border-default: #2E2E33
  --border-focus:   #3E3E46

Gold accent — used SPARINGLY, max 3 elements per screen:
  --gold:       #C9A96E
  --gold-hi:    #DFBE84
  --gold-dim:   #8A7045
  --gold-faint: #C9A96E14
  --gold-tint:  #C9A96E28

Text:
  --text-primary:   #EDE8DE
  --text-secondary: #8A8A96
  --text-tertiary:  #4A4A54
  --text-gold:      #C9A96E

Semantic — max 2 semantic colors per screen:
  --green:       #5DBB8C    --green-faint: #5DBB8C14
  --red:         #D96464    --red-faint:   #D9646414
  --amber:       #D4A846    --amber-faint: #D4A84614
```

### 5.3 Typography

```
Display font:  Cormorant Garamond (serif)
  → outfit headlines, screen titles, hero moments
  → weights: 300 (light), 400 (regular), 600 (semibold)
  → italic variants for outfit names and quotes

UI font:       DM Sans (geometric sans-serif)
  → all UI labels, buttons, data, metadata, inputs
  → weights: 300, 400, 500 — NEVER 600+

NEVER USE: Inter, Roboto, SF Pro, system fonts.

Type Scale:
  Display:  Cormorant 44px / 300 / line-height 1.15
  Title:    Cormorant 32px / 400 / line-height 1.2
  Subtitle: Cormorant 22px / 400 italic / line-height 1.3
  Body:     DM Sans 15px  / 400 / line-height 1.7
  Label:    DM Sans 12px  / 500 / letter-spacing 0.06em / UPPERCASE
  Caption:  DM Sans 11px  / 400 / --text-secondary
  Micro:    DM Sans 10px  / 500 / letter-spacing 0.10em / UPPERCASE — status badges only
```

### 5.4 Spacing & Layout

```
Base unit: 4px

Scale:  xs=4px  sm=8px  md=16px  lg=24px  xl=36px  2xl=56px

Border radius:
  sm=8px  md=12px  lg=18px  xl=24px  full=9999px

Standard card:
  background:    --bg-surface-1
  border:        0.5px solid --border-subtle
  border-radius: lg (18px)
  padding:       lg (24px)
  gap:           md (16px)

Screen edge padding: xl (36px)
Bottom nav height:   72px + safe area
```

### 5.5 Iconography (Nano Banana)

All icons are custom thin-stroke SVGs generated by Nano Banana. Never mixed with emoji or system icons in functional UI.

**Prompt template for each icon:**
```
"Minimal single-color SVG icon for [icon_name].
Style: ultra-thin stroke, 1.5px weight, rounded line caps and joins,
no fill, pure outline. 24×24px viewbox.
Aesthetic: premium fashion app, Leica-inspired precision.
Color: #C9A96E on transparent background.
No gradients, no shadows, no decorative elements."
```

**Required icon set:**

Navigation: `today` (sun + ray) · `wardrobe` (open closet) · `week` (7-cell grid) · `wash` (water drop + circular arrow) · `generate` (lightning bolt) · `packing` (open suitcase) · `stats` (3 bars) · `insights` (diamond) · `settings` (gear)

Actions: `add` (plus circle) · `delete` (minus circle) · `camera` · `gallery` (image) · `wear` (checkmark circle) · `skip` (forward arrow circle) · `edit` (pencil)

Status: `clean` (droplet + checkmark) · `needs_wash` (droplet + !) · `wash_soon` (droplet + clock) · `processing` (dotted arc circle) · `ready` (4-point star) · `archived` (box + down arrow) · `waterproof` (shield + droplet)

Info: `weather` (cloud + partial sun) · `temperature` (thermometer) · `rain` (cloud + rain lines) · `occasion` (tie) · `color` (circle) · `formality` (suit) · `warmth` (thin flame)

Notification: `bell` · `notification` (bell + dot)

Insight: `health` (heart + activity line) · `streak` (thin fire) · `capsule` (pill shape) · `orphan` (item + ?) · `season` (leaf)

**Usage rules:**
- Nav tabs: 22px — `--text-tertiary` inactive, `--gold` active
- Action icons: 20px, `--text-secondary`
- Status badges: 14px, semantic color of the badge
- Processing state: `processing` icon with CSS rotation animation
- Never mix SVG icons and emoji in the same UI context

### 5.6 Component Specifications

**Bottom Navigation Bar**
```
Height: 72px + safe area
Background: --bg-surface-1 @ 85% opacity + blur(20px)
Border top: 0.5px solid --border-subtle
Active tab: icon + label --gold + 2px --gold underline dot
Inactive: icon + label --text-tertiary
Font: DM Sans 10px / 500 / UPPERCASE / 0.10em letter-spacing
Transition: color 200ms ease
```

**Primary Button**
```
Background: linear-gradient(135deg, #C9A96E, #DFBE84)
Text: #1A1208 (warm dark)
Font: DM Sans 15px / 500
Padding: 14px 24px
Border radius: sm (8px) · Height: 52px
Active: scale 0.97
Loading: thin spinner in --bg-base color, replaces text
```

**Ghost Button**
```
Background: transparent · Border: 1px solid --border-default · Text: --text-primary
Active: background --bg-surface-2 · Same dimensions as Primary
```

**Destructive Button**
```
Background: --red-faint · Border: 1px solid rgba(217,100,100,0.3) · Text: --red
```

**Card**
```
Background: --bg-surface-1 · Border: 0.5px solid --border-subtle · Border radius: lg (18px)
Padding: lg (24px)
On press: border-color → --border-default, scale 0.99 · Transition: 150ms ease
```

**Input Field**
```
Background: --bg-surface-2 · Border: 1px solid --border-subtle → focus: --gold-dim
Border radius: sm (8px) · Padding: 12px 16px · Height: 52px
Font: DM Sans 15px / 400 · Text: --text-primary · Placeholder: --text-tertiary
```

**Status Badge**
```
Font: DM Sans 10px / 500 / UPPERCASE / 0.10em
Padding: 3px 10px · Border radius: full (pill)
Background: semantic-faint · Text: semantic color · Border: 1px solid semantic @ 30%
```

**Metric Card**
```
Background: --bg-surface-2 · Border radius: md (12px) · Padding: 14px 16px
Label: DM Sans 10px / 500 / UPPERCASE / --text-tertiary
Value: Cormorant 32px / 300 / --text-primary
```

**Bottom Sheet**
```
Background: --bg-surface-1 · Border radius: xl xl 0 0 (24px top only)
Border: 0.5px solid --border-subtle (top + sides only)
Handle: 4×40px rect, --border-default, radius 2px, centered
Animation: translateY(100%) → 0, 280ms cubic-bezier(0.32,0.72,0,1)
Backdrop: rgba(0,0,0,0.88) + blur(10px) · Max height: 92vh
```

### 5.7 Screen Entry Animations

```
Standard enter: opacity 0→1 + translateY(12px)→0 · 380ms · cubic-bezier(0.16,1,0.3,1)
Children stagger: 40ms apart (max 5 staggered, rest appear instantly)

Outfit card reveal: photo grid scale 0.96→1.0 + text fade up · 420ms

Bottom sheet: translateY(100%)→0 · 280ms · cubic-bezier(0.32,0.72,0,1)

Tab switch: fade only, no slide · 180ms (avoids motion sickness on quick taps)

Rules:
  No looping animations · No animation > 500ms
  Reduced motion preference → all animations instant
```

### 5.8 Outfit Card Visual Design

```
Photo grid (2-column):
  ┌─────────────┬──────────┐
  │             │  shoes   │  top-right: 155px
  │    top      ├──────────┤
  │  (155px)    │accessory │  bottom-right: 120px
  ├─────────────┤  (120px) │
  │   bottom    │          │
  │  (120px)    │          │
  └─────────────┴──────────┘
  Gap: 2px · No border-radius on cells (full-bleed to card edge)

Score badge (top-right overlay):
  Background: rgba(0,0,0,0.72) + blur(8px) · Text: --gold, DM Sans 13px / 500
  Border: 1px solid rgba(201,169,110,0.3) · Border radius: md

Outfit headline:
  Cormorant 30px / 300 / italic · Format: "Clean City Casual" · margin-top: 18px

AI notes:
  icon (14px) + DM Sans 13px / --text-secondary · line-height 1.7 · gap 8px between notes

Item thumbnail strip (horizontal scroll, no visible scrollbar):
  Each: photo 44×56px (radius md) + DM Sans 9px / --text-tertiary name

Action row (two ghost buttons):
  "Next look →"  |  "✓ Wearing this"
```

---

## 6. Wash Tracking System (`wash_tracker.py`)

Pure functions, no database calls. Called by `main.py` and `scheduler.py`.

**Logic:**
- Every `POST /wardrobe/wear` increments `wash_count` for each worn item
- `needs_wash = (wash_count >= wash_threshold)`
- `POST /wardrobe/washed` resets `wash_count = 0`, sets `last_washed = today`
- Smart batching: only alert when 3+ items need washing (not per-item)
- Pre-warning: alert when fewer than 2 clean tops OR 1 clean bottom remain

**Wash urgency levels:**
- `critical` — fewer than 2 clean tops OR fewer than 1 clean bottom
- `high` — 5+ items need washing
- `medium` — 3–4 items need washing
- `low` — routine (below alert threshold)

**Notification tone:** not naggy, like a helpful friend.
- critical: "⚠ Almost out of clean clothes — Only N clean tops left."
- high: "🧺 Good time for a laundry run — N items ready."
- medium: "🧺 A few things need washing — plan a wash soon."

---

## 7. 7-Day Outfit Planner (`planner.py`)

Runs every Sunday at 20:00 per user, or on demand via `POST /planner/generate`.

**Algorithm:**
1. Fetch 7-day weather forecast from Open-Meteo for the user's city
2. For each day, select the best outfit from clean, unarchived, in-season items using the fuzzy scorer
3. Apply outfit memory penalty (same as recommendations — see §12)
4. Enforce wardrobe rotation: same item cannot appear more than 2 days/week (accessories exempt)
5. Check wash headroom — if an item would hit `wash_threshold` mid-week, attach a `wash_warning` to that day
6. If clean tops ≤ 2 or clean bottoms ≤ 1 for the week, return a `week_wash_alert`

**Response shape:**
```
{
  "days": [
    {
      "date":        "2026-03-23",
      "day_name":    "Monday",
      "occasion":    "casual",
      "outfit":      {item_ids, headline, score, score_breakdown, score_labels},
      "weather":     {"temp_c": 24, "rain_pct": 20},
      "wash_warning": null | "Wash [item] before using on Wednesday"
    }, ...
  ],
  "week_wash_alert": null | {"message": "...", "urgency": "high"},
  "rotation_score": 0.78    ← 0=same items every day, 1=perfect rotation
}
```

---

## 8. Wardrobe Intelligence

### 8.1 Wardrobe Health Score (`health_score.py`)

Single 0–100 score shown as an animated ring on the Insights screen. Pure function, no DB access.

**Components:**
| Component | Weight | Calculation |
|---|---|---|
| utilization | 40% | items worn at least once in last 30 days / total |
| rotation | 30% | 1 − (stdev of wear_counts / mean wear_count) |
| freshness | 20% | items worn in last 7 days / total |
| wash | 10% | clean items / total |

**Labels:**
- 90–100: ✦ Exceptional · 75–89: ◈ Great · 60–74: ▲ Good · 40–59: ◇ Fair · 0–39: ○ Low

### 8.2 Capsule Wardrobe Analysis (`capsule_analysis.py`)

Runs weekly (Mondays 03:00 UTC), results cached in `capsule_cache`. Only runs for users with 10+ items and 7+ days of usage.

**Four analyses:**

1. **Versatility Matrix** — for each item, count how many other items it has been recommended alongside. `versatility_score = pair_count / (total_items − 1)`. Surface top 5 most versatile.

2. **Orphan Items** — items with `versatility_score < 0.2` AND worn fewer than 2 times in 30 days. Surface with reason: "Low versatility and rarely worn."

3. **Wardrobe Gaps** — check: no waterproof top, all bottoms same formality tier, etc. Return plain-English suggestions.

4. **Color Story** — count color co-occurrences across accepted outfits. Surface top 3: "Navy + White + Brown — classic, timeless."

---

## 9. Scheduler (`scheduler.py`)

All jobs run inside the FastAPI process via APScheduler. Start with `lifespan`.

| Job | Schedule | Behavior |
|---|---|---|
| daily_outfit_check | every 1 min | Check if any user's `notify_time` matches now; send outfit notification if not sent today |
| generate_weekly_plans | Sunday 20:00 UTC | Generate 7-day plan for all `weekly_plan_enabled` users; send notification |
| check_wash_status | every 4 hours | Check wash urgency for all `wash_notify_enabled` users; notify if threshold met and not sent today |
| check_weather_anomalies | every 6 hours | If tomorrow's temp deviates >8°C from 30-day rolling average, notify `weather_anomaly_enabled` users |
| run_capsule_analysis | Monday 03:00 UTC | Compute and cache capsule analysis for eligible users |
| check_season_transitions | 1st of month, 06:00 UTC | Archive out-of-season items; unarchive newly in-season items; notify user |

**Mumbai/India seasons:**
- Summer: March–May · Monsoon: June–September · Winter: October–February

---

## 10. Push Notifications (`notifications.py`)

Firebase FCM. Initialise once on startup from `firebase_service_account.json`.

**Notification types and their data payloads:**

| type | title | body | screen |
|---|---|---|---|
| `daily_outfit` | "✦ Today's look is ready" | outfit headline | Today |
| `weekly_plan` | "Your week is planned ✦" | "7 outfits ready for the week ahead" | Week |
| `template_ready` | "📸 Showroom photo ready" | "Your {item_name} looks great" | Wardrobe |
| `wash_reminder` | (from wash_tracker urgency) | (from wash_tracker urgency) | Wash |
| `weather_anomaly` | "Weather heads-up for tomorrow" | "{N}°C {colder/warmer} than usual ({temp}°C). Outfit adjusted." | Today |
| `first_wear` | "First time wearing this ✦" | "Debut of your {item_name}. Good choice." | Today |
| `streak_milestone` | "Wardrobe streak 🔥" | "{N} days of full wardrobe rotation" | Stats |
| `season_transition` | "Season update" | "{N} items back in rotation for {season}" or "{N} items archived" | Wardrobe |

One notification per type per user per day (enforced via `notification_log`).

---

## 11. Backend API — All Endpoints

### Auth

Auth uses `X-Session-Token` header (Fernet-encrypted `google_id`). Validated on every protected route.

```
GET  /health                           → {"status": "ok"}

GET  /auth/login-url                   → {"url": "<Google OAuth URL>"}
GET  /auth/callback                    ← code from Google → issue session token → redirect
POST /auth/mobile-login                Body: {id_token} → verify → issue session token
GET  /auth/me                          → full user object
POST /auth/logout                      → invalidate session
POST /auth/api-key                     Body: {api_key} → encrypt and store
PATCH /auth/me                         Body: any user fields → update
  Accepted fields: city, notify_enabled, notify_time, notify_occasion,
                   weekly_plan_enabled, wash_notify_enabled,
                   weather_anomaly_enabled, wash_notify_urgency
```

### Device Tokens

```
POST   /notifications/register         Body: {fcm_token, platform}
DELETE /notifications/unregister       Body: {fcm_token}
```

### Wardrobe

```
GET    /wardrobe                        ?include_archived=false
POST   /wardrobe                        multipart/form-data: name, category, color, warmth,
                                        formality, waterproof, season, wash_threshold, photo
                                        → creates item (photo_status=processing), enqueues pipeline
GET    /wardrobe/status/pending         → items where photo_status=processing
GET    /wardrobe/{id}/status            → {id, photo_status, photo_url, photo_template_url}
DELETE /wardrobe/{id}                   → deletes item + R2 photos
POST   /wardrobe/wear                   Body: {item_ids: [...]}
                                        → wear_count+1, last_worn=today, first_worn if null
                                        → increment wash counts
                                        → EMA preference update
                                        → first_wear notification if applicable
                                        → streak update + streak notification at 7/14/30
                                        → add to outfit_memory
POST   /wardrobe/washed                 Body: {item_ids: [...]} → reset wash counts
GET    /wardrobe/wash-status            → full wash status object
POST   /wardrobe/{id}/reprocess         → re-enqueue photo pipeline
PATCH  /wardrobe/{id}                   Body: any item fields → update
```

### Recommendations

```
POST /recommendations
     Body: {occasion, weather_override?: {temp_c, rain_pct}}
     → filter to clean, unarchived, in-season items
     → fuzzy score all combinations (cap at 500 combos)
     → apply outfit memory penalty
     → return top 5 outfits
     Response: {outfits: [...], weather: {...}, wash_warning?: "..."}
```

### Weekly Planner

```
GET  /planner/week                      → current week plan (generates if missing)
POST /planner/generate                  Body: {occasions: {"2026-03-23": "casual", ...}}
PATCH /planner/day/{date}               Body: {occasion?} | {confirmed?} | {item_ids?}
POST /planner/day/{date}/worn           → mark as worn; triggers POST /wardrobe/wear internally
```

### Insights

```
GET /insights/health-score
    Response: {score, label, components: {utilization, rotation, freshness, wash}, trend}

GET /insights/capsule
    → returns cache; triggers compute if missing
    Response: {most_versatile, orphans, gaps, color_story, computed_at}

GET /insights/streak
    Response: {current_streak, best_streak, message}
```

### Packing

```
POST /packing
     Body: {destination, days, occasions: [...], weather: {temp_c, rain_pct}}
     → Gemini Flash (user api_key) selects packing list; rule-based fallback if no key
     Response: {items, packing_list: [{category, count, items}], tip}
```

### Stats

```
GET /stats
    Response: {total, total_wears, never_worn, with_photos, with_templates,
               templates_processing, by_category, top_worn, top_preference,
               needs_wash_count, clean_items_count, health_score}
```

---

## 12. Recommendation Algorithm

Filter before scoring:
```
available = items where:
  needs_wash = FALSE
  is_archived = FALSE
  season IN ('all', current_season)

Emergency fallback: if zero tops available, include needs_wash tops
  and set response.wash_warning = "All your tops need washing."
```

Fuzzy scorer inputs (from `modules/fuzzy_scorer.py`):
- warmth match to `weather.temp_c`
- waterproof match to `weather.rain_pct`
- formality match to occasion
- color harmony (HSL module)
- user preference EMA score
- freshness bonus (unworn items get a boost)

Outfit memory penalty:
```
For each candidate outfit:
  if ≥75% of item_ids overlap with any of the last 10 outfit_memory rows
  for the same occasion:
    score -= 0.08
    flag as repeated_recently = True
Re-sort after penalty.
```

Return top 5 outfits sorted by score.

---

## 13. PC Frontend (`pc_frontend/frontend.py`)

Streamlit app, 9 tabs: **Today | Week | Wardrobe | Wash | Generate | Pack | Insights | Stats | Settings**

All API calls use the session token stored in `st.session_state`. Design follows §5 as closely as Streamlit allows (animations and custom fonts are Android-only).

**Week tab:**
- 7-column layout Mon–Sun
- Each column: day name + weather icon + occasion dropdown + outfit thumbnail strip
- Expand column → full outfit card
- Wash warning banner at top if `week_wash_alert` present
- "Regenerate Plan" button

**Wash tab:**
- Urgency banner (color-coded by level)
- Items grouped by category, each row showing name + wash_count/wash_threshold
- Checkboxes + "Mark selected as washed" button
- Projected next wash date

**Insights tab:**
- Health score as Streamlit progress bar + score number + label + trend
- Capsule analysis cards: Most Versatile · Orphan Items · Wardrobe Gaps · Color Story
- Streak counter

---

## 14. Android Frontend

### New Screens

**`WeekScreen.tsx`**
- Horizontal FlatList of 7 `WeekDayCard` components
- Tap → full OutfitCard in bottom sheet
- Long press → occasion selector (bottom sheet)
- Confirm toggle per day → `PATCH /planner/day/{date}`
- Sticky amber wash warning banner when `week_wash_alert` is present
- FAB: "Regenerate" → `POST /planner/generate`

**`WashScreen.tsx`**
- Urgency banner: red=critical · amber=high · none=green
- SectionList grouped by category
- Each row: `ClothingPhoto` (48×60) + name + `WashBadge` + checkbox
- "Mark selected as washed" → `POST /wardrobe/washed`
- Projected next wash line

**`InsightsScreen.tsx`**
- `HealthRing` (animated, fills on mount)
- 4 capsule cards in ScrollView
- `StreakBadge` (lg) at top

### Updated `SettingsScreen.tsx`

Four notification sections, each with a toggle + options:
1. **Daily Outfit** — toggle, time picker, occasion selector
2. **Weekly Plan** — toggle, info text "Sent every Sunday evening"
3. **Wash Reminders** — toggle, urgency threshold selector (medium / high / critical)
4. **Weather Alerts** — toggle, info text "Notified when tomorrow is 8°C+ off normal"

All changes → `PATCH /auth/me`

### New Components

**`HealthRing.tsx`**
- Props: `score: number`, `size?: number` (default 160)
- SVG circle ring, stroke-dasharray drives fill
- Color: red (0–39) → amber (40–59) → gold (60–89) → green (90–100)
- Center: Cormorant 32px score + DM Sans 11px label
- Entry: ring fills 0→score over 800ms ease-out

**`WashBadge.tsx`**
- Props: `wash_count`, `wash_threshold`, `compact?: boolean`
- clean (< threshold − 1): "N / M wears" — green pill
- wash_soon (= threshold − 1): "N / M wears" — amber pill + wash icon
- needs_wash (≥ threshold): "Needs wash" — red pill + wash icon
- Compact: icon only, color-coded (for wardrobe grid)

**`WeekDayCard.tsx`**
- Props: `day: DayPlan`
- Top: day name (UPPERCASE DM Sans 12px) + date
- Weather row: icon + temp + rain%
- Occasion pill: tappable → selector
- Outfit thumbnails: 3 `ClothingPhoto` in a row (36×48px)
- Confirmed state: 1px `--gold` border
- Wash warning: amber ⚠ badge (top-right corner)

**`StreakBadge.tsx`**
- Props: `streak: number`, `size: 'sm' | 'md' | 'lg'`
- Sizes: sm=12px icon / md=18px / lg=28px icon with Cormorant 32px count
- Milestone pulse animation at 7, 14, 30 days (scale 0.95→1.05→1.0, 300ms)

---

## 15. Environment Variables

```bash
# Backend (Railway)
SW_ENCRYPT_KEY=<Fernet key>
DATABASE_URL=postgresql://...        # Railway auto-injects
REDIS_URL=redis://...                # Railway auto-injects
FIREBASE_CREDENTIALS_PATH=./firebase_service_account.json
R2_ACCOUNT_ID=<id>
R2_ACCESS_KEY_ID=<key>
R2_SECRET_ACCESS_KEY=<secret>
R2_BUCKET_NAME=smart-wardrobe-photos
R2_PUBLIC_URL=https://pub-<hash>.r2.dev

# Android
EXPO_PUBLIC_API_URL=https://your-app.railway.app
```

---

## 16. Requirements (`backend/requirements.txt`)

```
fastapi>=0.110.0
uvicorn[standard]>=0.27.0
httpx>=0.27.0
python-multipart>=0.0.9
cryptography>=42.0.0
asyncpg>=0.29.0
psycopg2-binary>=2.9.0
boto3>=1.34.0
firebase-admin>=6.5.0
APScheduler>=3.10.0
redis>=5.0.0
rembg>=2.0.57
Pillow>=10.0.0
onnxruntime>=1.17.0
scikit-fuzzy>=0.4.2
scikit-learn>=1.4.0
pandas>=2.0.0
numpy>=1.26.0
matplotlib>=3.8.0
google-auth>=2.28.0
google-auth-oauthlib>=1.2.0
```

**`Procfile`:** `web: uvicorn main:app --host 0.0.0.0 --port $PORT`

---

## 17. Key Design Decisions

| Decision | Rationale |
|---|---|
| Wash filter before scoring | Dirty clothes are not available. Emergency fallback only when wardrobe is critically depleted. |
| Smart wash batching (3+ threshold) | Per-item nagging is annoying. Batch when it's a real laundry load. |
| Bottom wash threshold = 5 | Jeans in hostel/PG life are worn 4–6 times before washing. Reflects reality. |
| `outfit_memory` table | Prevents repeating the same outfit at the same occasion. Critical for formal/date occasions. |
| Weekly plan on Sundays | Sunday is when people mentally plan their week. Highest engagement timing. |
| Season archiver | Mumbai has 3 distinct seasons. Archive out-of-season items to keep recommendations relevant. |
| Weather anomaly threshold 8°C | Below 8°C, the outfit difference is marginal. Above 8°C, it genuinely changes what you wear. |
| Health Score as animated ring | Rings are universally understood as progress. Makes utilisation legible at a glance. |
| Capsule analysis after 10 items + 7 days | Need minimum data before insights are meaningful. Running on 3 items is noise. |
| Leica × Editorial UI | Restraint is harder than decoration. Designed once, correctly. |
| Cormorant + DM Sans | Cormorant for emotion (headlines). DM Sans for clarity (data). Both timeless. |
| Single gold accent | One accent used sparingly feels like a signature. Multiple accents feels cheap. |
| Nano Banana for icons | Consistent stroke weight, same aesthetic language. No icon library = no visual debt. |
| No subscription ever | Daily habit is the product's value. Paywalls break the habit loop. |

---

## 18. What This Blueprint Does NOT Cover (v7+)

- iOS support (APNs)
- Combo-level preference learning (needs 3+ months of outfit history)
- Outfit calendar view (data is already tracked)
- Retailer integration ("buy a matching piece")
- Shared wardrobe (couples/roommates)
- Dry cleaning tracking

---

*End of blueprint v6.0 — FINAL.*
