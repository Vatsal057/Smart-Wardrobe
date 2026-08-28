@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_wardrobe_app/services/api.dart';
import 'package:smart_wardrobe_app/services/demo_seed.dart';
import 'package:smart_wardrobe_app/services/local_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Verifies the demo closet the web build ships with is actually usable:
/// the rows land in the real schema, and the app's own scoring can build
/// outfits out of them. The browser uses the same schema and the same
/// queries via the WASM build of SQLite, so exercising it here on the FFI
/// build tests the part that could realistically be wrong.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // A fresh in-memory database per test, so seeding is always first-run.
    await LocalDatabase.resetForTests();
  });

  test('seeds a closet that covers every category the planner needs', () async {
    await LocalDatabase.createOrGetUser('demo');
    await DemoSeed.ensureSeeded('demo');

    final items = await LocalDatabase.getWardrobe('demo', includeArchived: true);
    expect(items.length, greaterThanOrEqualTo(20),
        reason: 'the demo closet should feel furnished, not sparse');

    final byCategory = <String, int>{};
    for (final i in items) {
      byCategory[i['category'] as String] =
          (byCategory[i['category'] as String] ?? 0) + 1;
    }
    // getRecommendations() bails out unless there is at least one top and one
    // bottom; shoes and accessories are what make an outfit look complete.
    expect(byCategory['top'], greaterThanOrEqualTo(4));
    expect(byCategory['bottom'], greaterThanOrEqualTo(4));
    expect(byCategory['shoes'], greaterThanOrEqualTo(2));
    expect(byCategory['accessory'], greaterThanOrEqualTo(2));
  });

  test('enough of the closet survives the season and laundry filters', () async {
    // The real failure mode for this demo: a closet that looks full in the
    // grid but collapses to two garments once the recommender filters it, so
    // every suggestion looks the same. Guard the usable pool, not the total.
    await LocalDatabase.createOrGetUser('demo');
    await DemoSeed.ensureSeeded('demo');

    final usable = (await LocalDatabase.getWardrobe('demo'))
        .where((i) => i['needs_wash'] != 1 && i['season'] == 'all')
        .toList();
    int count(String c) => usable.where((i) => i['category'] == c).length;

    expect(count('top'), greaterThanOrEqualTo(6),
        reason: 'all-season clean tops available in any month');
    expect(count('bottom'), greaterThanOrEqualTo(4));

    // Spread of formality is what lets the occasion actually change the answer.
    final formalities =
        usable.where((i) => i['category'] == 'top').map((i) => i['formality'] as int);
    expect(formalities.reduce((a, b) => a < b ? a : b), lessThanOrEqualTo(3));
    expect(formalities.reduce((a, b) => a > b ? a : b), greaterThanOrEqualTo(8));
  });

  test('seeded history gives the wash tracker and insights something to say', () async {
    await LocalDatabase.createOrGetUser('demo');
    await DemoSeed.ensureSeeded('demo');

    final items = await LocalDatabase.getWardrobe('demo');
    expect(items.where((i) => i['needs_wash'] == 1), isNotEmpty,
        reason: 'the wash tracker should not open empty');
    expect(items.where((i) => (i['wear_count'] as int) > 0), isNotEmpty,
        reason: 'insights are computed from wear history');
    expect(items.where((i) => i['last_worn'] != null), isNotEmpty);
    expect(items.where((i) => i['waterproof'] == 1), isNotEmpty,
        reason: 'the rain bonus in the scorer needs something waterproof');

    final memory = await LocalDatabase.getRecentOutfits('demo', 'casual');
    expect(memory, isNotEmpty,
        reason: 'the repeat-outfit penalty needs prior outfits');
    for (final m in memory) {
      expect(m['item_ids'], isA<List<int>>());
      expect((m['item_ids'] as List).length, 3);
    }
  });

  test('is idempotent, so a visitor\'s own edits survive a reload', () async {
    await LocalDatabase.createOrGetUser('demo');
    await DemoSeed.ensureSeeded('demo');
    final first = await LocalDatabase.getWardrobe('demo', includeArchived: true);

    await LocalDatabase.addWardrobeItem('demo', {'name': 'My own jacket', 'category': 'top'});
    await DemoSeed.ensureSeeded('demo'); // second launch

    final second = await LocalDatabase.getWardrobe('demo', includeArchived: true);
    expect(second.length, first.length + 1,
        reason: 'seeding twice must not duplicate the closet');
    expect(second.where((i) => i['name'] == 'My own jacket'), hasLength(1));
  });

  test('wear history is relative to today, not baked in at build time', () async {
    await LocalDatabase.createOrGetUser('demo');
    await DemoSeed.ensureSeeded('demo');

    final items = await LocalDatabase.getWardrobe('demo');
    final worn = items
        .where((i) => i['last_worn'] != null)
        .map((i) => DateTime.parse(i['last_worn'] as String))
        .toList();
    final mostRecent = worn.reduce((a, b) => a.isAfter(b) ? a : b);
    expect(DateTime.now().difference(mostRecent).inDays, lessThanOrEqualTo(2),
        reason: 'something should look worn in the last day or two whenever '
            'the demo is opened');
  });

  _recommendationTests();
}

/// The demo only earns its place if the app's real scorer can turn the seeded
/// closet into ranked outfits. A fixed weather override keeps this offline and
/// deterministic instead of hitting open-meteo.
void _recommendationTests() {
  group('scoring the seeded closet', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await LocalDatabase.resetForTests();
      await ApiService.login('demo');
      await DemoSeed.ensureSeeded('demo');
    });

    test('produces ranked outfits for a hot Mumbai day', () async {
      final res = await ApiService.getRecommendations(
        occasion: 'casual',
        weatherOverride: {'temp_c': 33, 'rain_pct': 10, 'daily': []},
      );
      final outfits = res['outfits'] as List;
      expect(outfits, isNotEmpty, reason: 'a furnished closet must yield outfits');
      expect(outfits.length, lessThanOrEqualTo(5));

      final scores = outfits.map((o) => o['score'] as double).toList();
      expect(scores.first, greaterThan(0));
      // Returned best-first.
      for (var i = 1; i < scores.length; i++) {
        expect(scores[i - 1], greaterThanOrEqualTo(scores[i]));
      }

      final best = outfits.first as Map<String, dynamic>;
      final cats = (best['items'] as List).map((i) => i['category']).toSet();
      expect(cats, containsAll(<String>['top', 'bottom']));
      expect(best['headline'], isNotEmpty);
      expect(best['score_breakdown'],
          allOf(contains('warmth'), contains('formality'), contains('color'), contains('freshness')));
    });

    test('never recommends anything sitting in the laundry', () async {
      final dirty = (await LocalDatabase.getWardrobe('demo'))
          .where((i) => i['needs_wash'] == 1)
          .map((i) => i['id'] as int)
          .toSet();
      expect(dirty, isNotEmpty, reason: 'the seed deliberately includes worn items');

      final res = await ApiService.getRecommendations(
        occasion: 'casual',
        weatherOverride: {'temp_c': 28, 'rain_pct': 10, 'daily': []},
      );
      for (final o in (res['outfits'] as List)) {
        for (final id in (o['item_ids'] as List)) {
          expect(dirty.contains(id), isFalse,
              reason: 'item $id needs washing and should be filtered out');
        }
      }
    });

    test('a cold day scores warmer clothes higher than a hot day does', () async {
      final cold = await ApiService.getRecommendations(
        occasion: 'casual',
        weatherOverride: {'temp_c': 8, 'rain_pct': 0, 'daily': []},
      );
      final hot = await ApiService.getRecommendations(
        occasion: 'casual',
        weatherOverride: {'temp_c': 36, 'rain_pct': 0, 'daily': []},
      );

      double avgWarmth(Map<String, dynamic> res) {
        final items = (res['outfits'] as List).first['items'] as List;
        return items.fold<double>(0, (s, i) => s + (i['warmth'] as int)) / items.length;
      }

      expect(avgWarmth(cold), greaterThan(avgWarmth(hot)),
          reason: 'warmth matching should actually respond to temperature');
    });

    test('a formal occasion picks more formal clothes than a casual one', () async {
      // getRecommendations() picks the shoes and the accessory at random for
      // each candidate combo, so any single outfit is noisy. The garments the
      // occasion actually drives are the top and the bottom, averaged across
      // the whole returned set.
      double meanFormality(Map<String, dynamic> res) {
        var sum = 0.0;
        var n = 0;
        for (final o in (res['outfits'] as List)) {
          for (final i in (o['items'] as List)) {
            if (i['category'] == 'top' || i['category'] == 'bottom') {
              sum += i['formality'] as int;
              n++;
            }
          }
        }
        return sum / n;
      }

      final weather = {'temp_c': 26, 'rain_pct': 10, 'daily': []};
      final formal = await ApiService.getRecommendations(occasion: 'formal', weatherOverride: weather);
      final casual = await ApiService.getRecommendations(occasion: 'casual', weatherOverride: weather);

      expect(meanFormality(formal), greaterThan(meanFormality(casual)),
          reason: 'occasion should steer the tops and bottoms it selects');
    });

    test('the 7-day planner fills every day', () async {
      final plan = await ApiService.generatePlan();
      final days = plan['days'] as List;
      expect(days.length, 7);
      expect(days.where((d) => d['outfit'] != null).length, 7,
          reason: 'every day should get an outfit from this closet');
    });
  });
}
