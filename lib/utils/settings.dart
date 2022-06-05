import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings.g.dart';
part 'settings.freezed.dart';

const themeModeAdapterTypeId = 0;
const sortOptionSettingAdapterTypeId = 1;
const sortOptionAdapterTypeId = 2;

final _settingsBoxProvider = FutureProvider<Box>((ref) async {
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(themeModeAdapterTypeId)) {
    Hive.registerAdapter(_ThemeModeAdapter());
  }
  if (!Hive.isAdapterRegistered(sortOptionSettingAdapterTypeId)) {
    Hive.registerAdapter(SortOptionSettingAdapter());
  }
  if (!Hive.isAdapterRegistered(sortOptionAdapterTypeId)) {
    Hive.registerAdapter(SortOptionAdapter());
  }

  final box = await Hive.openBox('settings');

  ref.onDispose(() {
    box.close();
  });

  return box;
});

final themeModeProvider =
    StateNotifierProvider<HiveSettingNotifier<ThemeMode>, ThemeMode>((ref) {
  final box = ref.watch(_settingsBoxProvider);
  return HiveSettingNotifier(box.value, 'themeMode', ThemeMode.system);
});

@HiveType(typeId: sortOptionAdapterTypeId)
enum SortOption {
  @HiveField(0)
  lastRead,

  @HiveField(1)
  lastUpdated,

  @HiveField(2)
  title,
}

@freezed
abstract class SortOptionSetting with _$SortOptionSetting {
  @HiveType(typeId: sortOptionSettingAdapterTypeId)
  const factory SortOptionSetting({
    @HiveField(0) required SortOption sortOption,
    @HiveField(1) required bool reverse,
  }) = _SortOptionSetting;
}

final sortOptionProvider = StateNotifierProvider<
    HiveSettingNotifier<SortOptionSetting>, SortOptionSetting>((ref) {
  final box = ref.watch(_settingsBoxProvider);
  return HiveSettingNotifier(box.value, 'sortOption',
      const SortOptionSetting(sortOption: SortOption.lastRead, reverse: false));
});

final comicNavBarToggleProvider = StateNotifierProvider.autoDispose
    .family<HiveSettingNotifier<bool>, bool, String>((ref, comicId) {
  final box = ref.watch(_settingsBoxProvider);
  return HiveSettingNotifier(box.value, 'comicNavBarToggle_$comicId', false);
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

  void setValue(T value) async {
    final b = box;
    if (b == null) return;
    b.put(key, value);
    state = value;
  }
}

class _ThemeModeAdapter extends TypeAdapter<ThemeMode> {
  @override
  final typeId = themeModeAdapterTypeId;

  @override
  ThemeMode read(BinaryReader reader) {
    return ThemeMode.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, ThemeMode obj) {
    writer.writeByte(obj.index);
  }
}
