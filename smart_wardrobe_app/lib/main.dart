import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/today_screen.dart';
import 'screens/wardrobe_screen.dart';
import 'screens/add_item_screen.dart';
import 'screens/week_screen.dart';
import 'screens/wash_screen.dart';
import 'screens/generate_screen.dart';
import 'screens/packing_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..init(),
      child: const SmartWardrobeApp(),
    ),
  );
}

class SmartWardrobeApp extends StatelessWidget {
  const SmartWardrobeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Wardrobe',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: Consumer<AuthProvider>(
        builder: (_, auth, __) {
          if (auth.isLoggedIn) return const MainShell();
          return const LoginScreen();
        },
      ),
      routes: {
        '/add-item': (_) => const AddItemScreen(),
        '/generate': (_) => const GenerateScreen(),
        '/packing': (_) => const PackingScreen(),
        '/wash': (_) => const WashScreen(),
        '/stats': (_) => const StatsScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}

/// Bottom-nav shell with 4 main tabs.
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _screens = const [
    TodayScreen(),
    WardrobeScreen(),
    WeekScreen(),
    InsightsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.bgSurface1,
          border: Border(top: BorderSide(color: AppColors.borderSubtle, width: 0.5)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: AppSpacing.bottomNavHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.wb_sunny_outlined, 'TODAY', 0),
                _navItem(Icons.checkroom_outlined, 'CLOSET', 1),
                _navItem(Icons.calendar_today_outlined, 'WEEK', 2),
                _navItem(Icons.insights_outlined, 'INSIGHTS', 3),
                _moreButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final active = _index == index;
    return GestureDetector(
      onTap: () => setState(() => _index = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: active ? AppColors.gold : AppColors.textTertiary),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w500, letterSpacing: 1,
              color: active ? AppColors.gold : AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }

  Widget _moreButton() {
    return GestureDetector(
      onTap: () => _showMoreMenu(),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.more_horiz, size: 22, color: AppColors.textTertiary),
            const SizedBox(height: 4),
            Text('MORE', style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w500, letterSpacing: 1,
              color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgSurface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(
              color: AppColors.borderDefault, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: AppSpacing.lg),
            _menuItem(ctx, Icons.auto_awesome_outlined, 'Generate Outfit', '/generate'),
            _menuItem(ctx, Icons.local_laundry_service_outlined, 'Wash Tracker', '/wash'),
            _menuItem(ctx, Icons.luggage_outlined, 'Packing List', '/packing'),
            _menuItem(ctx, Icons.bar_chart_outlined, 'Statistics', '/stats'),
            _menuItem(ctx, Icons.settings_outlined, 'Settings', '/settings'),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(BuildContext ctx, IconData icon, String label, String route) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(label, style: AppTheme.body),
      onTap: () { Navigator.pop(ctx); Navigator.pushNamed(context, route); },
    );
  }
}
