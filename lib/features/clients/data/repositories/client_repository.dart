import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesis_util/core/providers/theme_provider.dart';
import 'package:genesis_util/features/clients/domain/entities/client.dart';
import 'package:genesis_util/features/clients/domain/entities/client_document.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClientRepository {
  ClientRepository(this._prefs);
  final SharedPreferences _prefs;
  static const _clientsKey = 'genesis_clients_list';
  static const _docsKey = 'genesis_documents_list';

  // --- Clients ---

  List<Client> getClients() {
    final json = _prefs.getString(_clientsKey);
    if (json == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(json) as List<dynamic>;
      return decoded
          .map((e) => Client.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      throw Exception('Data corruption detected in clients: $e\n$stack');
    }
  }

  Future<void> saveClients(List<Client> clients) async {
    final encoded = jsonEncode(clients.map((e) => e.toJson()).toList());
    await _prefs.setString(_clientsKey, encoded);
  }

  // --- Documents ---

  List<ClientDocument> getDocuments() {
    final json = _prefs.getString(_docsKey);
    if (json == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(json) as List<dynamic>;
      return decoded
          .map((e) => ClientDocument.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      throw Exception('Data corruption detected in documents: $e\n$stack');
    }
  }

  Future<void> saveDocuments(List<ClientDocument> docs) async {
    final encoded = jsonEncode(docs.map((e) => e.toJson()).toList());
    await _prefs.setString(_docsKey, encoded);
  }
}

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ClientRepository(prefs);
});
