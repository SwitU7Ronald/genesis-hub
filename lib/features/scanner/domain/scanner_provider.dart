import 'package:flutter_riverpod/flutter_riverpod.dart';

class PanelSerialsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  void add(String serial) {
    if (!state.contains(serial)) state = [...state, serial];
  }

  void remove(String serial) {
    state = state.where((s) => s != serial).toList();
  }

  void update(String oldSerial, String newSerial) {
    state = state.map((s) => s == oldSerial ? newSerial : s).toList();
  }

  void clear() => state = [];
}

final panelSerialsProvider = NotifierProvider<PanelSerialsNotifier, List<String>>(PanelSerialsNotifier.new);

class InverterSerialsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  void add(String serial) {
    if (!state.contains(serial)) state = [...state, serial];
  }

  void remove(String serial) {
    state = state.where((s) => s != serial).toList();
  }

  void update(String oldSerial, String newSerial) {
    state = state.map((s) => s == oldSerial ? newSerial : s).toList();
  }

  void clear() => state = [];
}

final inverterSerialsProvider = NotifierProvider<InverterSerialsNotifier, List<String>>(InverterSerialsNotifier.new);
