import '../l10n/generated/app_localizations.dart';

enum OperationType { transfer, ret }

extension OperationTypeApi on OperationType {
  String get apiValue => this == OperationType.transfer ? 'TRANSFER' : 'RETURN';

  // Return/Transfer are identical flows — only the label differs (per the
  // human lead: "return is just like transfer only titles changes").
  String label(AppLocalizations l10n) =>
      this == OperationType.transfer ? l10n.transferLabel : l10n.returnLabel;
}

class OperationItem {
  final int productId;
  final String productLabel;
  final int quantity;
  // Branch stock at the moment this item was staged — null if unknown (the
  // stock fetch failed). Carried along purely so the staged-items screen
  // can show a "Final" column without re-fetching; not sent to the backend.
  final int? branchStock;
  final int? imageResourceId; // same — thumbnail on the staged-items row

  const OperationItem({
    required this.productId,
    required this.productLabel,
    required this.quantity,
    this.branchStock,
    this.imageResourceId,
  });
}

// One TRANSFER or RETURN record added to the active visit. Per the human
// lead (2026-09-09, see ~/git/to_Backend_AI_On_Inventory_Task [11]/[12]):
// TRANSFER/RETURN are company↔branch, never branch↔branch — "company" is
// an untracked, conceptual stock source, not a second store row. There is
// no destination picker; `targetStoreId` is always the visit's own origin
// store (the only branch ever in play). Backend confirmed (see
// to_Frontend_AI_On_Inventory_Task [9]) its stock effect now applies
// entirely to `targetStoreId`, origin (`visit.store_id`) being purely
// administrative:
//   TRANSFER (company → branch) — targetStoreId (= origin) gains qty.
//   RETURN   (branch → company) — targetStoreId (= origin) loses qty.
class VisitOperation {
  final int? operationId; // set once the backend confirms the add
  final OperationType type;
  final int targetStoreId;
  final List<OperationItem> items;

  const VisitOperation({
    this.operationId,
    required this.type,
    required this.targetStoreId,
    required this.items,
  });

  VisitOperation withOperationId(int id) => VisitOperation(
        operationId: id,
        type: type,
        targetStoreId: targetStoreId,
        items: items,
      );

  Map<String, dynamic> toRequestJson() => {
        'operationType': type.apiValue,
        'targetStoreId': targetStoreId,
        'items': items
            .map((i) => {'productId': i.productId, 'quantity': i.quantity})
            .toList(),
      };
}
