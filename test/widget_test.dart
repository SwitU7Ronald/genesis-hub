import 'package:flutter_test/flutter_test.dart';
import 'package:genesis_util/app/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App bootloader smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const GenesisBootloader());
    await tester.pumpAndSettle();
    expect(find.textContaining('Genesis'), findsWidgets);
  });
}
