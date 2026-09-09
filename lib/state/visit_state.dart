import 'package:flutter/material.dart';

import '../models/visit_operation.dart';
import '../services/api_client.dart';

enum VisitStatus { none, active, completed }

// Holds the active visit and its operations. The visit's origin store is
// fixed by the employee's session (set at login) — this state never lets
// the employee change it. There is no destination/target-branch concept —
// every TRANSFER/RETURN is company↔branch (see VisitOperation's doc).
//
// reset() doubles as "cancel visit": per the human lead, cancelling is a
// pure local undo — never call completeVisit for it. Anything already
// POSTed to the backend as an operation stays there (the visit row is
// simply abandoned, ACTIVE-but-never-completed), but since store_inventory
// is only mutated inside /complete, an abandoned visit has zero effect on
// real stock. Don't try to "clean up" by deleting those operations or
// completing empty — just stop touching this visit and reset local state.
class VisitState extends ChangeNotifier {
  int? visitId;
  int? originStoreId;
  String? originStoreName;
  VisitStatus status = VisitStatus.none;
  final List<VisitOperation> operations = [];
  bool busy = false;
  String? error;

  Future<bool> startVisit(ApiClient api, String token, int storeId) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      final started = await api.startVisit(token, storeId);
      visitId = started.id;
      originStoreId = started.storeId;
      originStoreName = started.storeName;
      status = VisitStatus.active;
      operations.clear();
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> addOperation(
    ApiClient api,
    String token,
    OperationType type,
    List<OperationItem> items,
  ) async {
    if (visitId == null || originStoreId == null) return false;
    busy = true;
    error = null;
    notifyListeners();
    // No destination picker — every operation is company↔branch, so the
    // required targetStoreId is always this visit's own origin store. See
    // VisitOperation's doc comment for the backend contract this satisfies.
    final draft = VisitOperation(
      type: type,
      targetStoreId: originStoreId!,
      items: items,
    );
    try {
      final id = await api.addOperation(token: token, visitId: visitId!, operation: draft);
      operations.add(draft.withOperationId(id));
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> removeOperation(ApiClient api, String token, int index) async {
    final op = operations[index];
    if (op.operationId == null || visitId == null) return false;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await api.deleteOperation(token: token, visitId: visitId!, operationId: op.operationId!);
      operations.removeAt(index);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> completeVisit(ApiClient api, String token) async {
    if (visitId == null) return false;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await api.completeVisit(token: token, visitId: visitId!);
      status = VisitStatus.completed;
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void reset() {
    visitId = null;
    originStoreId = null;
    originStoreName = null;
    status = VisitStatus.none;
    operations.clear();
    error = null;
    notifyListeners();
  }
}
