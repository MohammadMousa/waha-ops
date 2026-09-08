// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'عمليات واها';

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
  String get selectYourBranch => 'اختر فرعك';

  @override
  String get noBranchAccessMessage =>
      'لا يملك هذا الحساب صلاحية الوصول لأي فرع.';

  @override
  String get backToLogin => 'العودة لتسجيل الدخول';

  @override
  String get logOut => 'تسجيل الخروج';

  @override
  String noInventoryAccessAt(String branch) {
    return 'لا توجد صلاحية مخزون في $branch. اختر فرعًا آخر، أو سجّل الخروج لتبديل الحساب.';
  }

  @override
  String get dismiss => 'إغلاق';

  @override
  String get changeBranch => 'تغيير الفرع';

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
  String get transferLabel => 'تحويل';

  @override
  String get returnLabel => 'إرجاع';

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
  String get quantityLabel => 'الكمية';

  @override
  String get enterValidQuantity => 'أدخل كمية صحيحة';

  @override
  String get selectAProduct => 'اختر منتجًا';

  @override
  String get addButton => 'إضافة';

  @override
  String saveItemsCount(int count) {
    return 'حفظ $count عنصر';
  }

  @override
  String itemsAddedCount(int count) {
    return 'تمت إضافة $count عنصر';
  }

  @override
  String get scanBarcode => 'مسح الباركود';

  @override
  String get alignBarcode => 'ضع الباركود داخل الإطار';
}
