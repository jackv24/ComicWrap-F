import 'package:comicwrap_f/pages/auth/email_verify_screen.dart';
import 'package:comicwrap_f/pages/auth/sign_in_screen.dart';
import 'package:comicwrap_f/pages/library/library_screen.dart';
import 'package:comicwrap_f/utils/auth.dart';
import 'package:comicwrap_f/utils/firebase.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    // Setup global style for loading blocker
    EasyLoading.instance
      ..userInteractions = false
      ..maskType = EasyLoadingMaskType.black;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ComicWrap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.light(),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        colorScheme: const ColorScheme.dark(),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Firebase init
      home: Consumer(
        builder: (context, ref, child) {
          final asyncUser = ref.watch(userChangesProvider);
          return asyncUser.when(
            loading: () => _loadingScreen('Signing in...'),
            error: (err, stack) => _loadingScreen('Error signing in'),
            data: (user) {
              if (user == null) return const SignInScreen();

              // Can only verify email if not running firebase emulators
              if (!user.emailVerified && !useEmulators) {
                return const EmailVerifyScreen();
              }

              return const LibraryScreen();
            },
          );
        },
      ),
      builder: EasyLoading.init(),
    );
  }

  Widget _loadingScreen(String infoText) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: CircularProgressIndicator(),
          ),
          Text(
            infoText,
            style: theme.textTheme.subtitle1
                ?.copyWith(color: theme.colorScheme.onBackground),
          ),
        ],
      ),
    );
  }
}
