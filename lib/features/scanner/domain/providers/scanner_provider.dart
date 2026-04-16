import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genesis_util/app/router.dart';
import 'package:go_router/go_router.dart';

class ScannerNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  Future<String?> scanSerial() async {
    // Navigate to scanner screen and wait for result
    final result = await rootNavigatorKey.currentContext?.push<String>(
      '/scanner',
    );
    return result;
  }
}

final scannerProvider = NotifierProvider<ScannerNotifier, bool>(
  ScannerNotifier.new,
);
