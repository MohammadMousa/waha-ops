import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'router/routes.dart';
import 'screens/login_screen.dart';
import 'screens/start_visit_screen.dart';
import 'screens/store_select_screen.dart';
import 'screens/visit_screen.dart';
import 'services/api_client.dart';
import 'state/auth_state.dart';
import 'state/visit_state.dart';

const _kProcessInventoryPermission = 'PROCESS_INVENTORY';

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
            case Routes.storeSelect:
              return MaterialPageRoute(builder: (_) => const StoreSelectScreen());
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

enum _StartupTarget { login, storeSelect, startVisit }

// Tries a cached employee session (and, if a store was previously chosen
// and is still accessible, re-selects it automatically) before showing
// the login screen.
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
    final visit = context.read<VisitState>();
    final loggedIn = await auth.resolveStartupAuth(api);

    var target = _StartupTarget.login;
    if (loggedIn) {
      if (auth.hasSelectedStore) {
        if (!auth.hasPermission(_kProcessInventoryPermission)) {
          await auth.logout();
        } else {
          await visit.loadDestinationBranches(api, auth.token!, auth.storeId!);
          target = _StartupTarget.startVisit;
        }
      } else {
        target = _StartupTarget.storeSelect;
      }
    }

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
      case _StartupTarget.startVisit:
        return const StartVisitScreen();
      case _StartupTarget.storeSelect:
        return const StoreSelectScreen();
      case _StartupTarget.login:
        return const LoginScreen();
    }
  }
}
