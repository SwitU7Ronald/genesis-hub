import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesis_util/features/clients/data/repositories/client_repository.dart';
import 'package:genesis_util/features/clients/data/repositories/firestore_client_repository.dart';
import 'package:genesis_util/features/clients/domain/entities/client.dart';
import 'package:genesis_util/features/clients/domain/entities/client_document.dart';
import 'package:genesis_util/features/clients/domain/entities/hardware_config.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

// Raw streams from Firestore
final clientsStreamProvider = StreamProvider<List<Client>>((ref) {
  return ref.watch(firestoreClientRepositoryProvider).watchClients();
});

class ClientsNotifier extends Notifier<List<Client>> {
  @override
  List<Client> build() {
    final firestoreClients = ref.watch(clientsStreamProvider).value ?? [];
    
    // One-time migration logic
    if (firestoreClients.isEmpty) {
      _migrateLocalData();
    }
    
    return firestoreClients;
  }

  Future<void> _migrateLocalData() async {
    final localClients = ref.read(clientRepositoryProvider).getClients();
    if (localClients.isNotEmpty) {
      log('Migrating ${localClients.length} clients to Firestore...');
      await ref.read(firestoreClientRepositoryProvider).syncLocalClients(localClients);
    }
  }

  Future<void> addClient(Client client) async {
    await ref.read(firestoreClientRepositoryProvider).saveClient(client);
  }

  Future<void> deleteClient(String id) async {
    await ref.read(firestoreClientRepositoryProvider).deleteClient(id);
  }

  Future<void> updateClient(Client updatedConfig) async {
    await ref.read(firestoreClientRepositoryProvider).saveClient(updatedConfig);
  }

  Future<void> updateFinancials(
    String id, {
    required bool isSubsidy,
    required bool isLoan,
    double? solarCostRs,
    double? initialDepositRs,
  }) async {
    final client = state.firstWhere((c) => c.id == id);
    final updated = client.copyWith(
      solarCostRs: solarCostRs,
      isSubsidy: isSubsidy,
      isLoan: isLoan,
      initialDepositRs: initialDepositRs,
    );
    await updateClient(updated);
  }

  Future<void> updateSystemDNA(
    String id, {
    required List<InverterConfiguration> inverters,
    required List<PanelConfiguration> panels,
  }) async {
    final client = state.firstWhere((c) => c.id == id);
    final totalKwp = panels.fold(0.0, (sum, p) => sum + p.totalCapacityKwp);
    final updated = client.copyWith(
      systemSizeKwp: totalKwp,
      inverterConfigs: inverters,
      panelConfigs: panels,
    );
    await updateClient(updated);
  }

  Future<void> updateContactInfo(
    String id, {
    required String name,
    required String phone,
    required String address,
  }) async {
    final client = state.firstWhere((c) => c.id == id);
    final updated = client.copyWith(name: name, phone: phone, address: address);
    await updateClient(updated);
  }

  Future<void> updateUtilityIDs(
    String id, {
    required String consumerNumber,
    String? npApplicationNumber,
  }) async {
    final client = state.firstWhere((c) => c.id == id);
    final updated = client.copyWith(
      consumerNumber: consumerNumber,
      npApplicationNumber: npApplicationNumber,
    );
    await updateClient(updated);
  }

  Future<void> updateSubsidyStatus(String id, SubsidyStatus status) async {
    final client = state.firstWhere((c) => c.id == id);
    final updated = client.copyWith(subsidyStatus: status);
    await updateClient(updated);
  }

  Future<void> updateVendor(String id, String vendorName) async {
    final client = state.firstWhere((c) => c.id == id);
    final updated = client.copyWith(vendorName: vendorName);
    await updateClient(updated);
  }
}

// Documents
final documentsStreamProvider = StreamProvider.family<List<ClientDocument>, String>((ref, clientId) {
  return ref.watch(firestoreClientRepositoryProvider).watchDocuments(clientId);
});

class DocumentsNotifier extends Notifier<List<ClientDocument>> {
  @override
  List<ClientDocument> build() {
    // Note: Documents are now fetched per-client in real-time.
    // We keep this global list for backward compatibility if needed, 
    // but the UI should ideally use documentsStreamProvider(clientId).
    return []; 
  }

  Future<void> addDocument(ClientDocument doc) async {
    await ref.read(firestoreClientRepositoryProvider).saveDocument(doc);
  }

  Future<void> removeDocument(String id) async {
    await ref.read(firestoreClientRepositoryProvider).deleteDocument(id);
  }
}

final clientsProvider = NotifierProvider<ClientsNotifier, List<Client>>(
  ClientsNotifier.new,
);

final documentsProvider =
    NotifierProvider<DocumentsNotifier, List<ClientDocument>>(
      DocumentsNotifier.new,
    );
