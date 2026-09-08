import 'package:flutter/material.dart';

import '../models/branch.dart';
import '../models/visit_operation.dart';
import '../services/api_client.dart';

enum VisitStatus { none, active, completed }

// Holds the destination-branch picker, the active visit, and its operations.
// The visit's origin store is fixed by the employee's session (set at
// login) — this state never lets the employee change it. "Branch" in the
// header refers to the destination/target branch for the operation being
// composed (roadmap section 24/33), which can change freely mid-visit
// without resetting the visit or its already-added operations.
class VisitState extends ChangeNotifier {
  List<Branch> destinationBranches = [];
  Branch? targetBranch;

  int? visitId;
  int? originStoreId;
  String? originStoreName;
  VisitStatus status = VisitStatus.none;
  OperationType operationType = OperationType.transfer;
  final List<VisitOperation> operations = [];
  bool busy = false;
  String? error;

  Future<bool> loadDestinationBranches(ApiClient api, String token, int excludeStoreId) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      final all = await api.getBranches(token);
      destinationBranches = all.where((b) => b.id != excludeStoreId).toList();
      targetBranch = destinationBranches.isNotEmpty ? destinationBranches.first : null;
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> startVisit(ApiClient api, String token) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      final started = await api.startVisit(token);
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

  void setOperationType(OperationType type) {
    operationType = type;
    notifyListeners();
  }

  void setTargetBranch(Branch branch) {
    targetBranch = branch;
    notifyListeners();
  }

  Future<bool> addOperation(
    ApiClient api,
    String token,
    OperationType type,
    List<OperationItem> items,
  ) async {
    if (visitId == null || targetBranch == null) return false;
    busy = true;
    error = null;
    notifyListeners();
    final draft = VisitOperation(
      type: type,
      targetStoreId: targetBranch!.id,
      targetStoreLabel: targetBranch!.label,
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
    operationType = OperationType.transfer;
    operations.clear();
    error = null;
    notifyListeners();
  }
}
