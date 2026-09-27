import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Waha'**
  String get appTitle;

  /// No description provided for @inventoryVisitsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory visits'**
  String get inventoryVisitsSubtitle;

  /// No description provided for @usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// No description provided for @pinLabel.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get pinLabel;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get loginButton;

  /// No description provided for @enterUsernameAndPin.
  ///
  /// In en, this message translates to:
  /// **'Enter username and PIN'**
  String get enterUsernameAndPin;

  /// No description provided for @couldNotReachServer.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server'**
  String get couldNotReachServer;

  /// No description provided for @selectYourBranch.
  ///
  /// In en, this message translates to:
  /// **'Pick A Branch'**
  String get selectYourBranch;

  /// No description provided for @noBranchAccessMessage.
  ///
  /// In en, this message translates to:
  /// **'This account has no branch access.'**
  String get noBranchAccessMessage;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get backToLogin;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @noInventoryPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'This account doesn\'t have inventory access.'**
  String get noInventoryPermissionMessage;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @languageMenuLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageMenuLabel;

  /// No description provided for @aboutMenuLabel.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutMenuLabel;

  /// No description provided for @aboutVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutVersionLabel;

  /// No description provided for @aboutBuildLabel.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get aboutBuildLabel;

  /// No description provided for @aboutBuiltLabel.
  ///
  /// In en, this message translates to:
  /// **'Built'**
  String get aboutBuiltLabel;

  /// No description provided for @aboutServerLabel.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get aboutServerLabel;

  /// No description provided for @closeButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// No description provided for @changeBranch.
  ///
  /// In en, this message translates to:
  /// **'Change Branch'**
  String get changeBranch;

  /// No description provided for @selectDestinationBranch.
  ///
  /// In en, this message translates to:
  /// **'Select destination branch'**
  String get selectDestinationBranch;

  /// No description provided for @selectTransferSourceBranch.
  ///
  /// In en, this message translates to:
  /// **'Which branch is sending this?'**
  String get selectTransferSourceBranch;

  /// No description provided for @selectReturnTargetBranch.
  ///
  /// In en, this message translates to:
  /// **'Which branch are you returning this to?'**
  String get selectReturnTargetBranch;

  /// No description provided for @endVisitFirstTitle.
  ///
  /// In en, this message translates to:
  /// **'End visit first'**
  String get endVisitFirstTitle;

  /// No description provided for @endVisitFirstBody.
  ///
  /// In en, this message translates to:
  /// **'You have an active visit. End it before switching branches.'**
  String get endVisitFirstBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @endVisitAndSwitch.
  ///
  /// In en, this message translates to:
  /// **'End Visit & Switch'**
  String get endVisitAndSwitch;

  /// No description provided for @startingVisit.
  ///
  /// In en, this message translates to:
  /// **'Starting visit…'**
  String get startingVisit;

  /// No description provided for @startVisitButton.
  ///
  /// In en, this message translates to:
  /// **'Start Visit'**
  String get startVisitButton;

  /// No description provided for @transferLabel.
  ///
  /// In en, this message translates to:
  /// **'Transfer Stock'**
  String get transferLabel;

  /// No description provided for @returnLabel.
  ///
  /// In en, this message translates to:
  /// **'Return Stock'**
  String get returnLabel;

  /// No description provided for @cancelVisit.
  ///
  /// In en, this message translates to:
  /// **'Cancel Visit'**
  String get cancelVisit;

  /// No description provided for @endVisit.
  ///
  /// In en, this message translates to:
  /// **'End Visit'**
  String get endVisit;

  /// No description provided for @cancelVisitConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this visit?'**
  String get cancelVisitConfirmTitle;

  /// No description provided for @cancelVisitConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Anything added won\'t be saved.'**
  String get cancelVisitConfirmBody;

  /// No description provided for @keepVisit.
  ///
  /// In en, this message translates to:
  /// **'Keep Visit'**
  String get keepVisit;

  /// No description provided for @discardVisit.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardVisit;

  /// No description provided for @visitSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Visit saved'**
  String get visitSavedTitle;

  /// No description provided for @visitSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'The activity has been recorded.'**
  String get visitSavedMessage;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @searchOrScanProduct.
  ///
  /// In en, this message translates to:
  /// **'Search or scan a product'**
  String get searchOrScanProduct;

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get noMatches;

  /// No description provided for @inStockOnly.
  ///
  /// In en, this message translates to:
  /// **'In stock only'**
  String get inStockOnly;

  /// No description provided for @branchStockLabel.
  ///
  /// In en, this message translates to:
  /// **'Branch Stock'**
  String get branchStockLabel;

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Add Quantity'**
  String get quantityLabel;

  /// No description provided for @enterValidQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid quantity'**
  String get enterValidQuantity;

  /// No description provided for @selectAProduct.
  ///
  /// In en, this message translates to:
  /// **'Select a product'**
  String get selectAProduct;

  /// No description provided for @addButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get addButton;

  /// No description provided for @productTransferTitle.
  ///
  /// In en, this message translates to:
  /// **'Product Transfer'**
  String get productTransferTitle;

  /// No description provided for @productReturnTitle.
  ///
  /// In en, this message translates to:
  /// **'Product Return'**
  String get productReturnTitle;

  /// No description provided for @endingInventoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Ending Inventory'**
  String get endingInventoryLabel;

  /// No description provided for @unitsSuffix.
  ///
  /// In en, this message translates to:
  /// **'units'**
  String get unitsSuffix;

  /// No description provided for @saveItemsCount.
  ///
  /// In en, this message translates to:
  /// **'Save {count} item(s)'**
  String saveItemsCount(int count);

  /// No description provided for @itemsAddedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} item(s) added'**
  String itemsAddedCount(int count);

  /// No description provided for @operationSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Operation saved'**
  String get operationSavedTitle;

  /// No description provided for @operationSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Operation is saved successfully.'**
  String get operationSavedMessage;

  /// No description provided for @finishOperationFirstMessage.
  ///
  /// In en, this message translates to:
  /// **'Finish or discard this operation\'s items before ending the visit.'**
  String get finishOperationFirstMessage;

  /// No description provided for @scanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan Barcode'**
  String get scanBarcode;

  /// No description provided for @alignBarcode.
  ///
  /// In en, this message translates to:
  /// **'Align the barcode within the frame'**
  String get alignBarcode;

  /// No description provided for @filterProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter Products'**
  String get filterProductsTitle;

  /// No description provided for @productNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productNameLabel;

  /// No description provided for @enterProductName.
  ///
  /// In en, this message translates to:
  /// **'Enter product name…'**
  String get enterProductName;

  /// No description provided for @barcodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcodeLabel;

  /// No description provided for @enterOrScanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Enter or scan barcode…'**
  String get enterOrScanBarcode;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @allCategoriesLabel.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategoriesLabel;

  /// No description provided for @descriptionKeywordLabel.
  ///
  /// In en, this message translates to:
  /// **'Description Keyword'**
  String get descriptionKeywordLabel;

  /// No description provided for @applyFiltersButton.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFiltersButton;

  /// No description provided for @clearAllButton.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAllButton;

  /// No description provided for @itemColumnLabel.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get itemColumnLabel;

  /// No description provided for @qtyColumnLabel.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get qtyColumnLabel;

  /// No description provided for @finalColumnLabel.
  ///
  /// In en, this message translates to:
  /// **'Final'**
  String get finalColumnLabel;

  /// No description provided for @saveChangesButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveChangesButton;

  /// No description provided for @transferItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer Items'**
  String get transferItemsTitle;

  /// No description provided for @returnItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Return Items'**
  String get returnItemsTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
