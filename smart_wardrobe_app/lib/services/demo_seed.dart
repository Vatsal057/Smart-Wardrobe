import 'local_database.dart';

/// Seeds a believable wardrobe the first time the web demo is opened.
///
/// The app's whole value — outfit scoring, the week planner, wash warnings,
/// insights — only means anything against a closet with clothes in it. On a
/// phone you build that up over weeks; a visitor with 30 seconds cannot. So the
/// browser build starts from a furnished closet instead of an empty one.
///
/// Nothing here is special-cased downstream: these go through the same tables
/// and the same scoring as items added by hand, and everything stays editable.
class DemoSeed {
  const DemoSeed._();

  /// Wear history is written relative to today so the planner and the
  /// "recently worn" penalty always have something recent to work with,
  /// however long after deployment somebody opens the demo.
  static String _daysAgo(int days) => DateTime.now()
      .subtract(Duration(days: days))
      .toIso8601String()
      .substring(0, 10);

  // name, category, color, warmth, formality, waterproof, season,
  // wearCount, lastWornDaysAgo (null = never worn), washCount, washThreshold,
  // needsWash, preference
  /// Deliberately weighted towards `season: 'all'`. The recommender applies a
  /// season filter and then drops anything in the laundry, so a closet full of
  /// seasonal items collapses to two or three usable garments and the demo
  /// looks thin whenever it happens to be opened. A handful of seasonal pieces
  /// stay in so the filter is still visible in the closet view.
  static const _items = <Map<String, dynamic>>[
    // ── tops ──
    {'name': 'White oxford shirt', 'category': 'top', 'color': 'white', 'warmth': 4, 'formality': 8, 'season': 'all', 'wear_count': 11, 'last_worn': 3, 'wash_count': 1, 'wash_threshold': 2, 'preference': 82.0},
    {'name': 'Light blue formal shirt', 'category': 'top', 'color': 'blue', 'warmth': 4, 'formality': 9, 'season': 'all', 'wear_count': 4, 'last_worn': 14, 'wash_count': 0, 'wash_threshold': 2, 'preference': 69.0},
    {'name': 'Black crew tee', 'category': 'top', 'color': 'black', 'warmth': 3, 'formality': 2, 'season': 'all', 'wear_count': 24, 'last_worn': 1, 'wash_count': 9, 'wash_threshold': 2, 'needs_wash': 1, 'preference': 91.0},
    {'name': 'Grey marl tee', 'category': 'top', 'color': 'grey', 'warmth': 3, 'formality': 2, 'season': 'all', 'wear_count': 17, 'last_worn': 2, 'wash_count': 1, 'wash_threshold': 2, 'preference': 66.0},
    {'name': 'Navy polo', 'category': 'top', 'color': 'navy', 'warmth': 4, 'formality': 5, 'season': 'all', 'wear_count': 6, 'last_worn': 9, 'wash_count': 2, 'wash_threshold': 3, 'preference': 58.0},
    {'name': 'Olive linen shirt', 'category': 'top', 'color': 'olive', 'warmth': 2, 'formality': 5, 'season': 'all', 'wear_count': 8, 'last_worn': 6, 'wash_count': 1, 'wash_threshold': 2, 'preference': 74.0},
    {'name': 'Striped kurta', 'category': 'top', 'color': 'cream', 'warmth': 3, 'formality': 7, 'season': 'all', 'wear_count': 3, 'last_worn': 21, 'wash_count': 1, 'wash_threshold': 2, 'preference': 70.0},
    {'name': 'Charcoal hoodie', 'category': 'top', 'color': 'charcoal', 'warmth': 7, 'formality': 3, 'season': 'all', 'wear_count': 9, 'last_worn': 11, 'wash_count': 2, 'wash_threshold': 4, 'preference': 77.0},
    {'name': 'Checked flannel', 'category': 'top', 'color': 'maroon', 'warmth': 8, 'formality': 3, 'season': 'winter', 'wear_count': 2, 'last_worn': 48, 'wash_count': 1, 'wash_threshold': 4, 'preference': 47.0},

    // ── bottoms ──
    {'name': 'Indigo slim jeans', 'category': 'bottom', 'color': 'indigo', 'warmth': 5, 'formality': 4, 'season': 'all', 'wear_count': 29, 'last_worn': 1, 'wash_count': 5, 'wash_threshold': 6, 'preference': 88.0},
    {'name': 'Charcoal chinos', 'category': 'bottom', 'color': 'charcoal', 'warmth': 5, 'formality': 7, 'season': 'all', 'wear_count': 14, 'last_worn': 4, 'wash_count': 2, 'wash_threshold': 4, 'preference': 79.0},
    {'name': 'Grey wool trousers', 'category': 'bottom', 'color': 'grey', 'warmth': 6, 'formality': 8, 'season': 'all', 'wear_count': 3, 'last_worn': 25, 'wash_count': 1, 'wash_threshold': 4, 'preference': 57.0},
    {'name': 'Black formal trousers', 'category': 'bottom', 'color': 'black', 'warmth': 5, 'formality': 9, 'season': 'all', 'wear_count': 5, 'last_worn': 17, 'wash_count': 2, 'wash_threshold': 4, 'preference': 61.0},
    {'name': 'Track pants', 'category': 'bottom', 'color': 'navy', 'warmth': 6, 'formality': 1, 'season': 'all', 'wear_count': 12, 'last_worn': 5, 'wash_count': 1, 'wash_threshold': 3, 'preference': 55.0},
    {'name': 'Beige cotton shorts', 'category': 'bottom', 'color': 'beige', 'warmth': 1, 'formality': 2, 'season': 'summer', 'wear_count': 19, 'last_worn': 2, 'wash_count': 8, 'wash_threshold': 2, 'needs_wash': 1, 'preference': 72.0},

    // ── shoes ──
    {'name': 'White sneakers', 'category': 'shoes', 'color': 'white', 'warmth': 3, 'formality': 4, 'season': 'all', 'wear_count': 33, 'last_worn': 1, 'wash_count': 2, 'wash_threshold': 12, 'preference': 93.0},
    {'name': 'Brown leather derbies', 'category': 'shoes', 'color': 'brown', 'warmth': 4, 'formality': 9, 'season': 'all', 'wear_count': 7, 'last_worn': 12, 'wash_count': 0, 'wash_threshold': 20, 'preference': 76.0},
    {'name': 'Running shoes', 'category': 'shoes', 'color': 'grey', 'warmth': 3, 'formality': 1, 'season': 'all', 'wear_count': 21, 'last_worn': 2, 'wash_count': 3, 'wash_threshold': 10, 'preference': 68.0},
    {'name': 'Monsoon sandals', 'category': 'shoes', 'color': 'black', 'warmth': 1, 'formality': 2, 'waterproof': 1, 'season': 'monsoon', 'wear_count': 9, 'last_worn': 30, 'wash_count': 1, 'wash_threshold': 8, 'preference': 52.0},

    // ── accessories ──
    {'name': 'Packable rain shell', 'category': 'accessory', 'color': 'navy', 'warmth': 4, 'formality': 3, 'waterproof': 1, 'season': 'monsoon', 'wear_count': 6, 'last_worn': 27, 'wash_count': 1, 'wash_threshold': 6, 'preference': 71.0},
    {'name': 'Canvas tote', 'category': 'accessory', 'color': 'beige', 'warmth': 0, 'formality': 3, 'season': 'all', 'wear_count': 15, 'last_worn': 3, 'wash_count': 2, 'wash_threshold': 8, 'preference': 64.0},
    {'name': 'Steel watch', 'category': 'accessory', 'color': 'silver', 'warmth': 0, 'formality': 7, 'season': 'all', 'wear_count': 26, 'last_worn': 1, 'wash_count': 0, 'wash_threshold': 30, 'preference': 85.0},
    {'name': 'Wool scarf', 'category': 'accessory', 'color': 'grey', 'warmth': 8, 'formality': 4, 'season': 'winter', 'wear_count': 1, 'last_worn': null, 'wash_count': 0, 'wash_threshold': 5, 'preference': 40.0},
  ];

  /// Inserts the demo closet if [userId] has nothing yet. Safe to call on every
  /// launch: an existing wardrobe is left completely alone, so anything the
  /// visitor adds or edits survives a reload.
  static Future<void> ensureSeeded(String userId) async {
    final existing = await LocalDatabase.getWardrobe(userId, includeArchived: true);
    if (existing.isNotEmpty) return;

    final ids = <String, List<int>>{};
    for (final spec in _items) {
      final created = await LocalDatabase.addWardrobeItem(userId, {
        'name': spec['name'],
        'category': spec['category'],
        'color': spec['color'],
        'warmth': spec['warmth'],
        'formality': spec['formality'],
        'waterproof': spec['waterproof'] ?? 0,
        'season': spec['season'],
        'wash_threshold': spec['wash_threshold'],
      });

      // addWardrobeItem only takes the descriptive fields, so the history that
      // makes the demo interesting is applied as an update.
      final lastWorn = spec['last_worn'] as int?;
      await LocalDatabase.updateItem(created['id'] as int, {
        'wear_count': spec['wear_count'],
        'last_worn': lastWorn == null ? null : _daysAgo(lastWorn),
        'first_worn': _daysAgo(90),
        'wash_count': spec['wash_count'],
        'needs_wash': spec['needs_wash'] ?? 0,
        'preference': spec['preference'],
      });

      (ids[spec['category'] as String] ??= []).add(created['id'] as int);
    }

    // A short outfit history, so "don't repeat what you just wore" has
    // something to avoid and the insights screen isn't empty.
    final tops = ids['top'] ?? const [];
    final bottoms = ids['bottom'] ?? const [];
    final shoes = ids['shoes'] ?? const [];
    if (tops.isEmpty || bottoms.isEmpty || shoes.isEmpty) return;
    for (var i = 0; i < 6; i++) {
      await LocalDatabase.addOutfitMemory(
        userId,
        [
          tops[i % tops.length],
          bottoms[i % bottoms.length],
          shoes[i % shoes.length],
        ],
        i.isEven ? 'casual' : 'formal',
        _daysAgo(i + 1),
      );
    }
  }
}
