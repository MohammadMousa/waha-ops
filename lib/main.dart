import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'router/routes.dart';
import 'screens/login_screen.dart';
import 'screens/start_visit_screen.dart';
import 'screens/visit_screen.dart';
import 'services/api_client.dart';
import 'state/auth_state.dart';
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
      ],
      child: MaterialApp(
        title: 'Waha Ops',
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo)),
        home: const _StartupGate(),
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case Routes.login:
              return MaterialPageRoute(builder: (_) => const LoginScreen());
            case Routes.startVisit:
              return MaterialPageRoute(builder: (_) => const StartVisitScreen());
            case Routes.visit:
              return MaterialPageRoute(builder: (_) => const VisitScreen());
            default:
              return MaterialPageRoute(builder: (_) => const LoginScreen());
          }
        },
      ),
    );
  }
}

// Tries a cached employee session before showing the login screen.
class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  bool _resolved = false;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final auth = context.read<AuthState>();
    final api = context.read<ApiClient>();
    final visit = context.read<VisitState>();
    final ok = await auth.resolveStartupAuth(api);
    if (ok && auth.storeId != null) {
      await visit.loadDestinationBranches(api, auth.token!, auth.storeId!);
    }
    if (mounted) {
      setState(() {
        _resolved = true;
        _loggedIn = ok;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_resolved) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _loggedIn ? const StartVisitScreen() : const LoginScreen();
  }
}
