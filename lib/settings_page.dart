import 'package:flutter/material.dart';
import 'package:adaptive_theme/adaptive_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final themeMode = AdaptiveTheme.of(context).mode;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _buildSectionHeader(context, 'Appearance'),
          _buildThemeSettingTile(context, themeMode),
          const Divider(),
          _buildSectionHeader(context, 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Open Source Licenses'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: 'Simple Editor',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(
                  Icons.edit_note,
                  size: 48,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildThemeSettingTile(
    BuildContext context,
    AdaptiveThemeMode themeMode,
  ) {
    return ListTile(
      leading: Icon(
        themeMode == AdaptiveThemeMode.dark
            ? Icons.dark_mode
            : themeMode == AdaptiveThemeMode.light
            ? Icons.light_mode
            : Icons.brightness_auto,
      ),
      title: const Text('Theme'),
      subtitle: Text(
        themeMode == AdaptiveThemeMode.dark
            ? 'Dark'
            : themeMode == AdaptiveThemeMode.light
            ? 'Light'
            : 'System',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showThemeDialog(context),
    );
  }

  void _showThemeDialog(BuildContext context) {
    final currentMode = AdaptiveTheme.of(context).mode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                AdaptiveTheme.of(context).setLight();
                Navigator.pop(context);
                setState(() {});
              },
              child: RadioListTile<AdaptiveThemeMode>(
                title: const Text('Light'),
                value: AdaptiveThemeMode.light,
                selected: currentMode == AdaptiveThemeMode.light,
              ),
            ),
            GestureDetector(
              onTap: () {
                AdaptiveTheme.of(context).setDark();
                Navigator.pop(context);
                setState(() {});
              },
              child: RadioListTile<AdaptiveThemeMode>(
                title: const Text('Dark'),
                value: AdaptiveThemeMode.dark,
                selected: currentMode == AdaptiveThemeMode.dark,
              ),
            ),
            GestureDetector(
              onTap: () {
                AdaptiveTheme.of(context).setSystem();
                Navigator.pop(context);
                setState(() {});
              },
              child: RadioListTile<AdaptiveThemeMode>(
                title: const Text('System'),
                value: AdaptiveThemeMode.system,
                selected: currentMode == AdaptiveThemeMode.system,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
