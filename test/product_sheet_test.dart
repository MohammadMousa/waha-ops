import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:waha_ops/l10n/generated/app_localizations.dart';
import 'package:waha_ops/models/product_lite.dart';
import 'package:waha_ops/models/visit_operation.dart';
import 'package:waha_ops/state/locale_state.dart';
import 'package:waha_ops/widgets/product_quantity_sheet.dart';

const _a = ProductLite(id: 1, barcode: '111', name: {'en': 'Alpha'});
const _b = ProductLite(id: 2, barcode: '222', name: {'en': 'Beta'});

Future<ProductSheetController> _open(
  WidgetTester tester, {
  required int? initialQuantity,
  void Function(ProductSheetResult?)? onResult,
}) async {
  final controller = ProductSheetController();
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => LocaleState(),
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                final r = await showProductQuantitySheet(
                  context,
                  product: _a,
                  branchStock: 5,
                  type: OperationType.transfer,
                  initialQuantity: initialQuantity,
                  controller: controller,
                );
                onResult?.call(r);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  testWidgets('a product not in the list yet counts as unsaved work', (tester) async {
    final c = await _open(tester, initialQuantity: null);
    expect(c.isOpen, isTrue);
    expect(c.isDirty, isTrue);
  });

  testWidgets('an untouched saved product is clean until the quantity changes', (tester) async {
    final c = await _open(tester, initialQuantity: 3);
    expect(c.isDirty, isFalse);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(c.isDirty, isTrue);
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    expect(c.isDirty, isFalse);
  });

  testWidgets('swapping shows the new product and its saved quantity, still clean', (tester) async {
    final c = await _open(tester, initialQuantity: 3);
    c.swapProduct(_b, 9, 4);
    await tester.pump();
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('Alpha'), findsNothing);
    expect(c.productId, 2);
    expect(c.isDirty, isFalse);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('swapping to a product not in the list is unsaved work', (tester) async {
    final c = await _open(tester, initialQuantity: 3);
    c.swapProduct(_b, 9, null);
    await tester.pump();
    expect(c.isDirty, isTrue);
  });

  testWidgets('showError shows the message in the sheet and the flash fades', (tester) async {
    final c = await _open(tester, initialQuantity: 3);
    c.showError('nope');
    await tester.pump();
    expect(find.text('nope'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('Add returns the product currently shown, even after a swap', (tester) async {
    ProductSheetResult? result;
    final c = await _open(tester, initialQuantity: 3, onResult: (r) => result = r);
    c.swapProduct(_b, 9, 4);
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(result?.product.id, 2);
    expect(result?.quantity, 4);
    expect(c.isOpen, isFalse);
  });
}
