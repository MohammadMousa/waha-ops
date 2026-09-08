// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Waha Operations';

  @override
  String get inventoryVisitsSubtitle => 'Inventory visits';

  @override
  String get usernameLabel => 'Username';

  @override
  String get pinLabel => 'PIN';

  @override
  String get loginButton => 'Log in';

  @override
  String get enterUsernameAndPin => 'Enter username and PIN';

  @override
  String get couldNotReachServer => 'Could not reach the server';

  @override
  String get selectYourBranch => 'Select Your Branch';

  @override
  String get noBranchAccessMessage => 'This account has no branch access.';

  @override
  String get backToLogin => 'Back to login';

  @override
  String get logOut => 'Log out';

  @override
  String noInventoryAccessAt(String branch) {
    return 'No inventory access at $branch. Pick a different branch, or log out to switch accounts.';
  }

  @override
  String get dismiss => 'Dismiss';

  @override
  String get changeBranch => 'Change Branch';

  @override
  String get endVisitFirstTitle => 'End visit first';

  @override
  String get endVisitFirstBody =>
      'You have an active visit. End it before switching branches.';

  @override
  String get cancel => 'Cancel';

  @override
  String get endVisitAndSwitch => 'End Visit & Switch';

  @override
  String get startingVisit => 'Starting visit…';

  @override
  String get transferLabel => 'Transfer';

  @override
  String get returnLabel => 'Return';

  @override
  String get cancelVisit => 'Cancel Visit';

  @override
  String get endVisit => 'End Visit';

  @override
  String get cancelVisitConfirmTitle => 'Cancel this visit?';

  @override
  String get cancelVisitConfirmBody => 'Anything added won\'t be saved.';

  @override
  String get keepVisit => 'Keep Visit';

  @override
  String get discardVisit => 'Discard';

  @override
  String get visitSavedTitle => 'Visit saved';

  @override
  String get visitSavedMessage => 'The activity has been recorded.';

  @override
  String get ok => 'OK';

  @override
  String get searchOrScanProduct => 'Search or scan a product';

  @override
  String get noMatches => 'No matches';

  @override
  String get inStockOnly => 'In stock only';

  @override
  String get branchStockLabel => 'Branch Stock';

  @override
  String get quantityLabel => 'Quantity';

  @override
  String get enterValidQuantity => 'Enter a valid quantity';

  @override
  String get selectAProduct => 'Select a product';

  @override
  String get addButton => 'Add';

  @override
  String saveItemsCount(int count) {
    return 'Save $count item(s)';
  }

  @override
  String itemsAddedCount(int count) {
    return '$count item(s) added';
  }

  @override
  String get scanBarcode => 'Scan Barcode';

  @override
  String get alignBarcode => 'Align the barcode within the frame';
}
