import 'package:go_router/go_router.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/dashboard/presentation/settings_screen.dart';
import '../../features/documents/presentation/document_screen.dart';
import '../../features/scanner/presentation/scanner_screen.dart';
import '../../features/clients/presentation/client_list_screen.dart';
import '../../features/clients/presentation/create_client_screen.dart';
import '../../features/clients/presentation/client_details_screen.dart';
import '../../features/clients/domain/models.dart';
import '../../features/vendors/presentation/vendor_list_screen.dart';
import '../../features/vendors/presentation/create_vendor_screen.dart';
import '../../features/vendors/domain/vendor_model.dart';
import '../../features/inventory/presentation/inventory_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
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
        builder: (context, state) => ClientDetailsScreen(clientId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/generator',
        builder: (context, state) => const DocumentScreen(),
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
          final vendor = state.extra as VendorPartner?;
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
