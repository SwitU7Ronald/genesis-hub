import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesis_util/features/clients/domain/entities/client.dart';
import 'package:genesis_util/features/clients/domain/entities/client_document.dart';
import 'package:genesis_util/features/clients/domain/entities/hardware_config.dart';
import 'package:genesis_util/features/clients/domain/providers/client_providers.dart';

class ClientDetailsController {
  ClientDetailsController(this.ref, this._clientId);
  final Ref ref;
  final String _clientId;

  // --- Financials ---

  void updateFinancials({
    required bool isSubsidy,
    required bool isLoan,
    double? solarCostRs,
    double? initialDepositRs,
  }) {
    ref
        .read(clientsProvider.notifier)
        .updateFinancials(
          _clientId,
          solarCostRs: solarCostRs,
          isSubsidy: isSubsidy,
          isLoan: isLoan,
          initialDepositRs: initialDepositRs,
        );
  }

  // --- System DNA ---

  void updateSystemDNA({
    required List<InverterConfiguration> inverters,
    required List<PanelConfiguration> panels,
  }) {
    ref
        .read(clientsProvider.notifier)
        .updateSystemDNA(_clientId, inverters: inverters, panels: panels);
  }

  // --- Documents ---

  void addDocument(ClientDocument doc) {
    ref.read(documentsProvider.notifier).addDocument(doc);
  }

  void removeDocument(String docId) {
    ref.read(documentsProvider.notifier).removeDocument(docId);
  }

  // --- Status & Vendor ---

  void updateSubsidyStatus(SubsidyStatus status) {
    ref.read(clientsProvider.notifier).updateSubsidyStatus(_clientId, status);
  }

  void updateVendor(String vendorName) {
    ref.read(clientsProvider.notifier).updateVendor(_clientId, vendorName);
  }
}

final clientDetailsControllerProvider = Provider.autoDispose
    .family<ClientDetailsController, String>((ref, id) {
      return ClientDetailsController(ref, id);
    });
