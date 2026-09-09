import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/generated/app_localizations.dart';
import 'router/routes.dart';
import 'screens/login_screen.dart';
import 'screens/store_select_screen.dart';
import 'screens/visit_home_screen.dart';
import 'services/api_client.dart';
import 'state/app_config_state.dart';
import 'state/auth_state.dart';
import 'state/locale_state.dart';
import 'state/visit_state.dart';

void main() {
  runApp(const WahaOpsApp());
}

class WahaOpsApp extends StatelessWidget {
  const WahaOpsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>(create: (_) => ApiClient()),
        ChangeNotifierProvider(create: (_) => AuthState()),
        ChangeNotifierProvider(create: (_) => VisitState()),
        ChangeNotifierProvider(create: (_) => LocaleState()..load()),
        // Fetched once at boot, before login — see AppConfigState's doc.
        ChangeNotifierProvider(create: (_) => AppConfigState()..load(ApiClient())),
      ],
      child: Consumer2<LocaleState, AppConfigState>(
        builder: (context, localeState, appConfig, _) => MaterialApp(
          onGenerateTitle: (context) =>
              appConfig.title(localeState.locale.languageCode) ??
              AppLocalizations.of(context)!.appTitle,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
            // Material 3's AppBar defaults to a pale surface color, not
            // colorScheme.primary. Set a sane default here so a new
            // screen's plain `AppBar()` doesn't wash out white icons/text
            // — this bug has bitten every screen in this app once already.
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),
          locale: localeState.locale,
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const _StartupGate(),
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case Routes.login:
                return MaterialPageRoute(builder: (_) => const LoginScreen());
              case Routes.storeSelect:
                return MaterialPageRoute(builder: (_) => const StoreSelectScreen());
              case Routes.visitHome:
                return MaterialPageRoute(builder: (_) => const VisitHomeScreen());
              default:
                return MaterialPageRoute(builder: (_) => const LoginScreen());
            }
          },
        ),
      ),
    );
  }
}

enum _StartupTarget { login, storeSelect }

// Tries a cached employee session before showing the login screen. Never
// re-selects a store or resumes a visit on its own — a reload always lands
// on StoreSelectScreen (or LoginScreen), branch pick stays manual every
// time (see AuthState.resolveStartupAuth).
class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  bool _resolved = false;
  _StartupTarget _target = _StartupTarget.login;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final auth = context.read<AuthState>();
    final api = context.read<ApiClient>();
    final loggedIn = await auth.resolveStartupAuth(api);
    // resolveStartupAuth always clears storeId (see its doc) — a reload
    // never has a store already selected, so this only ever chooses
    // between login and storeSelect.
    final target = loggedIn ? _StartupTarget.storeSelect : _StartupTarget.login;

    if (mounted) {
      setState(() {
        _resolved = true;
        _target = target;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_resolved) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    switch (_target) {
      case _StartupTarget.storeSelect:
        return const StoreSelectScreen();
      case _StartupTarget.login:
        return const LoginScreen();
    }
  }
}
