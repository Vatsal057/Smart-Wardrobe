import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'local_database.dart';

/// Smart Wardrobe API Service — Fully Offline / Local
/// All data stored in local SQLite via sqflite. No backend server needed.
class ApiService {
  static String? _username;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('sw_username');
  }

  static String? get sessionToken => _username;
  static bool get isLoggedIn => _username != null;

  // ─── Auth ──────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login(String username, {String? name, String? email}) async {
    _username = username;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sw_username', username);
    final user = await LocalDatabase.createOrGetUser(username, name: name, email: email);
    return {'session_token': username, 'user': user};
  }

  static Future<void> logout() async {
    _username = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sw_username');
  }

  static Future<Map<String, dynamic>> getMe() async {
    final user = await LocalDatabase.getUser(_username!);
    return user ?? {'username': _username, 'name': _username};
  }

  static Future<Map<String, dynamic>> updateMe(Map<String, dynamic> fields) async {
    if (fields.containsKey('city')) _weatherCache = null; // re-fetch for new city
    return await LocalDatabase.updateUser(_username!, fields);
  }

  static Future<void> setApiKey(String apiKey) async {
    await LocalDatabase.updateUser(_username!, {'api_key': apiKey});
  }

  // Not needed locally but kept for interface compat
  static Future<void> setBaseUrl(String url) async {}

  // ─── Wardrobe ──────────────────────────────────────────────────

  static Future<List<dynamic>> getWardrobe({bool includeArchived = false}) async {
    return await LocalDatabase.getWardrobe(_username!, includeArchived: includeArchived);
  }

  static Future<Map<String, dynamic>> addWardrobeItem({
    required String name,
    required String category,
    required String color,
    int warmth = 5,
    int formality = 5,
    bool waterproof = false,
    String season = 'all',
    int? washThreshold,
    File? photo,
  }) async {
    String? photoPath;
    if (photo != null) {
      final dir = await getApplicationDocumentsDirectory();
      final photosDir = Directory(p.join(dir.path, 'wardrobe_photos'));
      if (!await photosDir.exists()) await photosDir.create(recursive: true);
      final ext = p.extension(photo.path).isNotEmpty ? p.extension(photo.path) : '.jpg';
      final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}$ext';
      final dest = File(p.join(photosDir.path, fileName));
      await photo.copy(dest.path);
      photoPath = dest.path;
    }

    return await LocalDatabase.addWardrobeItem(_username!, {
      'name': name,
      'category': category,
      'color': color,
      'warmth': warmth,
      'formality': formality,
      'waterproof': waterproof,
      'season': season,
      'wash_threshold': washThreshold ?? 3,
      'photo_url': photoPath,
    });
  }

  static Future<void> deleteWardrobeItem(int id) async {
    final item = await LocalDatabase.getItem(id);
    for (final key in ['photo_url', 'photo_template_url']) {
      if (item?[key] != null) {
        final f = File(item![key] as String);
        if (await f.exists()) await f.delete();
      }
    }
    await LocalDatabase.deleteItem(id);
  }

  static Future<Map<String, dynamic>> wearItems(List<int> itemIds, {String occasion = 'casual'}) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final worn = <Map<String, dynamic>>[];
    int streak = 0;

    for (final id in itemIds) {
      final item = await LocalDatabase.getItem(id);
      if (item == null) continue;

      final updates = <String, dynamic>{
        'wear_count': (item['wear_count'] as int? ?? 0) + 1,
        'last_worn': today,
        'wash_count': (item['wash_count'] as int? ?? 0) + 1,
      };
      if (item['first_worn'] == null) updates['first_worn'] = today;
      if (updates['wash_count'] >= (item['wash_threshold'] as int? ?? 3)) {
        updates['needs_wash'] = 1;
      }
      final oldPref = (item['preference'] as num?)?.toDouble() ?? 50.0;
      updates['preference'] = (oldPref * 0.9 + 70 * 0.1);

      final updated = await LocalDatabase.updateItem(id, updates);
      worn.add(updated);
    }

    await LocalDatabase.addOutfitMemory(_username!, itemIds, occasion, today);

    // Streak tracking
    final user = await LocalDatabase.getUser(_username!);
    if (user != null) {
      final lastStreak = user['streak_updated'] as String?;
      final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
      if (lastStreak == yesterday) {
        streak = (user['streak_count'] as int? ?? 0) + 1;
      } else if (lastStreak == today) {
        streak = user['streak_count'] as int? ?? 0;
      } else {
        streak = 1;
      }
      await LocalDatabase.updateUser(_username!, {'streak_count': streak, 'streak_updated': today});
    }

    return {'items': worn, 'streak': streak};
  }

  static Future<Map<String, dynamic>> washItems(List<int> itemIds) async {
    final washed = <Map<String, dynamic>>[];
    final today = DateTime.now().toIso8601String().substring(0, 10);
    for (final id in itemIds) {
      final updated = await LocalDatabase.updateItem(id, {
        'wash_count': 0,
        'needs_wash': 0,
        'last_washed': today,
      });
      washed.add(updated);
    }
    return {'items': washed};
  }

  static Future<Map<String, dynamic>> getWashStatus() async {
    final items = await LocalDatabase.getWardrobe(_username!);
    final needsWash = items.where((i) => i['needs_wash'] == 1).toList();
    final washSoon = items.where((i) {
      final wc = i['wash_count'] as int? ?? 0;
      final wt = i['wash_threshold'] as int? ?? 3;
      return i['needs_wash'] != 1 && wc >= wt - 1 && wc > 0;
    }).toList();

    final cleanTops = items.where((i) => i['category'] == 'top' && i['needs_wash'] != 1).length;
    final cleanBottoms = items.where((i) => i['category'] == 'bottom' && i['needs_wash'] != 1).length;

    String urgency = 'low';
    String message = 'All items are clean!';
    if (needsWash.length > 3) {
      urgency = 'critical';
      message = '${needsWash.length} items need washing urgently!';
    } else if (needsWash.isNotEmpty) {
      urgency = 'medium';
      message = '${needsWash.length} item(s) need washing.';
    }

    return {
      'urgency': urgency,
      'message': message,
      'needs_wash_count': needsWash.length,
      'clean_tops': cleanTops,
      'clean_bottoms': cleanBottoms,
      'items_needing_wash': needsWash,
      'wash_soon_items': washSoon,
    };
  }

  static Future<Map<String, dynamic>> updateWardrobeItem(int id, Map<String, dynamic> fields) async {
    return await LocalDatabase.updateItem(id, fields);
  }

  /// Re-shoots the item photo as a catalog-style product photo via Gemini
  /// image editing. Needs the user's Gemini API key (Settings) and network.
  static Future<Map<String, dynamic>> polishPhoto(int itemId) async {
    final item = await LocalDatabase.getItem(itemId);
    if (item == null || item['photo_url'] == null) {
      return {'status': 'error', 'description': 'This item has no photo to polish.'};
    }
    final user = await LocalDatabase.getUser(_username!);
    final apiKey = (user?['api_key'] as String?)?.trim() ?? '';
    if (apiKey.isEmpty) {
      return {'status': 'error', 'description': 'Add your Gemini API key in Settings first.'};
    }
    final photoFile = File(item['photo_url'] as String);
    if (!await photoFile.exists()) {
      return {'status': 'error', 'description': 'Photo file is missing.'};
    }

    await LocalDatabase.updateItem(itemId, {'photo_status': 'processing'});
    try {
      final bytes = await photoFile.readAsBytes();
      final mime = (item['photo_url'] as String).toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
      final res = await http
          .post(
            Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent'),
            headers: {'Content-Type': 'application/json', 'x-goog-api-key': apiKey},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'inline_data': {'mime_type': mime, 'data': base64Encode(bytes)}},
                    {
                      'text': 'Re-shoot this clothing item as a catalog product photo: isolate the '
                          'garment on a clean light-grey studio background, centered, with even soft '
                          'lighting. Keep the garment itself exactly as-is — same colors, fabric, and '
                          'shape. No people, no text, no props. Also reply with one short sentence '
                          'describing the item.'
                    },
                  ],
                }
              ],
              'generationConfig': {'responseModalities': ['TEXT', 'IMAGE']},
            }),
          )
          .timeout(const Duration(seconds: 90));

      if (res.statusCode != 200) {
        String msg = 'HTTP ${res.statusCode}';
        try {
          msg = jsonDecode(res.body)['error']['message'] as String? ?? msg;
        } catch (_) {}
        throw Exception(msg);
      }

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final parts = (body['candidates']?[0]?['content']?['parts'] as List?) ?? [];
      String? description;
      String? polishedPath;
      for (final part in parts) {
        final inline = part['inlineData'] ?? part['inline_data'];
        if (inline != null && polishedPath == null) {
          final dir = await getApplicationDocumentsDirectory();
          final photosDir = Directory(p.join(dir.path, 'wardrobe_photos'));
          if (!await photosDir.exists()) await photosDir.create(recursive: true);
          final outMime = (inline['mimeType'] ?? inline['mime_type'] ?? 'image/png').toString();
          final ext = outMime.contains('jpeg') ? '.jpg' : '.png';
          polishedPath = p.join(photosDir.path, 'polished_${itemId}_${DateTime.now().millisecondsSinceEpoch}$ext');
          await File(polishedPath).writeAsBytes(base64Decode(inline['data'] as String));
        } else if (part['text'] != null) {
          description = (part['text'] as String).trim();
        }
      }
      if (polishedPath == null) throw Exception('Gemini returned no image.');

      // Replace any previous polished photo
      final oldTemplate = item['photo_template_url'] as String?;
      if (oldTemplate != null) {
        final f = File(oldTemplate);
        if (await f.exists()) await f.delete();
      }

      await LocalDatabase.updateItem(itemId, {
        'photo_template_url': polishedPath,
        'photo_status': 'done',
        'gemini_description': ?description,
      });
      return {'status': 'done', 'description': description ?? 'Photo polished.'};
    } catch (e) {
      await LocalDatabase.updateItem(itemId, {'photo_status': 'error'});
      return {
        'status': 'error',
        'description': 'Polish failed: ${e.toString().replaceFirst('Exception: ', '')}',
      };
    }
  }

  // ─── Weather (Open-Meteo, free, no API key) ────────────────────

  static Map<String, dynamic>? _weatherCache;
  static DateTime? _weatherFetched;

  /// Current weather + 7-day forecast for the user's city.
  /// Falls back to last cached weather, then defaults, when offline.
  static Future<Map<String, dynamic>> getWeather() async {
    if (_weatherCache != null &&
        _weatherFetched != null &&
        DateTime.now().difference(_weatherFetched!).inMinutes < 60) {
      return _weatherCache!;
    }
    final prefs = await SharedPreferences.getInstance();
    try {
      final user = _username != null ? await LocalDatabase.getUser(_username!) : null;
      final city = ((user?['city'] as String?)?.trim().isNotEmpty ?? false)
          ? (user!['city'] as String).trim()
          : 'Mumbai';

      // Geocode city → lat/lon (cached per city)
      double? lat = prefs.getDouble('sw_lat_$city');
      double? lon = prefs.getDouble('sw_lon_$city');
      if (lat == null || lon == null) {
        final geoRes = await http
            .get(Uri.parse('https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(city)}&count=1'))
            .timeout(const Duration(seconds: 8));
        final results = (jsonDecode(geoRes.body)['results'] as List?) ?? [];
        if (results.isEmpty) throw Exception('City not found: $city');
        lat = (results.first['latitude'] as num).toDouble();
        lon = (results.first['longitude'] as num).toDouble();
        await prefs.setDouble('sw_lat_$city', lat);
        await prefs.setDouble('sw_lon_$city', lon);
      }

      final res = await http
          .get(Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon'
              '&current=temperature_2m'
              '&daily=temperature_2m_max,precipitation_probability_max'
              '&forecast_days=7&timezone=auto'))
          .timeout(const Duration(seconds: 8));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final daily = data['daily'] as Map<String, dynamic>;
      final dates = daily['time'] as List;
      final temps = daily['temperature_2m_max'] as List;
      final rains = daily['precipitation_probability_max'] as List;

      final weather = {
        'temp_c': (data['current']['temperature_2m'] as num).round(),
        'rain_pct': ((rains.isNotEmpty ? rains.first : 0) as num? ?? 0).round(),
        'city': city,
        'daily': [
          for (int i = 0; i < dates.length; i++)
            {
              'date': dates[i],
              'temp_c': (temps[i] as num?)?.round() ?? 25,
              'rain_pct': (rains[i] as num?)?.round() ?? 0,
            }
        ],
      };
      _weatherCache = weather;
      _weatherFetched = DateTime.now();
      await prefs.setString('sw_weather_cache', jsonEncode(weather));
      return weather;
    } catch (_) {
      final cached = prefs.getString('sw_weather_cache');
      if (cached != null) return jsonDecode(cached) as Map<String, dynamic>;
      return {'temp_c': 25, 'rain_pct': 10, 'daily': []};
    }
  }

  // ─── Recommendations (local scoring) ──────────────────────────

  static Future<Map<String, dynamic>> getRecommendations({
    String occasion = 'casual',
    Map<String, dynamic>? weatherOverride,
  }) async {
    final items = await LocalDatabase.getWardrobe(_username!);
    final available = items.where((i) => i['needs_wash'] != 1 && i['is_archived'] != 1).toList();
    final weather = weatherOverride ?? await getWeather();
    final tempC = weather['temp_c'] as num? ?? 25;
    final rainPct = weather['rain_pct'] as num? ?? 10;

    final tops = _seasonFilter(available.where((i) => i['category'] == 'top').toList());
    final bottoms = _seasonFilter(available.where((i) => i['category'] == 'bottom').toList());
    final shoes = _seasonFilter(available.where((i) => i['category'] == 'shoes').toList());
    final accessories = _seasonFilter(available.where((i) => i['category'] == 'accessory').toList());

    if (tops.isEmpty || bottoms.isEmpty) {
      return {
        'outfits': [],
        'weather': weather,
        'wash_warning': 'Add more tops and bottoms to get outfit recommendations.',
      };
    }

    // Generate outfit combos
    final rng = Random();
    final scored = <Map<String, dynamic>>[];
    final memory = await LocalDatabase.getRecentOutfits(_username!, occasion);

    // Build combos (limit to avoid too much computation)
    final topsPool = tops.length > 10 ? (tops..shuffle()).sublist(0, 10) : tops;
    final bottomsPool = bottoms.length > 10 ? (bottoms..shuffle()).sublist(0, 10) : bottoms;

    for (final top in topsPool) {
      for (final bottom in bottomsPool) {
        final outfitItems = <Map<String, dynamic>>[top, bottom];
        if (shoes.isNotEmpty) outfitItems.add(shoes[rng.nextInt(shoes.length)]);
        if (accessories.isNotEmpty) outfitItems.add(accessories[rng.nextInt(accessories.length)]);

        final result = _scoreOutfit(outfitItems, occasion, tempC: tempC, rainPct: rainPct);
        double score = result['score'] as double;

        // Memory penalty
        final itemIds = outfitItems.map((i) => i['id'] as int).toSet();
        for (final past in memory) {
          final pastIds = (past['item_ids'] as List).map((e) => e as int).toSet();
          if (pastIds.isNotEmpty && itemIds.intersection(pastIds).length / itemIds.length >= 0.75) {
            score -= 8;
            break;
          }
        }

        scored.add({
          'item_ids': outfitItems.map((i) => i['id']).toList(),
          'items': outfitItems,
          'headline': _generateHeadline(outfitItems, occasion, score),
          'score': (score.clamp(0, 100) * 10).round() / 10.0,
          'score_breakdown': result['breakdown'],
          'score_labels': _scoreLabels(outfitItems, occasion),
        });
      }
    }

    scored.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    return {
      'outfits': scored.take(5).toList(),
      'weather': weather,
    };
  }

  /// Season for outfit filtering (Indian calendar, matches add-item options).
  static String _currentSeason() {
    final m = DateTime.now().month;
    if (m >= 3 && m <= 6) return 'summer';
    if (m >= 7 && m <= 9) return 'monsoon';
    if (m >= 11 || m <= 2) return 'winter';
    return 'all'; // October shoulder month
  }

  /// Drop out-of-season items; never empty the pool entirely.
  static List<Map<String, dynamic>> _seasonFilter(List<Map<String, dynamic>> items) {
    final season = _currentSeason();
    if (season == 'all') return items;
    final filtered = items.where((i) => i['season'] == 'all' || i['season'] == season).toList();
    return filtered.isEmpty ? items : filtered;
  }

  /// Returns {'score': double, 'breakdown': {warmth, formality, color, freshness}}
  /// with each breakdown component normalized 0–1.
  static Map<String, dynamic> _scoreOutfit(
    List<Map<String, dynamic>> items,
    String occasion, {
    num tempC = 25,
    num rainPct = 10,
  }) {
    double score = 40;

    // Formality match (0–1)
    final formalityMap = {
      'casual': 3, 'smart_casual': 5, 'semi_formal': 7, 'formal': 9,
      'date': 6, 'outdoor': 3, 'party': 6,
    };
    final targetFormality = formalityMap[occasion] ?? 5;
    double formality = 0;
    for (final item in items) {
      final f = item['formality'] as int? ?? 5;
      formality += 1.0 - (f - targetFormality).abs() / 9.0;
    }
    formality /= items.length;
    score += formality * 25;

    // Warmth vs temperature (0–1): hot day wants light clothes, cold wants warm
    final idealWarmth = tempC >= 32 ? 2.0 : tempC >= 26 ? 3.0 : tempC >= 20 ? 5.0 : tempC >= 12 ? 7.0 : 9.0;
    final avgWarmth = items.fold<double>(0, (s, i) => s + (i['warmth'] as int? ?? 5)) / items.length;
    final warmth = (1.0 - (avgWarmth - idealWarmth).abs() / 9.0).clamp(0.0, 1.0);
    score += warmth * 15;

    // Rain: waterproof bonus on wet days
    if (rainPct >= 50 && items.any((i) => i['waterproof'] == 1)) score += 5;

    // Color harmony (0–1)
    double color = 0.5;
    if (items.length >= 2) {
      final colors = items.map((i) => i['color'] as String? ?? 'black').toSet();
      if (colors.length > 1) color += 0.2; // variety
      if (_isClassicCombo(colors.toList())) color += 0.3; // classic combo
    }
    color = color.clamp(0.0, 1.0);
    score += color * 12;

    // Freshness (0–1): wears remaining before wash needed
    double freshness = 0;
    for (final item in items) {
      final wc = item['wash_count'] as int? ?? 0;
      final wt = item['wash_threshold'] as int? ?? 3;
      freshness += wt > 0 ? (1.0 - wc / wt).clamp(0.0, 1.0) : 1.0;
    }
    freshness /= items.length;
    score += freshness * 8;

    // Preference factor (learned from wear history)
    for (final item in items) {
      final pref = (item['preference'] as num?)?.toDouble() ?? 50.0;
      score += (pref - 50) / 10;
    }

    double round2(double v) => (v * 100).round() / 100;
    return {
      'score': score,
      'breakdown': {
        'warmth': round2(warmth),
        'formality': round2(formality),
        'color': round2(color),
        'freshness': round2(freshness),
      },
    };
  }

  static bool _isClassicCombo(List<String> colors) {
    final combos = [
      {'black', 'white'}, {'navy', 'white'}, {'navy', 'khaki'},
      {'blue', 'brown'}, {'grey', 'navy'}, {'black', 'grey'},
      {'white', 'blue'}, {'cream', 'navy'}, {'black', 'red'},
      {'olive', 'brown'}, {'denim', 'white'}, {'burgundy', 'cream'},
    ];
    final set = colors.toSet();
    return combos.any((c) => c.intersection(set).length >= 2);
  }

  static String _generateHeadline(List<Map<String, dynamic>> items, String occasion, double score) {
    final adj = score > 80 ? 'Perfect' : score > 65 ? 'Great' : score > 50 ? 'Good' : 'Decent';
    final occasionLabel = occasion.replaceAll('_', ' ');
    final topName = items.firstWhere((i) => i['category'] == 'top', orElse: () => items.first)['name'] ?? 'outfit';
    return '$adj $occasionLabel look with $topName';
  }

  static List<String> _scoreLabels(List<Map<String, dynamic>> items, String occasion) {
    final labels = <String>[];
    final avgFormality = items.map((i) => i['formality'] as int? ?? 5).reduce((a, b) => a + b) / items.length;
    if (avgFormality >= 7) {
      labels.add('Formal');
    } else if (avgFormality >= 4) {
      labels.add('Smart');
    } else {
      labels.add('Casual');
    }

    final colors = items.map((i) => i['color'] as String? ?? '').toSet();
    if (colors.length >= 3) labels.add('Colorful');
    if (colors.contains('black') && colors.length <= 2) labels.add('Monochrome');

    final hasWarm = items.any((i) => (i['warmth'] as int? ?? 5) >= 7);
    if (hasWarm) labels.add('Warm');

    return labels;
  }

  // ─── Planner ───────────────────────────────────────────────────

  static String get _planKey => 'sw_week_plan_$_username';

  static String _weekStart() {
    final today = DateTime.now();
    return today.subtract(Duration(days: today.weekday - 1)).toIso8601String().substring(0, 10);
  }

  static Future<Map<String, dynamic>?> _loadStoredPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_planKey);
    if (raw == null) return null;
    final plan = jsonDecode(raw) as Map<String, dynamic>;
    if (plan['week_start'] != _weekStart()) return null; // stale — new week
    return plan;
  }

  static Future<void> _savePlan(Map<String, dynamic> plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_planKey, jsonEncode(plan));
  }

  /// Returns the stored plan for this week; generates one if missing/stale.
  static Future<Map<String, dynamic>> getWeekPlan() async {
    final stored = await _loadStoredPlan();
    if (stored != null) return stored;
    return await generatePlan();
  }

  static Future<Map<String, dynamic>> generatePlan({Map<String, String>? occasions}) async {
    final plan = await _generateLocalWeekPlan(occasions: occasions);
    plan['week_start'] = _weekStart();
    await _savePlan(plan);
    return plan;
  }

  static Future<Map<String, dynamic>> _generateLocalWeekPlan({Map<String, String>? occasions}) async {
    final items = await LocalDatabase.getWardrobe(_username!);
    final available = items.where((i) => i['needs_wash'] != 1 && i['is_archived'] != 1).toList();

    final tops = _seasonFilter(available.where((i) => i['category'] == 'top').toList());
    final bottoms = _seasonFilter(available.where((i) => i['category'] == 'bottom').toList());
    final shoes = _seasonFilter(available.where((i) => i['category'] == 'shoes').toList());

    final weather = await getWeather();
    final forecastByDate = {
      for (final d in (weather['daily'] as List? ?? [])) d['date'] as String: d as Map<String, dynamic>,
    };

    final days = <Map<String, dynamic>>[];
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final dayOccasions = ['casual', 'smart_casual', 'casual', 'smart_casual', 'casual', 'date', 'casual'];
    final rng = Random();

    final usedTops = <int>{};
    final usedBottoms = <int>{};

    for (int i = 0; i < 7; i++) {
      final dayDate = monday.add(Duration(days: i));
      final dateStr = dayDate.toIso8601String().substring(0, 10);
      final dayName = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][i];
      final occasion = occasions?[dateStr] ?? dayOccasions[i];
      final dayWeather = forecastByDate[dateStr] ??
          {'temp_c': weather['temp_c'] ?? 25, 'rain_pct': weather['rain_pct'] ?? 10};

      Map<String, dynamic>? outfit;
      if (tops.isNotEmpty && bottoms.isNotEmpty) {
        // Try to pick unused items first for rotation
        var topPool = tops.where((t) => !usedTops.contains(t['id'])).toList();
        if (topPool.isEmpty) { topPool = tops; usedTops.clear(); }
        var bottomPool = bottoms.where((b) => !usedBottoms.contains(b['id'])).toList();
        if (bottomPool.isEmpty) { bottomPool = bottoms; usedBottoms.clear(); }

        final top = topPool[rng.nextInt(topPool.length)];
        final bottom = bottomPool[rng.nextInt(bottomPool.length)];
        usedTops.add(top['id'] as int);
        usedBottoms.add(bottom['id'] as int);

        final outfitItems = <Map<String, dynamic>>[top, bottom];
        if (shoes.isNotEmpty) outfitItems.add(shoes[rng.nextInt(shoes.length)]);

        final result = _scoreOutfit(outfitItems, occasion,
            tempC: dayWeather['temp_c'] as num? ?? 25, rainPct: dayWeather['rain_pct'] as num? ?? 10);
        final score = result['score'] as double;
        outfit = {
          'item_ids': outfitItems.map((i) => i['id']).toList(),
          'items': outfitItems,
          'headline': _generateHeadline(outfitItems, occasion, score),
          'score': (score.clamp(0, 100) * 10).round() / 10.0,
          'score_breakdown': result['breakdown'],
        };
      }

      days.add({
        'date': dateStr,
        'day_name': dayName,
        'occasion': occasion,
        'outfit': outfit,
        'weather': {'temp_c': dayWeather['temp_c'], 'rain_pct': dayWeather['rain_pct']},
        'confirmed': false,
        'worn': false,
      });
    }

    return {'days': days};
  }

  static Future<void> updatePlanDay(String date, Map<String, dynamic> fields) async {
    final plan = await _loadStoredPlan();
    if (plan == null) return;
    for (final day in (plan['days'] as List)) {
      if (day['date'] == date) {
        (day as Map).addAll(fields);
        break;
      }
    }
    await _savePlan(plan);
  }

  /// Wears the planned outfit for [date] (updates wear/wash counts, streak,
  /// outfit memory) and marks the day worn in the stored plan.
  static Future<void> markDayWorn(String date) async {
    final plan = await _loadStoredPlan();
    if (plan == null) return;
    for (final day in (plan['days'] as List)) {
      if (day['date'] == date && day['outfit'] != null && day['worn'] != true) {
        final ids = (day['outfit']['item_ids'] as List).map((e) => e as int).toList();
        await wearItems(ids, occasion: day['occasion'] as String? ?? 'casual');
        day['worn'] = true;
        day['confirmed'] = true;
        await _savePlan(plan);
        return;
      }
    }
  }

  // ─── Insights ──────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getHealthScore() async {
    final items = await LocalDatabase.getWardrobe(_username!);
    if (items.isEmpty) return {'score': 0, 'components': {'utilization': 0, 'rotation': 0, 'freshness': 0, 'wash': 0}};

    // Utilization (40%): what % of items have been worn
    final wornCount = items.where((i) => (i['wear_count'] as int? ?? 0) > 0).length;
    final utilization = items.isNotEmpty ? wornCount / items.length : 0.0;

    // Rotation (30%): how evenly items are worn
    final wears = items.map((i) => (i['wear_count'] as int? ?? 0).toDouble()).toList();
    final totalWears = wears.fold(0.0, (a, b) => a + b);
    double rotation = 0.8;
    if (totalWears > 0 && items.length > 1) {
      final avg = totalWears / items.length;
      final variance = wears.map((w) => (w - avg) * (w - avg)).fold(0.0, (a, b) => a + b) / items.length;
      final double cv = avg > 0 ? sqrt(variance) / avg : 0.0;
      rotation = (1.0 - cv.clamp(0.0, 1.0)).clamp(0.0, 1.0);
    }

    // Freshness (20%): what % of items don't need washing
    final cleanCount = items.where((i) => i['needs_wash'] != 1).length;
    final freshness = items.isNotEmpty ? cleanCount / items.length : 1.0;

    // Wash compliance (10%)
    final onTimeWash = items.where((i) {
      final wc = i['wash_count'] as int? ?? 0;
      final wt = i['wash_threshold'] as int? ?? 3;
      return wc <= wt;
    }).length;
    final washScore = items.isNotEmpty ? onTimeWash / items.length : 1.0;

    final score = (utilization * 40 + rotation * 30 + freshness * 20 + washScore * 10).round();

    return {
      'score': score,
      'components': {
        'utilization': utilization,
        'rotation': rotation,
        'freshness': freshness,
        'wash': washScore,
      },
    };
  }

  static Future<Map<String, dynamic>> getCapsule() async {
    final items = await LocalDatabase.getWardrobe(_username!);
    if (items.isEmpty) {
      return {
        'most_versatile': [],
        'orphans': [],
        'gaps': ['Add some items to see analysis'],
        'color_story': [],
      };
    }

    // Most versatile: items worn the most
    final sorted = List<Map<String, dynamic>>.from(items)
      ..sort((a, b) => ((b['wear_count'] as int? ?? 0)).compareTo(a['wear_count'] as int? ?? 0));
    final versatile = sorted.take(3).map((i) => {'name': i['name'], 'wear_count': i['wear_count'] ?? 0}).toList();

    // Orphans: items never worn
    final orphans = items.where((i) => (i['wear_count'] as int? ?? 0) == 0).map((i) =>
        {'name': i['name'], 'reason': 'Never worn'}
    ).toList();

    // Gaps
    final categories = items.map((i) => i['category'] as String).toSet();
    final gaps = <String>[];
    if (!categories.contains('shoes')) gaps.add('No shoes — consider adding footwear');
    if (!categories.contains('accessory')) gaps.add('No accessories — belts, watches, etc.');
    if (items.where((i) => i['category'] == 'top').length < 3) gaps.add('Add more tops for variety');
    if (items.where((i) => i['category'] == 'bottom').length < 2) gaps.add('Add more bottoms');

    // Color story
    final colorCounts = <String, int>{};
    for (final item in items) {
      final c = item['color'] as String? ?? 'unknown';
      colorCounts[c] = (colorCounts[c] ?? 0) + 1;
    }
    final sortedColors = colorCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final colorStory = sortedColors.map((e) => {
      'colors': e.key,
      'description': '${e.value} item${e.value > 1 ? 's' : ''}',
    }).toList();

    return {
      'most_versatile': versatile,
      'orphans': orphans.take(5).toList(),
      'gaps': gaps.isEmpty ? ['Your wardrobe looks well-balanced!'] : gaps,
      'color_story': colorStory.take(5).toList(),
    };
  }

  static Future<Map<String, dynamic>> getStreak() async {
    final user = await LocalDatabase.getUser(_username!);
    final streak = user?['streak_count'] as int? ?? 0;
    final messages = {
      0: 'Start wearing outfits to build your streak!',
      1: 'Day 1 — you\'re on your way!',
      7: '🔥 One week streak — impressive!',
      14: '🔥🔥 Two weeks strong!',
      30: '🔥🔥🔥 A full month — legendary!',
    };
    final msgKey = messages.keys.where((k) => k <= streak).reduce((a, b) => a > b ? a : b);
    var message = messages[msgKey]!;
    if (streak > 30) message = '🔥🔥🔥 $streak days — absolutely legendary!';

    return {'current_streak': streak, 'best_streak': streak, 'message': message};
  }

  // ─── Packing ───────────────────────────────────────────────────

  static Future<Map<String, dynamic>> generatePackingList({
    required String destination,
    required int days,
    List<String> occasions = const ['casual'],
    Map<String, dynamic> weather = const {'temp_c': 25, 'rain_pct': 20},
  }) async {
    final items = await LocalDatabase.getWardrobe(_username!);
    final available = items.where((i) => i['is_archived'] != 1 && i['needs_wash'] != 1).toList();

    final topsNeeded = days;
    final bottomsNeeded = max(2, days ~/ 2);
    final shoesNeeded = min(2, available.where((i) => i['category'] == 'shoes').length);
    final accNeeded = min(3, available.where((i) => i['category'] == 'accessory').length);

    final categories = <String, List<Map<String, dynamic>>>{'top': [], 'bottom': [], 'shoes': [], 'accessory': []};
    for (final item in available) {
      final cat = item['category'] as String? ?? 'top';
      if (categories.containsKey(cat)) categories[cat]!.add(item);
    }

    final limits = {'top': topsNeeded, 'bottom': bottomsNeeded, 'shoes': shoesNeeded, 'accessory': accNeeded};
    final packingList = <Map<String, dynamic>>[];
    final totalItems = <Map<String, dynamic>>[];

    for (final entry in categories.entries) {
      final catItems = entry.value.take(limits[entry.key] ?? 3).toList();
      packingList.add({
        'category': entry.key,
        'count': catItems.length,
        'items': catItems.map((i) => {'id': i['id'], 'name': i['name']}).toList(),
      });
      totalItems.addAll(catItems);
    }

    var tip = 'Pack light for $destination! $days days, ${totalItems.length} pieces.';
    if ((weather['rain_pct'] as num? ?? 0) > 50) tip += " Don't forget rain gear!";

    return {'items': totalItems, 'packing_list': packingList, 'tip': tip};
  }

  // ─── Stats ─────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getStats() async {
    final items = await LocalDatabase.getWardrobe(_username!, includeArchived: true);
    final active = items.where((i) => i['is_archived'] != 1).toList();

    final byCategory = <String, int>{};
    final topWorn = <Map<String, dynamic>>[];
    final topPreference = <Map<String, dynamic>>[];

    for (final item in active) {
      final cat = item['category'] as String? ?? 'other';
      byCategory[cat] = (byCategory[cat] ?? 0) + 1;
      topWorn.add({'id': item['id'], 'name': item['name'], 'wear_count': item['wear_count'] ?? 0});
      topPreference.add({'id': item['id'], 'name': item['name'], 'preference': item['preference'] ?? 50});
    }

    topWorn.sort((a, b) => (b['wear_count'] as int).compareTo(a['wear_count'] as int));
    topPreference.sort((a, b) => (b['preference'] as num).compareTo(a['preference'] as num));

    final healthScore = await getHealthScore();

    return {
      'total': active.length,
      'total_wears': active.fold<int>(0, (sum, i) => sum + (i['wear_count'] as int? ?? 0)),
      'never_worn': active.where((i) => (i['wear_count'] as int? ?? 0) == 0).length,
      'with_photos': active.where((i) => i['photo_url'] != null).length,
      'with_templates': active.where((i) => i['photo_template_url'] != null).length,
      'templates_processing': 0,
      'by_category': byCategory,
      'top_worn': topWorn.take(5).toList(),
      'top_preference': topPreference.take(5).toList(),
      'needs_wash_count': active.where((i) => i['needs_wash'] == 1).length,
      'clean_items_count': active.where((i) => i['needs_wash'] != 1).length,
      'health_score': healthScore,
    };
  }

  // ─── Health Check ──────────────────────────────────────────────

  static Future<bool> healthCheck() async {
    return true; // Always healthy locally
  }
}
