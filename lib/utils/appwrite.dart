import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const bool useLocalInstance = bool.fromEnvironment('USE_LOCAL_APPWRITE');
final _host =
    defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : 'localhost';

final clientProvider = Provider<Client>((ref) {
  return Client()
    ..setEndpoint('http://$_host/v1')
    ..setProject('comicwrap');
});

final realtimeProvider = Provider<Realtime>((ref) {
  final client = ref.watch(clientProvider);
  return Realtime(client);
});

final accountProvider = Provider<Account>((ref) {
  final client = ref.watch(clientProvider);
  return Account(client);
});
