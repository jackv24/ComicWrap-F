import 'package:comicwrap_f/pages/auth/email_verify_screen.dart';
import 'package:comicwrap_f/pages/auth/sign_in_screen.dart';
import 'package:comicwrap_f/pages/library/library_screen.dart';
import 'package:comicwrap_f/utils/auth.dart';
import 'package:comicwrap_f/utils/firebase.dart';
import 'package:comicwrap_f/utils/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Setup global style for loading blocker
    EasyLoading.instance
      ..userInteractions = false
      ..maskType = EasyLoadingMaskType.black;
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return Consumer(
          builder: (context, ref, child) {
            final themeMode = ref.watch(themeModeProvider);
            return MaterialApp(
              onGenerateTitle: (context) =>
                  AppLocalizations.of(context).appTitle,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                AppLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en'),
                Locale('fr'),
              ],
              theme: ThemeData(
                colorScheme: lightDynamic ?? const ColorScheme.light(),
                visualDensity: VisualDensity.adaptivePlatformDensity,
              ),
              darkTheme: ThemeData(
                colorScheme: darkDynamic ?? const ColorScheme.dark(),
                visualDensity: VisualDensity.adaptivePlatformDensity,
              ),
              themeMode: themeMode,
              // Firebase init
              home: child,
              builder: EasyLoading.init(),
            );
          },
          child: Consumer(
            builder: (context, ref, child) {
              final loc = AppLocalizations.of(context);
              final asyncUser = ref.watch(userChangesProvider);
              return asyncUser.when(
                loading: () => _loadingScreen(loc.signingIn),
                error: (err, stack) => _loadingScreen(loc.signInError),
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
        );
      },
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
