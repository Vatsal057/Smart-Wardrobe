import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:smart_wardrobe_app/services/api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('core wardrobe flow: add, recommend, wear, wash, week plan', () async {
    // Isolated db per run
    final tmp = await Directory.systemTemp.createTemp('sw_test');
    await databaseFactory.setDatabasesPath(tmp.path);
    SharedPreferences.setMockInitialValues({});

    await ApiService.login('testuser');

    final top = await ApiService.addWardrobeItem(name: 'Tee', category: 'top', color: 'white');
    final bottom = await ApiService.addWardrobeItem(
        name: 'Jeans', category: 'bottom', color: 'denim', waterproof: true);
    expect(bottom['waterproof'], 1);

    // bools must survive sqflite writes (settings toggles)
    final user = await ApiService.updateMe({'notify_enabled': false});
    expect(user['notify_enabled'], 0);

    // recommendations with weather override (no network needed)
    final rec = await ApiService.getRecommendations(
        weatherOverride: {'temp_c': 30, 'rain_pct': 60});
    final outfits = rec['outfits'] as List;
    expect(outfits, isNotEmpty);
    final breakdown = outfits.first['score_breakdown'] as Map;
    for (final key in ['warmth', 'formality', 'color', 'freshness']) {
      expect(breakdown[key], inInclusiveRange(0, 1), reason: key);
    }

    // wear increments counters, wash resets them
    final ids = [top['id'] as int, bottom['id'] as int];
    await ApiService.wearItems(ids);
    var items = await ApiService.getWardrobe();
    expect(items.every((i) => i['wear_count'] == 1), true);
    await ApiService.washItems(ids);
    items = await ApiService.getWardrobe();
    expect(items.every((i) => i['wash_count'] == 0), true);

    // polish guards: no photo, then no API key
    var polish = await ApiService.polishPhoto(top['id'] as int);
    expect(polish['status'], 'error');
    expect(polish['description'], contains('no photo'));
    await ApiService.updateWardrobeItem(top['id'] as int, {'photo_url': '/nonexistent/fake.jpg'});
    polish = await ApiService.polishPhoto(top['id'] as int);
    expect(polish['status'], 'error');
    expect(polish['description'], contains('API key'));

    // week plan is persistent across loads and markDayWorn sticks
    final plan = await ApiService.getWeekPlan();
    final plan2 = await ApiService.getWeekPlan();
    expect(plan2['days'][0]['outfit']?['item_ids'],
        plan['days'][0]['outfit']?['item_ids']);
    final firstDay = plan['days'][0] as Map<String, dynamic>;
    if (firstDay['outfit'] != null) {
      await ApiService.markDayWorn(firstDay['date'] as String);
      final plan3 = await ApiService.getWeekPlan();
      expect(plan3['days'][0]['worn'], true);
    }
  });
}
