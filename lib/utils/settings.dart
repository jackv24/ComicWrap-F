import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final _settingsBoxProvider = FutureProvider<Box>((ref) async {
  await Hive.initFlutter();

  Hive.registerAdapter(_ThemeModeAdapter());
  return await Hive.openBox('settings');
});

final themeModeProvider =
    StateNotifierProvider<HiveSettingNotifier<ThemeMode>, ThemeMode>((ref) {
  final box = ref.watch(_settingsBoxProvider);
  return HiveSettingNotifier(box.data?.value, 'themeMode', ThemeMode.system);
});

final comicNavBarToggleProvider = StateNotifierProvider.autoDispose
    .family<HiveSettingNotifier<bool>, bool, String>((ref, comicId) {
  final box = ref.watch(_settingsBoxProvider);
  return HiveSettingNotifier(
      box.data?.value, 'comicNavBarToggle_$comicId', false);
});

class HiveSettingNotifier<T> extends StateNotifier<T> {
  final Box? box;
  final String key;

  HiveSettingNotifier(this.box, this.key, T defaultValue)
      : super(defaultValue) {
    final b = box;
    if (b == null) return;
    state = b.get(key, defaultValue: defaultValue);
  }

  void setValue(T themeMode) async {
    final b = box;
    if (b == null) return;
    b.put(key, themeMode);
    state = themeMode;
  }
}

class _ThemeModeAdapter extends TypeAdapter<ThemeMode> {
  @override
  final typeId = 0;

  @override
  ThemeMode read(BinaryReader reader) {
    return ThemeMode.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, ThemeMode obj) {
    writer.writeByte(obj.index);
  }
}
