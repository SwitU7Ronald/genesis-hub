import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:genesis_util/core/widgets/app_card.dart';
import 'package:genesis_util/features/clients/domain/entities/client.dart';
import 'package:genesis_util/features/clients/domain/entities/client_document.dart';

class DocumentsTab extends StatelessWidget {
  const DocumentsTab({
    required this.client,
    required this.isWide,
    required this.documents,
    required this.onPreview,
    required this.onDownload,
    required this.onUpload,
    required this.onScan,
    required this.onCamera,

    required this.onDelete,
    super.key,
  });
  final Client client;
  final bool isWide;
  final List<ClientDocument> documents;
  final Function(ClientDocument) onPreview;
  final Function(ClientDocument) onDownload;
  final Function(Client, DocumentType) onUpload;
  final Function(Client, DocumentType) onScan;
  final Function(Client, DocumentType) onCamera;

  final Function(ClientDocument) onDelete;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 40 : 20, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              _buildCategoryCard(
                context,
                'Professional Documents',
                Icons.description_rounded,
                [
                  DocumentType.quotation,
                  DocumentType.agreement,
                  DocumentType.selfCertificate,
                ],
              ),
              const SizedBox(height: 24),
              _buildCategoryCard(
                context,
                'Government Documents',
                Icons.account_balance_rounded,
                [
                  DocumentType.aadhar,
                  DocumentType.pan,
                  DocumentType.electricityBill,
                  DocumentType.verapavti,
                ],
              ),
              const SizedBox(height: 24),
              _buildCategoryCard(
                context,
                'Bank References',
                Icons.account_balance_wallet_rounded,
                [DocumentType.cancelledCheque, DocumentType.bankPassbook],
              ),
              const SizedBox(height: 24),
              _buildCategoryCard(
                context,
                'Site Verification',
                Icons.satellite_alt_rounded,
                [
                  DocumentType.roofPhotoPreInstall,
                  DocumentType.roofPhotoPostInstall,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  ClientDocument? _findDocument(DocumentType type) {
    try {
      return documents.firstWhere((doc) => doc.type == type);
    } catch (_) {
      return null;
    }
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    IconData icon,
    List<DocumentType> requiredTypes,
  ) {
    return AppCard(
      title: title,
      icon: icon,
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: requiredTypes.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        itemBuilder: (context, index) =>
            _buildDocumentRow(context, requiredTypes[index]),
      ),
    );
  }

  Widget _buildDocumentRow(BuildContext context, DocumentType expectedType) {
    final doc = _findDocument(expectedType);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasDoc = doc != null;

    final isGovType =
        expectedType == DocumentType.aadhar ||
        expectedType == DocumentType.pan ||
        expectedType == DocumentType.electricityBill ||
        expectedType == DocumentType.verapavti;
    final isBankType =
        expectedType == DocumentType.cancelledCheque ||
        expectedType == DocumentType.bankPassbook;
    final isProfessionalType =
        expectedType == DocumentType.quotation ||
        expectedType == DocumentType.agreement ||
        expectedType == DocumentType.selfCertificate;

    final isMobile = !kIsWeb && 
        (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);

    final showScanOptions = (isGovType || isBankType || isProfessionalType) && isMobile;
    
    final isSiteVerification =
        (expectedType == DocumentType.roofPhotoPreInstall ||
        expectedType == DocumentType.roofPhotoPostInstall ||
        expectedType == DocumentType.sitePhoto) && isMobile;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 20 : 12, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isWide ? 12 : 8),
            decoration: BoxDecoration(
              color: hasDoc
                  ? Colors.green.withValues(alpha: 0.1)
                  : colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              hasDoc ? Icons.check_rounded : _getIconForType(expectedType),
              size: 24,
              color: hasDoc ? Colors.green : colorScheme.onSecondaryContainer,
            ),
          ),
          SizedBox(width: isWide ? 16 : 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    Text(
                      _formatDocName(expectedType),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: hasDoc
                            ? theme.colorScheme.onSurface
                            : Colors.grey,
                      ),
                    ),
                    if (hasDoc)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Uploaded',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  hasDoc
                      ? 'Date: ${doc.uploadedAt.toString().split(' ')[0]}'
                      : 'Pending Document',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: hasDoc ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: isWide ? 16 : 8),
          if (hasDoc)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildIconButton(
                  context,
                  Icons.visibility_rounded,
                  'Preview',
                  () => onPreview(doc),
                ),
                SizedBox(width: isWide ? 8 : 4),
                _buildIconButton(
                  context,
                  Icons.download_rounded,
                  'Download',
                  () => onDownload(doc),
                ),
                SizedBox(width: isWide ? 8 : 4),
                _buildIconButton(
                  context,
                  Icons.edit_document,
                  'Replace',
                  () => onUpload(client, expectedType),
                ),
                SizedBox(width: isWide ? 8 : 4),
                _buildIconButton(
                  context,
                  Icons.delete_rounded,
                  'Delete',
                  () => onDelete(doc),
                  color: colorScheme.error,
                ),
              ],
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showScanOptions) ...[
                  _buildIconButton(
                    context,
                    Icons.document_scanner_rounded,
                    'Scan',
                    () => onScan(client, expectedType),
                  ),
                  SizedBox(width: isWide ? 8 : 4),
                ],
                if (isSiteVerification) ...[
                  _buildIconButton(
                    context,
                    Icons.camera_alt_rounded,
                    'Camera',
                    () => onCamera(client, expectedType),
                  ),
                  SizedBox(width: isWide ? 8 : 4),
                ],
                _buildIconButton(
                  context,
                  Icons.upload_rounded,
                  'Attach',
                  () => onUpload(client, expectedType),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context,
    IconData icon,
    String tooltip,
    VoidCallback onPressed, {
    Color? color,
  }) {
    final defaultColor = Theme.of(context).colorScheme.primary;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (color ?? defaultColor).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: color ?? defaultColor),
        ),
      ),
    );
  }

  IconData _getIconForType(DocumentType type) {
    switch (type) {
      case DocumentType.aadhar:
      case DocumentType.pan:
        return Icons.badge_rounded;
      case DocumentType.electricityBill:
        return Icons.receipt_long_rounded;
      case DocumentType.verapavti:
        return Icons.house_rounded;
      case DocumentType.cancelledCheque:
      case DocumentType.bankPassbook:
        return Icons.account_balance_rounded;
      case DocumentType.roofPhotoPreInstall:
      case DocumentType.roofPhotoPostInstall:
      case DocumentType.sitePhoto:
        return Icons.home_work_rounded;
      case DocumentType.quotation:
      case DocumentType.agreement:
      case DocumentType.selfCertificate:
      case DocumentType.npApplication:
      case DocumentType.identityProof:
      case DocumentType.other:
        return Icons.insert_drive_file_rounded;
    }
  }

  String _formatDocName(DocumentType type) {
    var name = type.name;
    // Basic camelCase to Title Case
    name = name.replaceAllMapped(
      RegExp('[A-Z]'),
      (match) => ' ${match.group(0)}',
    );
    return name.substring(0, 1).toUpperCase() + name.substring(1);
  }
}
