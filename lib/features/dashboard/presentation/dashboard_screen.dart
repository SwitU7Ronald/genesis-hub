import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/theme_provider.dart';
import '../../clients/domain/client_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark || (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
    final theme = Theme.of(context);
    final clients = ref.watch(clientsProvider);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;
          
          return CustomScrollView(
            slivers: [
              // Premium Glassmorphism Header
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                stretch: true,
                backgroundColor: theme.colorScheme.surface,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark 
                          ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                          : [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -50,
                          top: -50,
                          child: Icon(Icons.bolt_rounded, size: 300, color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('EEEE, MMMM d').format(DateTime.now()),
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Genesis Hub',
                                style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: -1.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_rounded, color: Colors.white),
                    onPressed: () => context.push('/settings'),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? constraints.maxWidth * 0.1 : 20.0,
                  vertical: 32.0,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const Text(
                      'Command Center', 
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)
                    ),
                    const SizedBox(height: 24),
                    
                    // Main Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: isWide ? 2 : 1,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      childAspectRatio: isWide ? 2.2 : 1.4,
                      children: [
                        _buildNavCard(
                          context,
                          theme,
                          title: 'Clients',
                          desc: 'Manage customer lifecycle and project database.',
                          icon: Icons.people_alt_rounded,
                          color: theme.colorScheme.primary,
                          onTap: () => context.push('/clients'),
                        ),
                        _buildNavCard(
                          context,
                          theme,
                          title: 'Vendor Partner',
                          desc: 'Configure partners and witness identity.',
                          icon: Icons.handshake_rounded,
                          color: const Color(0xFF10B981),
                          onTap: () => context.push('/vendors'),
                        ),
                        _buildNavCard(
                          context,
                          theme,
                          title: 'Inventory',
                          desc: 'Professional solar hardware stock control.',
                          icon: Icons.inventory_2_rounded,
                          color: const Color(0xFFF59E0B),
                          onTap: () => context.push('/inventory'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavCard(
    BuildContext context, 
    ThemeData theme, {
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 20),
              Text(
                title, 
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 18)
              ),
              const SizedBox(height: 8),
              Text(
                desc, 
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
