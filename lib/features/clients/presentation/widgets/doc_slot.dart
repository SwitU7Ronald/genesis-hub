import 'package:flutter/material.dart';
import 'package:genesis_util/features/clients/domain/entities/client.dart';
import 'package:genesis_util/features/clients/domain/entities/client_document.dart';

class DocSlot extends StatelessWidget {
  const DocSlot({
    required this.client,
    required this.type,
    required this.label,
    required this.onPreview,
    required this.onDownload,
    required this.onUpload,
    required this.onDelete,
    super.key,
    this.existingDoc,
  });
  final Client client;
  final ClientDocument? existingDoc;
  final DocumentType type;
  final String label;
  final Function(ClientDocument) onPreview;
  final Function(ClientDocument) onDownload;
  final Function(Client, DocumentType) onUpload;
  final Function(ClientDocument) onDelete;

  @override
  Widget build(BuildContext context) {
    final doc = existingDoc;
    final hasDoc = doc != null;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasDoc
            ? Colors.green.withValues(alpha: 0.05)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasDoc
              ? Colors.green.withValues(alpha: 0.2)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: hasDoc
                  ? Colors.green.withValues(alpha: 0.1)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              hasDoc
                  ? Icons.check_circle_rounded
                  : Icons.pending_actions_rounded,
              color: hasDoc
                  ? Colors.green
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (doc != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    doc.fileName,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (doc != null) ...[
            IconButton(
              onPressed: () => onPreview(doc),
              icon: Icon(
                Icons.remove_red_eye_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              tooltip: 'Preview / View',
            ),
            IconButton(
              onPressed: () => onDownload(doc),
              icon: Icon(
                Icons.download_rounded,
                size: 20,
                color: theme.colorScheme.secondary,
              ),
              tooltip: 'Export',
            ),
            IconButton(
              onPressed: () => onUpload(client, type),
              icon: const Icon(Icons.upload_file_rounded, size: 20),
              tooltip: 'Replace',
            ),
            IconButton(
              onPressed: () => onDelete(doc),
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: theme.colorScheme.error,
              ),
              tooltip: 'Delete',
            ),
          ] else ...[
            TextButton.icon(
              onPressed: () => onUpload(client, type),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add'),
              style: TextButton.styleFrom(
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
