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
  /// **'Waha Operations'**
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
  /// **'Select Your Branch'**
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

  /// No description provided for @noInventoryAccessAt.
  ///
  /// In en, this message translates to:
  /// **'No inventory access at {branch}. Pick a different branch, or log out to switch accounts.'**
  String noInventoryAccessAt(String branch);

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @changeBranch.
  ///
  /// In en, this message translates to:
  /// **'Change Branch'**
  String get changeBranch;

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

  /// No description provided for @transferLabel.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transferLabel;

  /// No description provided for @returnLabel.
  ///
  /// In en, this message translates to:
  /// **'Return'**
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
  /// **'Quantity'**
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
  /// **'Add'**
  String get addButton;

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
