import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesis_util/features/clients/data/repositories/client_repository.dart';
import 'package:genesis_util/features/clients/domain/entities/client.dart';
import 'package:genesis_util/features/clients/domain/entities/client_document.dart';
import 'package:genesis_util/features/clients/domain/entities/hardware_config.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

class ClientsNotifier extends Notifier<List<Client>> {
  @override
  List<Client> build() {
    return ref.watch(clientRepositoryProvider).getClients();
  }

  Future<void> _save() async {
    try {
      await ref.read(clientRepositoryProvider).saveClients(state);
    } catch (e, stackTrace) {
      log(
        'Critical Error: Failed to save clients to local storage',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void addClient(Client client) {
    state = [...state, client];
    _save();
  }

  void deleteClient(String id) {
    state = state.where((c) => c.id != id).toList();
    _save();
  }

  void updateClient(Client updatedConfig) {
    state = state
        .map((c) => c.id == updatedConfig.id ? updatedConfig : c)
        .toList();
    _save();
  }

  void updateFinancials(
    String id, {
    required bool isSubsidy,
    required bool isLoan,
    double? solarCostRs,
    double? initialDepositRs,
  }) {
    state = state.map((c) {
      if (c.id != id) return c;
      return c.copyWith(
        solarCostRs: solarCostRs,
        isSubsidy: isSubsidy,
        isLoan: isLoan,
        initialDepositRs: initialDepositRs,
      );
    }).toList();
    _save();
  }

  void updateSystemDNA(
    String id, {
    required List<InverterConfiguration> inverters,
    required List<PanelConfiguration> panels,
  }) {
    state = state.map((c) {
      if (c.id != id) return c;
      final totalKwp = panels.fold(0.0, (sum, p) => sum + p.totalCapacityKwp);
      return c.copyWith(
        systemSizeKwp: totalKwp,
        inverterConfigs: inverters,
        panelConfigs: panels,
      );
    }).toList();
    _save();
  }

  void updateContactInfo(
    String id, {
    required String name,
    required String phone,
    required String address,
  }) {
    state = state
        .map(
          (c) => c.id == id
              ? c.copyWith(name: name, phone: phone, address: address)
              : c,
        )
        .toList();
    _save();
  }

  void updateUtilityIDs(
    String id, {
    required String consumerNumber,
    String? npApplicationNumber,
  }) {
    state = state
        .map(
          (c) => c.id == id
              ? c.copyWith(
                  consumerNumber: consumerNumber,
                  npApplicationNumber: npApplicationNumber,
                )
              : c,
        )
        .toList();
    _save();
  }

  void updateSubsidyStatus(String id, SubsidyStatus status) {
    state = state
        .map((c) => c.id == id ? c.copyWith(subsidyStatus: status) : c)
        .toList();
    _save();
  }

  void updateVendor(String id, String vendorName) {
    state = state
        .map((c) => c.id == id ? c.copyWith(vendorName: vendorName) : c)
        .toList();
    _save();
  }
}

class DocumentsNotifier extends Notifier<List<ClientDocument>> {
  @override
  List<ClientDocument> build() {
    return ref.watch(clientRepositoryProvider).getDocuments();
  }

  Future<void> _save() async {
    try {
      await ref.read(clientRepositoryProvider).saveDocuments(state);
    } catch (e, stackTrace) {
      log(
        'Critical Error: Failed to save documents to local storage',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void addDocument(ClientDocument doc) {
    state = [...state, doc];
    _save();
  }

  void removeDocument(String id) {
    state = state.where((d) => d.id != id).toList();
    _save();
  }

  void removeAllForClient(String clientId) {
    state = state.where((d) => d.clientId != clientId).toList();
    _save();
  }

  List<ClientDocument> getDocumentsForClient(String clientId) {
    return state.where((d) => d.clientId == clientId).toList();
  }
}

final clientsProvider = NotifierProvider<ClientsNotifier, List<Client>>(
  ClientsNotifier.new,
);

final documentsProvider =
    NotifierProvider<DocumentsNotifier, List<ClientDocument>>(
      DocumentsNotifier.new,
    );
