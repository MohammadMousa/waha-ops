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

  const OperationItem({
    required this.productId,
    required this.productLabel,
    required this.quantity,
  });
}

// One TRANSFER or RETURN record added to the active visit. Per the backend
// contract, targetStoreId is required for both types:
//   TRANSFER — origin store loses qty, targetStoreId gains qty.
//   RETURN   — targetStoreId loses qty, origin store gains qty.
class VisitOperation {
  final int? operationId; // set once the backend confirms the add
  final OperationType type;
  final int targetStoreId;
  final String targetStoreLabel;
  final List<OperationItem> items;

  const VisitOperation({
    this.operationId,
    required this.type,
    required this.targetStoreId,
    required this.targetStoreLabel,
    required this.items,
  });

  VisitOperation withOperationId(int id) => VisitOperation(
        operationId: id,
        type: type,
        targetStoreId: targetStoreId,
        targetStoreLabel: targetStoreLabel,
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
