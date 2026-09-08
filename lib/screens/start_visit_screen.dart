import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../router/routes.dart';
import '../services/api_client.dart';
import '../state/auth_state.dart';
import '../state/visit_state.dart';

// Landing screen after login. The origin store is already known from the
// session (no picker needed — roadmap section 2/4: never re-ask for
// company/branch once login has established it). "Start Visit" is the
// explicit action that opens a new ACTIVE visit (roadmap section 4/25).
class StartVisitScreen extends StatelessWidget {
  const StartVisitScreen({super.key});

  Future<void> _start(BuildContext context) async {
    final api = context.read<ApiClient>();
    final auth = context.read<AuthState>();
    final visit = context.read<VisitState>();
    final ok = await visit.startVisit(api, auth.token!);
    if (!context.mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacementNamed(Routes.visit);
    } else if (visit.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(visit.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final visit = context.watch<VisitState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Waha Operations')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.storefront, size: 48, color: Colors.indigo),
              const SizedBox(height: 16),
              const Text('Ready to start an inventory visit',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                visit.destinationBranches.isEmpty
                    ? 'No other branches available for transfer/return.'
                    : '${visit.destinationBranches.length} branch(es) available for Transfer/Return.',
                style: const TextStyle(color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: visit.busy ? null : () => _start(context),
                child: visit.busy
                    ? const SizedBox(
                        height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                        child: Text('Start Visit'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
