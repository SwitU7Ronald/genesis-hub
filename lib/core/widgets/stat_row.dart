import 'package:flutter/material.dart';

class StatRow extends StatelessWidget {
  const StatRow({
    required this.label,
    required this.value,
    super.key,
    this.icon,
    this.onCopy,
    this.onAction,
    this.actionIcon,
    this.isHero = false,
    this.isSecondary = false,
  });
  final String label;
  final String value;
  final IconData? icon;
  final VoidCallback? onCopy;
  final VoidCallback? onAction;
  final IconData? actionIcon;
  final bool isHero;
  final bool isSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final localOnCopy = onCopy;
    final localOnAction = onAction;
    final localActionIcon = actionIcon;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSecondary
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSecondary ? 16 : 0,
            vertical: isSecondary ? 16 : 4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 18,
                      color: theme.colorScheme.primary.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontWeight: isHero ? FontWeight.bold : FontWeight.w600,
                        fontSize: isHero ? 18 : 15,
                        color: isHero
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (localOnCopy != null) ...[
                        const SizedBox(width: 8),
                        _ActionCircle(
                          icon: Icons.content_copy_rounded,
                          onTap: localOnCopy,
                          isSecondary: true,
                        ),
                      ],
                      if (localOnAction != null && localActionIcon != null) ...[
                        const SizedBox(width: 12),
                        _ActionCircle(
                          icon: localActionIcon,
                          onTap: localOnAction,
                          isSecondary: false,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCircle extends StatelessWidget {
  const _ActionCircle({
    required this.icon,
    required this.onTap,
    required this.isSecondary,
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool isSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: isSecondary ? 'Copy to Clipboard' : 'Action',
      child: Material(
        color: isSecondary
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : theme.colorScheme.primary.withValues(alpha: 0.1),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 16,
              color: isSecondary
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
