import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          _buildSectionHeader('Appearance'),
          const SizedBox(height: 16),
          _buildThemeSelector(context, ref, themeMode),
          const SizedBox(height: 48),
          
          _buildSectionHeader('About Genesis Hub'),
          const SizedBox(height: 16),
          _buildAboutCard(context),
          const SizedBox(height: 40),
          
          Center(
            child: Text(
              'Genesis Hub v1.0.0+1',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, WidgetRef ref, ThemeMode currentMode) {
    return Card(
      child: Column(
        children: [
          _buildThemeOption(
            context,
            ref,
            mode: ThemeMode.system,
            title: 'System Default',
            subtitle: 'Follow device settings',
            icon: Icons.brightness_auto_rounded,
            isSelected: currentMode == ThemeMode.system,
          ),
          const Divider(height: 1, indent: 64),
          _buildThemeOption(
            context,
            ref,
            mode: ThemeMode.light,
            title: 'Light Mode',
            subtitle: 'Classic bright experience',
            icon: Icons.light_mode_rounded,
            isSelected: currentMode == ThemeMode.light,
          ),
          const Divider(height: 1, indent: 64),
          _buildThemeOption(
            context,
            ref,
            mode: ThemeMode.dark,
            title: 'Dark Mode',
            subtitle: 'Easy on the eyes',
            icon: Icons.dark_mode_rounded,
            isSelected: currentMode == ThemeMode.dark,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref, {
    required ThemeMode mode,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon, 
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          size: 24,
        ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
      trailing: isSelected 
        ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary) 
        : null,
      onTap: () => ref.read(themeProvider.notifier).setThemeMode(mode),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.bolt_rounded, size: 48, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 24),
            const Text(
              'Genesis Hub',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -1),
            ),
            const SizedBox(height: 8),
            Text(
              'Professional Solar CRM & Automation',
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),
            _buildAboutTile(Icons.verified_user_rounded, 'Version', '1.0.0+1 (Release)'),
            _buildAboutTile(Icons.code_rounded, 'Developer', 'Genesis Engineering'),
            _buildAboutTile(Icons.business_center_rounded, 'Organization', 'Genesis Electrical'),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
