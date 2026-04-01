import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'models.dart';
import '../../../core/theme/theme_provider.dart';

const uuid = Uuid();

// Provider for the list of all clients
class ClientsNotifier extends Notifier<List<Client>> {
  static const _clientsKey = 'genesis_clients_list';

  @override
  List<Client> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final clientsJson = prefs.getString(_clientsKey);
    
    if (clientsJson == null) {
      return []; // Clean slate for production
    }

    try {
      final List<dynamic> decoded = jsonDecode(clientsJson);
      return decoded.map((e) => Client.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _save() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final encoded = jsonEncode(state.map((e) => e.toJson()).toList());
    await prefs.setString(_clientsKey, encoded);
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
    state = state.map((c) => c.id == updatedConfig.id ? updatedConfig : c).toList();
    _save();
  }

  void updateFinancials(String id, {
    double? solarCostRs,
    required bool isSubsidy,
    required bool isLoan,
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

  void updateSystemDNA(String id, {
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

  void updateContactInfo(String id, {
    required String name,
    required String phone,
    required String address,
  }) {
    state = state.map((c) => c.id == id ? c.copyWith(name: name, phone: phone, address: address) : c).toList();
    _save();
  }

  void updateUtilityIDs(String id, {
    required String consumerNumber,
    String? npApplicationNumber,
  }) {
    state = state.map((c) => c.id == id ? c.copyWith(consumerNumber: consumerNumber, npApplicationNumber: npApplicationNumber) : c).toList();
    _save();
  }

  void updateSubsidyStatus(String id, SubsidyStatus status) {
    state = state.map((c) => c.id == id ? c.copyWith(subsidyStatus: status) : c).toList();
    _save();
  }

  void updateVendor(String id, String vendorName) {
    state = state.map((c) => c.id == id ? c.copyWith(vendorName: vendorName) : c).toList();
    _save();
  }
}

// Provider for documents belonging to a specific client
class DocumentsNotifier extends Notifier<List<ClientDocument>> {
  static const _docsKey = 'genesis_documents_list';

  @override
  List<ClientDocument> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final docsJson = prefs.getString(_docsKey);
    
    if (docsJson == null) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(docsJson);
      return decoded.map((e) => ClientDocument.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _save() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final encoded = jsonEncode(state.map((e) => e.toJson()).toList());
    await prefs.setString(_docsKey, encoded);
  }

  void addDocument(ClientDocument doc) {
    state = [...state, doc];
    _save();
  }

  void removeDocument(String id) {
    state = state.where((d) => d.id != id).toList();
    _save();
  }

  List<ClientDocument> getDocumentsForClient(String clientId) {
    return state.where((d) => d.clientId == clientId).toList();
  }
}

final clientsProvider = NotifierProvider<ClientsNotifier, List<Client>>(ClientsNotifier.new);

final documentsProvider = NotifierProvider<DocumentsNotifier, List<ClientDocument>>(DocumentsNotifier.new);
