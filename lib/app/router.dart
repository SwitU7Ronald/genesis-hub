import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesis_util/features/clients/domain/entities/client.dart';
import 'package:genesis_util/features/clients/presentation/client_details_screen.dart';
import 'package:genesis_util/features/clients/presentation/screens/client_list_screen.dart';
import 'package:genesis_util/features/clients/presentation/screens/create_client_screen.dart';
// Features (New Clean Architecture Paths)
import 'package:genesis_util/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:genesis_util/features/dashboard/presentation/screens/settings_screen.dart';
import 'package:genesis_util/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:genesis_util/features/scanner/presentation/screens/scanner_screen.dart';
import 'package:genesis_util/features/vendors/domain/entities/vendor.dart';
import 'package:genesis_util/features/vendors/presentation/screens/create_vendor_screen.dart';
import 'package:genesis_util/features/vendors/presentation/screens/vendor_list_screen.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/clients',
        builder: (context, state) => const ClientListScreen(),
      ),
      GoRoute(
        path: '/create-client',
        builder: (context, state) {
          final client = state.extra as Client?;
          return CreateClientScreen(existingClient: client);
        },
      ),
      GoRoute(
        path: '/client/:id',
        builder: (context, state) =>
            ClientDetailsScreen(clientId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/scanner',
        builder: (context, state) => const ScannerScreen(),
      ),
      GoRoute(
        path: '/vendors',
        builder: (context, state) => const VendorListScreen(),
      ),
      GoRoute(
        path: '/vendors/create',
        builder: (context, state) {
          final vendor = state.extra as Vendor?;
          return CreateVendorScreen(existingVendor: vendor);
        },
      ),
      GoRoute(
        path: '/inventory',
        builder: (context, state) => const InventoryScreen(),
      ),
    ],
  );
});
