import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_util/features/clients/domain/entities/client.dart';

void main() {
  group('Client Financials Calculations', () {
    test('Cash Client - Full Subsidy', () {
      final client = Client(
        id: '1',
        name: 'Test',
        phone: '123',
        address: '123',
        consumerNumber: '1',
        systemSizeKwp: 5,
        createdAt: DateTime.now(),
        solarCostRs: 250000,
      );

      expect(client.totalQuotation, 250000.0);
      expect(client.netFinalClientCost, 172000.0); // 250000 - 78000
      expect(
        client.strategicLoanAmount,
        0.0,
      ); // Cash client means loan amount = 0
      expect(
        client.advisedDownpayment,
        250000.0,
      ); // No loan, so full downpayment
    });

    test('Loan Client - Within Strategy Tier', () {
      final client = Client(
        id: '2',
        name: 'Test',
        phone: '123',
        address: '123',
        consumerNumber: '1',
        systemSizeKwp: 5,
        createdAt: DateTime.now(),
        solarCostRs: 200000,
        isLoan: true, // Financed with loan
      );

      const expectedMaxLoan = 200000.0 * 0.9; // 180000.0

      expect(client.maxBankLoanLimit, expectedMaxLoan);
      // Strategic bound checks if maxBankLoanLimit < 198000.0 then returns maxBankLoanLimit.
      expect(client.strategicLoanAmount, expectedMaxLoan);
      expect(client.advisedDownpayment, 200000.0 - expectedMaxLoan); // 20000.0
      expect(client.netFinalClientCost, 122000.0);
    });

    test('Loan Client - Cap Strategy Tier at 1.98 Lakh', () {
      final client = Client(
        id: '3',
        name: 'Test',
        phone: '123',
        address: '123',
        consumerNumber: '1',
        systemSizeKwp: 5,
        createdAt: DateTime.now(),
        solarCostRs: 500000,
        isLoan: true,
      );

      const expectedMaxLoan = 500000.0 * 0.9; // 450000.0
      expect(client.maxBankLoanLimit, expectedMaxLoan);
      // Expected to be capped at 198000.0
      expect(client.strategicLoanAmount, 198000.0);
      expect(client.advisedDownpayment, 500000.0 - 198000.0); // 302000.0
    });
  });
}
