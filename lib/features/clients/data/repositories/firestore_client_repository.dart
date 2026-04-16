import 'package:genesis_util/core/services/firestore_service.dart';
import 'package:genesis_util/features/clients/domain/entities/client.dart';
import 'package:genesis_util/features/clients/domain/entities/client_document.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FirestoreClientRepository {
  FirestoreClientRepository(this._service);
  final FirestoreService _service;

  static const _clientsPath = 'clients';
  static const _documentsPath = 'documents';

  // --- Clients ---

  Stream<List<Client>> watchClients() {
    return _service.collectionStream<Client>(
      path: _clientsPath,
      builder: (data, id) => Client.fromJson({...data, 'id': id}),
      sort: (a, b) => b.createdAt.compareTo(a.createdAt),
    );
  }

  Future<void> syncLocalClients(List<Client> clients) async {
    await _service.batchUpload<Client>(
      path: _clientsPath,
      items: clients,
      toMap: (c) => c.toJson(),
      getId: (c) => c.id,
    );
  }

  Future<void> saveClient(Client client) async {
    await _service.setData(
      path: '$_clientsPath/${client.id}',
      data: client.toJson(),
    );
  }

  Future<void> deleteClient(String id) async {
    await _service.deleteData(path: '$_clientsPath/$id');
  }

  // --- Documents ---

  Stream<List<ClientDocument>> watchDocuments(String clientId) {
    return _service.collectionStream<ClientDocument>(
      path: _documentsPath,
      queryBuilder: (query) => query.where('clientId', isEqualTo: clientId),
      builder: (data, id) => ClientDocument.fromJson({...data, 'id': id}),
      sort: (a, b) => b.uploadedAt.compareTo(a.uploadedAt),
    );
  }

  Future<void> saveDocument(ClientDocument doc) async {
    await _service.setData(
      path: '$_documentsPath/${doc.id}',
      data: doc.toJson(),
    );
  }

  Future<void> deleteDocument(String id) async {
    await _service.deleteData(path: '$_documentsPath/$id');
  }
}

final firestoreClientRepositoryProvider = Provider<FirestoreClientRepository>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return FirestoreClientRepository(service);
});
