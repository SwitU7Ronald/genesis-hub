import 'package:flutter/material.dart';

import 'package:genesis_util/core/utils/currency_formatter.dart';
import 'package:genesis_util/core/widgets/app_card.dart';
import 'package:genesis_util/core/widgets/stat_row.dart';
import 'package:genesis_util/features/clients/domain/entities/client.dart';

class EconomicsTab extends StatelessWidget {
  const EconomicsTab({
    required this.client,
    required this.isWide,
    required this.onEditFinancials,
    super.key,
  });
  final Client client;
  final bool isWide;
  final VoidCallback onEditFinancials;

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
              _buildEconomicsIntro(context),
              const SizedBox(height: 32),
              _buildStrategicFinancials(context),
              const SizedBox(height: 32),
              _buildSubsidyStatus(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEconomicsIntro(BuildContext context) {
    final theme = Theme.of(context);
    final hasQuote = client.solarCostRs != null && client.solarCostRs! > 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PROJECT QUOTATION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasQuote
                  ? CurrencyFormatter.formatINR(client.totalQuotation)
                  : 'Not Configured',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: hasQuote ? theme.colorScheme.primary : Colors.grey,
                letterSpacing: -1,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: onEditFinancials,
          icon: const Icon(Icons.edit_note_rounded),
          label: const Text('Edit Terms'),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildStrategicFinancials(BuildContext context) {
    if (client.solarCostRs == null || client.solarCostRs == 0.0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final total = client.totalQuotation;

    return AppCard(
      title: 'Funding Model',
      icon: Icons.pie_chart_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                client.isLoan
                    ? Icons.account_balance_rounded
                    : Icons.payments_rounded,
                color: client.isLoan ? Colors.blue : Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  client.isLoan
                      ? 'Bank Financed Model'
                      : 'Direct Payment Model',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              if (client.isLoan && client.strategicLoanAmount == 198000.0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'OPTIMIZED CAPPED LOAN',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          if (client.isLoan) ...[
            _buildSplitBar(context),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: StatRow(
                    label: 'ADVISED LOAN',
                    value: CurrencyFormatter.formatINR(
                      client.strategicLoanAmount,
                    ),
                    isHero: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatRow(
                    label: 'DOWNPAYMENT (INC. SUBSIDY)',
                    value: CurrencyFormatter.formatINR(
                      client.advisedDownpayment,
                    ),
                    isSecondary: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StatRow(
              label: 'PREDICTED EMI (10 YRS @ 9%)',
              value: CurrencyFormatter.formatINR(client.estimatedMonthlyEmi),
              isSecondary: true,
            ),
          ] else ...[
            StatRow(
              label: 'TOTAL PAYABLE BY CLIENT',
              value: CurrencyFormatter.formatINR(total),
              isHero: true,
            ),
          ],

          const Divider(height: 48),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 24,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NET COST (AFTER SUBSIDY)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.7,
                          ),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatINR(client.netFinalClientCost),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitBar(BuildContext context) {
    if (client.totalQuotation == 0) return const SizedBox.shrink();

    final loanFlex =
        ((client.strategicLoanAmount / client.totalQuotation) * 100).toInt();
    final cashFlex = 100 - loanFlex;

    return Container(
      height: 12,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
      child: Row(
        children: [
          if (loanFlex > 0)
            Expanded(
              flex: loanFlex,
              child: Container(color: Colors.blue),
            ),
          if (cashFlex > 0)
            Expanded(
              flex: cashFlex,
              child: Container(color: Colors.green),
            ),
        ],
      ),
    );
  }

  Widget _buildSubsidyStatus(BuildContext context) {
    if (!client.isSubsidy) return const SizedBox.shrink();

    final statusColor = _getSubsidyColor(client.subsidyStatus);

    return AppCard(
      title: 'Subsidy Lifecycle',
      icon: Icons.savings_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatRow(
            label: 'SUBSIDY TARGET',
            value: CurrencyFormatter.formatINR(client.subsidyAmount),
            isSecondary: true,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.flag_circle_rounded, size: 16, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  client.subsidyStatus.name.toUpperCase().replaceAll('_', ' '),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getSubsidyColor(SubsidyStatus status) {
    switch (status) {
      case SubsidyStatus.pendingInstallation:
        return Colors.orange;
      case SubsidyStatus.meteringInProgress:
        return Colors.blue;
      case SubsidyStatus.readyForRedemption:
        return Colors.purple;
      case SubsidyStatus.collected:
        return Colors.green;
    }
  }
}
