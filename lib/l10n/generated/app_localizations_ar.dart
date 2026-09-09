// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'واحة';

  @override
  String get inventoryVisitsSubtitle => 'زيارات المخزون';

  @override
  String get usernameLabel => 'اسم المستخدم';

  @override
  String get pinLabel => 'الرقم السري';

  @override
  String get loginButton => 'تسجيل الدخول';

  @override
  String get enterUsernameAndPin => 'أدخل اسم المستخدم والرقم السري';

  @override
  String get couldNotReachServer => 'تعذر الوصول إلى الخادم';

  @override
  String get selectYourBranch => 'اختر الفرع';

  @override
  String get noBranchAccessMessage =>
      'لا يملك هذا الحساب صلاحية الوصول لأي فرع.';

  @override
  String get backToLogin => 'العودة لتسجيل الدخول';

  @override
  String get logOut => 'تسجيل الخروج';

  @override
  String get noInventoryPermissionMessage =>
      'لا يملك هذا الحساب صلاحية الوصول للمخزون.';

  @override
  String get dismiss => 'إغلاق';

  @override
  String get languageMenuLabel => 'اللغة';

  @override
  String get changeBranch => 'تغيير الفرع';

  @override
  String get selectDestinationBranch => 'اختر فرع الوجهة';

  @override
  String get selectTransferSourceBranch => 'من أي فرع سيتم النقل؟';

  @override
  String get selectReturnTargetBranch => 'إلى أي فرع سيتم الإرجاع؟';

  @override
  String get endVisitFirstTitle => 'أنهِ الزيارة أولاً';

  @override
  String get endVisitFirstBody => 'لديك زيارة نشطة. أنهِها قبل تغيير الفرع.';

  @override
  String get cancel => 'إلغاء';

  @override
  String get endVisitAndSwitch => 'إنهاء الزيارة والتبديل';

  @override
  String get startingVisit => 'جاري بدء الزيارة…';

  @override
  String get startVisitButton => 'بدء الزيارة';

  @override
  String get transferLabel => 'نقل مخزون';

  @override
  String get returnLabel => 'ارجاع مخزون';

  @override
  String get cancelVisit => 'إلغاء الزيارة';

  @override
  String get endVisit => 'إنهاء الزيارة';

  @override
  String get cancelVisitConfirmTitle => 'إلغاء هذه الزيارة؟';

  @override
  String get cancelVisitConfirmBody => 'لن يتم حفظ ما تمت إضافته.';

  @override
  String get keepVisit => 'الاحتفاظ بالزيارة';

  @override
  String get discardVisit => 'تجاهل';

  @override
  String get visitSavedTitle => 'تم حفظ الزيارة';

  @override
  String get visitSavedMessage => 'تم تسجيل النشاط.';

  @override
  String get ok => 'حسنًا';

  @override
  String get searchOrScanProduct => 'ابحث أو امسح منتجًا';

  @override
  String get noMatches => 'لا توجد نتائج';

  @override
  String get inStockOnly => 'المتوفر فقط';

  @override
  String get branchStockLabel => 'مخزون الفرع';

  @override
  String get quantityLabel => 'أضف الكمية';

  @override
  String get enterValidQuantity => 'أدخل كمية صحيحة';

  @override
  String get selectAProduct => 'اختر منتجًا';

  @override
  String get addButton => 'حفظ';

  @override
  String get productTransferTitle => 'نقل المنتج';

  @override
  String get productReturnTitle => 'إرجاع المنتج';

  @override
  String get endingInventoryLabel => 'المخزون النهائي';

  @override
  String get unitsSuffix => 'وحدة';

  @override
  String saveItemsCount(int count) {
    return 'حفظ $count عنصر';
  }

  @override
  String itemsAddedCount(int count) {
    return 'تمت إضافة $count عنصر';
  }

  @override
  String get operationSavedTitle => 'تم حفظ العملية';

  @override
  String get operationSavedMessage => 'تم حفظ العملية بنجاح.';

  @override
  String get finishOperationFirstMessage =>
      'أنهِ أو احذف أصناف هذه العملية قبل إنهاء الزيارة.';

  @override
  String get scanBarcode => 'مسح الباركود';

  @override
  String get alignBarcode => 'ضع الباركود داخل الإطار';

  @override
  String get filterProductsTitle => 'تصفية المنتجات';

  @override
  String get productNameLabel => 'اسم المنتج';

  @override
  String get enterProductName => 'أدخل اسم المنتج...';

  @override
  String get barcodeLabel => 'الباركود';

  @override
  String get enterOrScanBarcode => 'أدخل أو امسح الباركود...';

  @override
  String get categoryLabel => 'الفئة';

  @override
  String get allCategoriesLabel => 'كل الفئات';

  @override
  String get descriptionKeywordLabel => 'كلمة مفتاحية في الوصف';

  @override
  String get applyFiltersButton => 'تطبيق الفلاتر';

  @override
  String get clearAllButton => 'مسح الكل';

  @override
  String get itemColumnLabel => 'الصنف';

  @override
  String get qtyColumnLabel => 'الكمية';

  @override
  String get finalColumnLabel => 'النهائي';

  @override
  String get saveChangesButton => 'حفظ';

  @override
  String get transferItemsTitle => 'أصناف النقل';

  @override
  String get returnItemsTitle => 'أصناف الإرجاع';
}
