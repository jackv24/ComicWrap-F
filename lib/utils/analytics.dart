import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:comicwrap_f/utils/firebase.dart';

final analyticsProvider = FutureProvider<FirebaseAnalytics>((ref) async {
  await ref.watch(firebaseProvider.future);
  return FirebaseAnalytics.instance;
});
