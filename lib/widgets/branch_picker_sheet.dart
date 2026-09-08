import 'package:flutter/material.dart';

import '../models/branch.dart';

// Shown when Transfer/Return is tapped and more than one destination
// branch is available. Skipped entirely when there's exactly one — see
// VisitHomeScreen._openOperation.
Future<Branch?> showBranchPickerSheet(BuildContext context, List<Branch> branches) {
  return showModalBottomSheet<Branch>(
    context: context,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: branches
            .map((b) => ListTile(
                  leading: const Icon(Icons.storefront),
                  title: Text(b.label),
                  onTap: () => Navigator.of(context).pop(b),
                ))
            .toList(),
      ),
    ),
  );
}
