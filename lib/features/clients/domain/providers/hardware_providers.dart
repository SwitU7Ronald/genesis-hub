import 'package:flutter_riverpod/flutter_riverpod.dart';

class SerialListNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  void add(String serial) {
    if (!state.contains(serial)) {
      state = [...state, serial];
    }
  }

  void remove(int index) {
    state = [
      for (int i = 0; i < state.length; i++)
        if (i != index) state[i],
    ];
  }

  void updateSerial(String oldSerial, String newSerial) {
    state = state.map((s) => s == oldSerial ? newSerial : s).toList();
  }

  void clear() => state = [];

  void setSerials(List<String> serials) => state = serials;
}

final panelSerialsProvider =
    NotifierProvider.autoDispose<SerialListNotifier, List<String>>(
      SerialListNotifier.new,
    );

final inverterSerialsProvider =
    NotifierProvider.autoDispose<SerialListNotifier, List<String>>(
      SerialListNotifier.new,
    );
