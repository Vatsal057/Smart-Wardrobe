import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _cityController = TextEditingController();
  final _apiKeyController = TextEditingController();
  bool _cityInitialized = false;

  @override
  void dispose() {
    _cityController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _saved(String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what saved', style: AppTheme.body), backgroundColor: AppColors.bgSurface2));
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user ?? {};
    if (!_cityInitialized && user['city'] != null) {
      _cityController.text = user['city'];
      _cityInitialized = true;
    }

    return Scaffold(backgroundColor: AppColors.bgBase,
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(AppSpacing.xl), children: [
        Text('Settings', style: AppTheme.title), const SizedBox(height: AppSpacing.lg),
        // User info
        Container(padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(color: AppColors.bgSurface1, borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.borderSubtle, width: 0.5)),
          child: Row(children: [
            CircleAvatar(radius: 24, backgroundColor: AppColors.bgSurface2,
              child: Text((user['name'] ?? 'U')[0].toUpperCase(),
                style: AppTheme.title.copyWith(fontSize: 20, color: AppColors.gold))),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user['name'] ?? 'User', style: AppTheme.body.copyWith(fontWeight: FontWeight.w500)),
              Text(user['email'] ?? '', style: AppTheme.caption)]))])),
        const SizedBox(height: AppSpacing.xl),

        // City (used for live weather)
        Text('CITY', style: AppTheme.label), const SizedBox(height: 8),
        Text('Used for weather-aware outfit suggestions.', style: AppTheme.caption),
        const SizedBox(height: 8),
        TextField(controller: _cityController, style: AppTheme.body,
          decoration: const InputDecoration(hintText: 'e.g. Mumbai'),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) { auth.updateUser({'city': v.trim()}); _saved('City'); }
          }),
        const SizedBox(height: AppSpacing.xl),

        // Notifications
        Text('NOTIFICATIONS', style: AppTheme.label), const SizedBox(height: 12),
        _toggle('Daily Outfit', Icons.wb_sunny_outlined, user['notify_enabled'] == 1 || user['notify_enabled'] == true,
          (v) => auth.updateUser({'notify_enabled': v})),
        _toggle('Weekly Plan', Icons.calendar_today_outlined, user['weekly_plan_enabled'] == 1 || user['weekly_plan_enabled'] == true,
          (v) => auth.updateUser({'weekly_plan_enabled': v})),
        _toggle('Wash Reminders', Icons.local_laundry_service_outlined, user['wash_notify_enabled'] == 1 || user['wash_notify_enabled'] == true,
          (v) => auth.updateUser({'wash_notify_enabled': v})),
        _toggle('Weather Alerts', Icons.cloud_outlined, user['weather_anomaly_enabled'] == 1 || user['weather_anomaly_enabled'] == true,
          (v) => auth.updateUser({'weather_anomaly_enabled': v})),
        const SizedBox(height: AppSpacing.xl),

        // API Key
        Text('GEMINI API KEY', style: AppTheme.label), const SizedBox(height: 8),
        Text('For AI-powered style notes and template generation.', style: AppTheme.caption),
        const SizedBox(height: 8),
        TextField(controller: _apiKeyController, style: AppTheme.body, obscureText: true,
          decoration: InputDecoration(
            hintText: (user['api_key'] as String?)?.isNotEmpty == true ? '••••••••  (key saved)' : 'Paste your Gemini API key'),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) {
              auth.updateUser({'api_key': v.trim()});
              _apiKeyController.clear();
              _saved('API key');
            }
          }),
        const SizedBox(height: AppSpacing.xl),

        // Logout
        SizedBox(width: double.infinity, height: 52, child: InkWell(
          onTap: () => auth.logout(),
          borderRadius: BorderRadius.circular(8),
          child: Container(decoration: BoxDecoration(
            color: AppColors.redFaint, borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.red.withValues(alpha: 0.3))),
            child: Center(child: Text('Logout', style: AppTheme.body.copyWith(color: AppColors.red)))))),
        const SizedBox(height: AppSpacing.xl),
      ])));
  }

  Widget _toggle(String label, IconData icon, bool value, ValueChanged<bool> onChanged) => Container(
    margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(color: AppColors.bgSurface1, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.borderSubtle, width: 0.5)),
    child: Row(children: [Icon(icon, color: AppColors.textSecondary, size: 20), const SizedBox(width: 12),
      Expanded(child: Text(label, style: AppTheme.body.copyWith(fontSize: 14))),
      Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.gold)]));
}
