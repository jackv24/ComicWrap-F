import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final _settingsBoxProvider = FutureProvider<Box>((ref) async {
  await Hive.initFlutter();

  Hive.registerAdapter(ThemeModeAdapter());
  return await Hive.openBox('settings');
});

final themeModeProvider =
    StateNotifierProvider<ThemeSettingNotifier, ThemeMode>((ref) {
  final box = ref.watch(_settingsBoxProvider);
  return ThemeSettingNotifier(box.data?.value);
});

class ThemeSettingNotifier extends StateNotifier<ThemeMode> {
  final Box? box;

  ThemeSettingNotifier(this.box) : super(ThemeMode.system) {
    final b = box;
    if (b == null) return;
    state = b.get('themeMode', defaultValue: ThemeMode.system);
  }

  void setTheme(ThemeMode themeMode) async {
    final b = box;
    if (b == null) return;
    b.put('themeMode', themeMode);
    state = themeMode;
  }
}

class ThemeModeAdapter extends TypeAdapter<ThemeMode> {
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
