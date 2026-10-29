// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Waha';

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
  String get selectYourBranch => 'Pick A Branch';

  @override
  String get noBranchAccessMessage => 'This account has no branch access.';

  @override
  String get backToLogin => 'Back to login';

  @override
  String get logOut => 'Log out';

  @override
  String get sessionEndedMessage =>
      'Your session has ended. Please sign in again.';

  @override
  String get activeSessionsTitle => 'Active sessions';

  @override
  String get thisDevice => 'This device';

  @override
  String get signOutOtherDevices => 'Sign out other devices';

  @override
  String get signOutOthersConfirmBody =>
      'All your other devices will be signed out.';

  @override
  String get signOutDevice => 'Sign out';

  @override
  String get noOtherSessions => 'No other devices are signed in.';

  @override
  String get lastActive => 'Last active';

  @override
  String get unknownDevice => 'Unknown device';

  @override
  String get signedOutOthersMessage => 'Other devices signed out.';

  @override
  String get retry => 'Retry';

  @override
  String get noInventoryPermissionMessage =>
      'This account doesn\'t have inventory access.';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get languageMenuLabel => 'Language';

  @override
  String get aboutMenuLabel => 'About';

  @override
  String get aboutVersionLabel => 'Version';

  @override
  String get aboutBuildLabel => 'Build';

  @override
  String get aboutBuiltLabel => 'Built';

  @override
  String get aboutServerLabel => 'Server';

  @override
  String get closeButton => 'Close';

  @override
  String get changeBranch => 'Change Branch';

  @override
  String get selectDestinationBranch => 'Select destination branch';

  @override
  String get selectTransferSourceBranch => 'Which branch is sending this?';

  @override
  String get selectReturnTargetBranch =>
      'Which branch are you returning this to?';

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
  String get startVisitButton => 'Start Visit';

  @override
  String get transferLabel => 'Transfer Stock';

  @override
  String get returnLabel => 'Return Stock';

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
  String get quantityLabel => 'Add Quantity';

  @override
  String get enterValidQuantity => 'Enter a valid quantity';

  @override
  String get selectAProduct => 'Select a product';

  @override
  String get addButton => 'Save';

  @override
  String get productTransferTitle => 'Product Transfer';

  @override
  String get productReturnTitle => 'Product Return';

  @override
  String get endingInventoryLabel => 'Ending Inventory';

  @override
  String get unitsSuffix => 'units';

  @override
  String saveItemsCount(int count) {
    return 'Save $count item(s)';
  }

  @override
  String itemsAddedCount(int count) {
    return '$count item(s) added';
  }

  @override
  String get operationSavedTitle => 'Operation saved';

  @override
  String get operationSavedMessage => 'Operation is saved successfully.';

  @override
  String get finishOperationFirstMessage =>
      'Finish or discard this operation\'s items before ending the visit.';

  @override
  String get scanBarcode => 'Scan Barcode';

  @override
  String get alignBarcode => 'Align the barcode within the frame';

  @override
  String get filterProductsTitle => 'Filter Products';

  @override
  String get productNameLabel => 'Product Name';

  @override
  String get enterProductName => 'Enter product name…';

  @override
  String get barcodeLabel => 'Barcode';

  @override
  String get enterOrScanBarcode => 'Enter or scan barcode…';

  @override
  String get categoryLabel => 'Category';

  @override
  String get allCategoriesLabel => 'All Categories';

  @override
  String get descriptionKeywordLabel => 'Description Keyword';

  @override
  String get applyFiltersButton => 'Apply Filters';

  @override
  String get clearAllButton => 'Clear All';

  @override
  String get itemColumnLabel => 'Item';

  @override
  String get qtyColumnLabel => 'Qty';

  @override
  String get finalColumnLabel => 'Final';

  @override
  String get saveChangesButton => 'Save';

  @override
  String get transferItemsTitle => 'Transfer Items';

  @override
  String get returnItemsTitle => 'Return Items';
}
