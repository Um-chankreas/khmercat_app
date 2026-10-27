// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Khmer Central Khmer (`km`).
class AppLocalizationsKm extends AppLocalizations {
  AppLocalizationsKm([String locale = 'km']) : super(locale);

  @override
  String get menuTitle => 'ម៉ឺនុយ';

  @override
  String get settingsTitle => 'ការកំណត់';

  @override
  String get accountAndPages => 'គណនី និងទំព័រ';

  @override
  String get createPage => 'បង្កើតទំព័រ';

  @override
  String get yourRestaurants => 'ភោជនីយដ្ឋានរបស់អ្នក';

  @override
  String get createRestaurant => 'បង្កើតភោជនីយដ្ឋាន';

  @override
  String get noRestaurantsYet => 'អ្នកមិនទាន់គ្រប់គ្រងទំព័រណាមួយទេ។';

  @override
  String get preferences => 'ចំណូលចិត្ត';

  @override
  String get language => 'ភាសា';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageKhmer => 'ខ្មែរ';

  @override
  String get appearance => 'រូបរាង';

  @override
  String get darkMode => 'របៀបងងឹត';

  @override
  String get themeSystem => 'តាមប្រព័ន្ធ';

  @override
  String get themeLight => 'ភ្លឺ';

  @override
  String get themeDark => 'ងងឹត';

  @override
  String get termsOfPolicy => 'លក្ខខណ្ឌគោលការណ៍';

  @override
  String get termsOfService => 'លក្ខខណ្ឌនៃការប្រើប្រាស់';

  @override
  String get termsOfPrivacy => 'គោលការណ៍ឯកជនភាព';

  @override
  String get logOut => 'ចាកចេញ';

  @override
  String get logOutConfirmTitle => 'ចាកចេញ?';

  @override
  String get logOutConfirmMessage => 'អ្នកអាចចូលឡើងវិញបានគ្រប់ពេល។';

  @override
  String get statFollowing => 'កំពុងតាមដាន';

  @override
  String get statFollowers => 'អ្នកតាមដាន';

  @override
  String get statPosts => 'ការបង្ហោះ';

  @override
  String get statLikes => 'ចូលចិត្ត';

  @override
  String get profileTabPosts => 'បង្ហោះ';

  @override
  String get profileTabSaved => 'រក្សាទុក';

  @override
  String get profileTabShared => 'បានចែករំលែក';

  @override
  String get profileTabLiked => 'បានចូលចិត្ត';

  @override
  String get profileTabFavorites => 'សំណព្វ';

  @override
  String get profileTabTrash => 'ធុងសំរាម';

  @override
  String get profileTabAbout => 'អំពី';

  @override
  String get emptyPosts => 'អ្នកមិនទាន់បានបង្ហោះវីដេអូណាមួយទេ។';

  @override
  String get emptySaved => 'វីដេអូដែលអ្នករក្សាទុកនឹងបង្ហាញនៅទីនេះ។';

  @override
  String get emptyShared => 'វីដេអូដែលអ្នកចែករំលែកនឹងបង្ហាញនៅទីនេះ។';

  @override
  String get emptyLiked => 'វីដេអូដែលអ្នកចូលចិត្តនឹងបង្ហាញនៅទីនេះ។';

  @override
  String get emptyFavorites => 'វីដេអូសំណព្វរបស់អ្នកនឹងបង្ហាញនៅទីនេះ។';

  @override
  String get emptyTrash => 'វីដេអូដែលបានលុបនឹងនៅទីនេះ ៣០ ថ្ងៃ។';

  @override
  String get aboutSectionTitle => 'ព័ត៌មានគណនី';

  @override
  String get aboutName => 'ឈ្មោះ';

  @override
  String get aboutUsername => 'ឈ្មោះអ្នកប្រើ';

  @override
  String get aboutEmail => 'អ៊ីមែល';

  @override
  String get aboutBio => 'ប្រវត្តិរូប';

  @override
  String get comingSoon => 'នឹងមកដល់ឆាប់ៗ';

  @override
  String get currentlyViewing => 'កំពុងប្រើជា';

  @override
  String youAreViewingAs(String name) {
    return 'អ្នកកំពុងប្រើកម្មវិធីជា $name';
  }

  @override
  String get switchTo => 'ប្ដូរទៅ';

  @override
  String get switchButton => 'ប្ដូរ';

  @override
  String get switchingProfile => 'កំពុងប្ដូរប្រវត្តិរូប…';

  @override
  String get profileTypePersonal => 'ផ្ទាល់ខ្លួន';

  @override
  String get profileTypeRestaurant => 'ភោជនីយដ្ឋាន';

  @override
  String get profileStatusActive => 'សកម្ម';

  @override
  String get profileStatusInactive => 'អសកម្ម';

  @override
  String switchedTo(String name) {
    return 'បានប្ដូរទៅ $name';
  }

  @override
  String get switchFailed => 'មិនអាចប្ដូរប្រវត្តិរូបបានទេ។ សូមព្យាយាមម្ដងទៀត។';

  @override
  String confirmSwitchTitle(String name) {
    return 'ប្ដូរទៅ $name';
  }

  @override
  String get confirmSwitchMessage =>
      'បញ្ចូលពាក្យសម្ងាត់របស់អ្នក ដើម្បីប្ដូរត្រឡប់ទៅគណនីផ្ទាល់ខ្លួនវិញ។';

  @override
  String get passwordHint => 'ពាក្យសម្ងាត់';

  @override
  String get continueAction => 'បន្ត';

  @override
  String get cancelAction => 'បោះបង់';

  @override
  String get switchAccount => 'ប្ដូរគណនី';

  @override
  String profilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ប្រវត្តិរូប',
    );
    return '$_temp0';
  }

  @override
  String get accountSection => 'គណនី';

  @override
  String get deactivateAccount => 'បិទគណនីបណ្ដោះអាសន្ន';

  @override
  String get deactivateAccountSubtitle => 'លាក់ប្រវត្តិរូបរបស់អ្នកមួយរយៈ';

  @override
  String get deleteAccount => 'លុបគណនី';

  @override
  String get deleteAccountSubtitle => 'លុបគណនីរបស់អ្នកជាអចិន្ត្រៃយ៍';

  @override
  String get deactivateAccountTitle => 'បិទគណនីរបស់អ្នកបណ្ដោះអាសន្ន?';

  @override
  String get deactivateAccountPoint1 =>
      'ប្រវត្តិរូប វីដេអូ និងមតិយោបល់របស់អ្នកនឹងត្រូវលាក់។';

  @override
  String get deactivateAccountPoint2 => 'អ្នកនឹងត្រូវចាកចេញពីគ្រប់ឧបករណ៍។';

  @override
  String get deactivateAccountPoint3 =>
      'ចូលម្ដងទៀតនៅពេលណាក៏បាន ដើម្បីបើកគណនីវិញ។';

  @override
  String get deactivateAction => 'បិទគណនី';

  @override
  String get deleteAccountTitle => 'លុបគណនីរបស់អ្នក?';

  @override
  String get deleteAccountPoint1 =>
      'ប្រវត្តិរូប វីដេអូ មតិយោបល់ និងការចូលចិត្តរបស់អ្នកនឹងត្រូវលុបជាអចិន្ត្រៃយ៍។';

  @override
  String get deleteAccountPoint2 =>
      'ភោជនីយដ្ឋានដែលអ្នកជាម្ចាស់ក៏នឹងត្រូវលុបដែរ។';

  @override
  String get deleteAccountPoint3 => 'សកម្មភាពនេះមិនអាចត្រឡប់វិញបានទេ។';

  @override
  String get deleteAccountAlternative =>
      'គ្រាន់តែចង់សម្រាកមួយរយៈ? បិទគណនីបណ្ដោះអាសន្នជំនួសវិញ។';

  @override
  String get deleteAction => 'លុប';

  @override
  String get confirmPasswordHint => 'បញ្ចូលពាក្យសម្ងាត់ដើម្បីបញ្ជាក់';

  @override
  String get accountDeactivated => 'គណនីរបស់អ្នកត្រូវបានបិទ។ ជួបគ្នាឆាប់ៗ!';

  @override
  String get accountDeleted => 'គណនីរបស់អ្នកត្រូវបានលុប។';

  @override
  String get accountReactivated =>
      'សូមស្វាគមន៍ការត្រឡប់មកវិញ! គណនីរបស់អ្នកដំណើរការវិញហើយ។';

  @override
  String get accountActionFailed => 'មានបញ្ហាកើតឡើង។ សូមព្យាយាមម្ដងទៀត។';

  @override
  String get navHome => 'ទំព័រដើម';

  @override
  String get navSearch => 'ស្វែងរក';

  @override
  String get navNotifications => 'ការជូនដំណឹង';

  @override
  String get navProfile => 'ប្រវត្តិរូប';

  @override
  String get yourAccount => 'គណនីរបស់អ្នក';

  @override
  String get seeAll => 'មើលទាំងអស់';

  @override
  String get showLess => 'បង្ហាញតិច';

  @override
  String get addressSection => 'អាសយដ្ឋាន';

  @override
  String get savedAddresses => 'អាសយដ្ឋានដែលបានរក្សាទុក';

  @override
  String reviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'មតិវាយតម្លៃ $count',
    );
    return '$_temp0';
  }

  @override
  String get restaurantHidden => 'លាក់';

  @override
  String savedCount(int count) {
    return 'បានរក្សាទុក $count';
  }

  @override
  String get addressesTitle => 'អាសយដ្ឋាន';

  @override
  String get addNewAddress => 'បន្ថែមអាសយដ្ឋានថ្មី';

  @override
  String get noData => 'គ្មានទិន្នន័យ';

  @override
  String get noAddressesMessage =>
      'អ្នកមិនទាន់បានរក្សាទុកអាសយដ្ឋានណាមួយទេ។\nចុច «បន្ថែមអាសយដ្ឋានថ្មី» ដើម្បីបន្ថែម។';

  @override
  String get somethingWentWrong => 'មានបញ្ហាកើតឡើង';

  @override
  String get addressesLoadFailed => 'មិនអាចផ្ទុកអាសយដ្ឋានរបស់អ្នកបានទេ។';

  @override
  String get tryAgain => 'ព្យាយាមម្តងទៀត';

  @override
  String get editAction => 'កែប្រែ';

  @override
  String get moreActions => 'ច្រើនទៀត';

  @override
  String get deleteAddressTitle => 'លុបអាសយដ្ឋាន?';

  @override
  String deleteAddressMessage(String label) {
    return '«$label» នឹងត្រូវដកចេញពីអាសយដ្ឋានរបស់អ្នក។';
  }

  @override
  String get addressDeleteFailed => 'មិនអាចលុបអាសយដ្ឋានបានទេ';

  @override
  String get addressSaveFailed =>
      'មិនអាចរក្សាទុកអាសយដ្ឋានបានទេ។ សូមព្យាយាមម្តងទៀត។';

  @override
  String get addressSearchHint => 'ស្វែងរកអាសយដ្ឋាន';

  @override
  String get addressPinHint => 'រំកិលផែនទីដើម្បីដាក់ម្ជុល';

  @override
  String get findingAddress => 'កំពុងស្វែងរកអាសយដ្ឋាន…';

  @override
  String get addressDetailHint => 'ផ្ទះលេខ អគារ ជាន់ (មិនចាំបាច់)';

  @override
  String get saveAddress => 'រក្សាទុកអាសយដ្ឋាន';

  @override
  String get saveChanges => 'រក្សាទុកការផ្លាស់ប្តូរ';

  @override
  String get addressSaved => 'បានរក្សាទុកអាសយដ្ឋាន';

  @override
  String get addressUpdated => 'បានកែប្រែអាសយដ្ឋាន';

  @override
  String get placeOpenFailed => 'មិនអាចបើកទីតាំងនោះបានទេ';

  @override
  String get addressLabelHome => 'ផ្ទះ';

  @override
  String get addressLabelOffice => 'ការិយាល័យ';

  @override
  String get addressLabelOther => 'ផ្សេងៗ';

  @override
  String get backAction => 'ត្រឡប់ក្រោយ';

  @override
  String get myLocation => 'ទីតាំងរបស់ខ្ញុំ';

  @override
  String get reviewersTitle => 'អ្នកវាយតម្លៃ';

  @override
  String get followAction => 'តាមដាន';

  @override
  String get followingAction => 'កំពុងតាមដាន';

  @override
  String get youLabel => 'អ្នក';

  @override
  String get noFollowersYet => 'មិនទាន់មានអ្នកតាមដាននៅឡើយ';

  @override
  String get notFollowingAnyoneYet => 'មិនទាន់តាមដាននរណាម្នាក់នៅឡើយ';

  @override
  String get noReviewersYet => 'មិនទាន់មានការវាយតម្លៃនៅឡើយ';

  @override
  String get peopleLoadFailed => 'មិនអាចផ្ទុកបញ្ជីនេះបានទេ។';

  @override
  String get signInToFollow => 'ចូលគណនីដើម្បីតាមដានអ្នកដទៃ';

  @override
  String get followFailed =>
      'មិនអាចធ្វើបច្ចុប្បន្នភាពការតាមដានបានទេ។ សូមព្យាយាមម្តងទៀត។';

  @override
  String get profileTabVideos => 'វីដេអូ';

  @override
  String get adminNavHome => 'ទំព័រដើម';

  @override
  String get adminNavRestaurants => 'ភោជនីយដ្ឋាន';

  @override
  String get adminNavReports => 'របាយការណ៍';

  @override
  String get adminNavSettings => 'ការកំណត់';

  @override
  String adminHi(String name) {
    return 'សួស្តី $name';
  }

  @override
  String get adminDashboardLoadFailed => 'មិនអាចផ្ទុកផ្ទាំងគ្រប់គ្រងបានទេ។';

  @override
  String get adminTileToApprove => 'ភោជនីយដ្ឋានរង់ចាំអនុម័ត';

  @override
  String get adminTileOpenReports => 'របាយការណ៍មិនទាន់ដោះស្រាយ';

  @override
  String get adminUsers => 'អ្នកប្រើប្រាស់';

  @override
  String adminTileUsersWeek(int count) {
    return 'អ្នកប្រើប្រាស់ · +$count សប្តាហ៍នេះ';
  }

  @override
  String get adminTileActiveRestaurants => 'ភោជនីយដ្ឋានសកម្ម';

  @override
  String get adminWaitingApproval => 'រង់ចាំការអនុម័ត';

  @override
  String adminSeeAll(int count) {
    return 'មើលទាំង $count';
  }

  @override
  String get adminNoRestaurantsWaiting => 'មិនមានភោជនីយដ្ឋានរង់ចាំទេ។';

  @override
  String get adminLatestReports => 'របាយការណ៍ចុងក្រោយ';

  @override
  String get adminNoOpenReports => 'មិនមានរបាយការណ៍ទេ។';

  @override
  String adminVideoBy(String username) {
    return 'វីដេអូដោយ @$username';
  }

  @override
  String adminReportsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count របាយការណ៍',
    );
    return '$_temp0';
  }

  @override
  String adminVideosCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count វីដេអូ',
    );
    return '$_temp0';
  }

  @override
  String get adminSomethingWrong => 'មានបញ្ហាអ្វីមួយ';

  @override
  String get adminReject => 'បដិសេធ';

  @override
  String adminRejectTitle(String name) {
    return 'បដិសេធ $name?';
  }

  @override
  String get adminReasonForOwner => 'មូលហេតុសម្រាប់ម្ចាស់ (ស្រេចចិត្ត)';

  @override
  String get adminRejected => 'បានបដិសេធ';

  @override
  String get adminApprove => 'អនុម័ត';

  @override
  String get adminApproved => 'បានអនុម័ត';

  @override
  String get adminDelete => 'លុប';

  @override
  String get adminTabPending => 'រង់ចាំ';

  @override
  String get adminTabActive => 'សកម្ម';

  @override
  String get adminTabDeactivated => 'បានបិទ';

  @override
  String adminDeactivateTitle(String name) {
    return 'បិទ $name?';
  }

  @override
  String get adminDeactivateHint =>
      'ហេតុអ្វី? ឧ. រូបភាពក្លែងក្លាយ របាយការណ៍ច្រើន';

  @override
  String get adminDeactivate => 'បិទ';

  @override
  String get adminActivate => 'បើកវិញ';

  @override
  String get adminActivatedAgain => 'បានបើកវិញ';

  @override
  String get adminRestaurantsLoadFailed => 'មិនអាចផ្ទុកភោជនីយដ្ឋានបានទេ។';

  @override
  String get adminNoPending => 'មិនមានភោជនីយដ្ឋានរង់ចាំការអនុម័តទេ។';

  @override
  String get adminNoActive => 'មិនមានភោជនីយដ្ឋានសកម្មទេ។';

  @override
  String get adminNoDeactivated => 'មិនមានភោជនីយដ្ឋានដែលបានបិទទេ។';

  @override
  String adminOwner(String name) {
    return 'ម្ចាស់ $name';
  }

  @override
  String adminDeactivatedOn(String date) {
    return 'បានបិទ $date';
  }

  @override
  String adminReasonValue(String reason) {
    return 'មូលហេតុ៖ $reason';
  }

  @override
  String get adminVideoTakenDown => 'វីដេអូនេះត្រូវបានដកចេញ។';

  @override
  String get adminDeleteVideoTitle => 'លុបវីដេអូនេះ?';

  @override
  String adminDeleteVideoMessage(String author) {
    return 'វានឹងត្រូវដកចេញសម្រាប់គ្រប់គ្នា ហើយរបាយការណ៍របស់វានឹងត្រូវបិទ។ $author នៅតែអាចមើលវាក្នុងផ្ទាំង «បានលុប» រយៈពេល ៣០ ថ្ងៃ។';
  }

  @override
  String get adminTheAuthor => 'អ្នកបង្ហោះ';

  @override
  String get adminVideoDeleted => 'បានលុបវីដេអូ';

  @override
  String get adminReportsLoadFailed => 'មិនអាចផ្ទុករបាយការណ៍បានទេ។';

  @override
  String get adminAllClear => 'មិនមានរបាយការណ៍ទេ។ ល្អណាស់!';

  @override
  String get adminNothingResolved => 'មិនទាន់មានអ្វីដោះស្រាយនៅឡើយ។';

  @override
  String get adminReportsDismissed => 'បានច្រានចោលរបាយការណ៍';

  @override
  String get adminTabOpen => 'មិនទាន់ដោះស្រាយ';

  @override
  String get adminTabResolved => 'បានដោះស្រាយ';

  @override
  String get adminTapToView => 'ចុចដើម្បីមើល';

  @override
  String get adminAuthorBanned => 'អ្នកបង្ហោះត្រូវបានហាមឃាត់';

  @override
  String get adminDismiss => 'ច្រានចោល';

  @override
  String get adminBan => 'ហាមឃាត់';

  @override
  String get adminByYou => 'ដោយអ្នក';

  @override
  String adminByName(String name) {
    return 'ដោយ $name';
  }

  @override
  String get adminUserBanned => 'បានហាមឃាត់អ្នកប្រើ';

  @override
  String get adminDeleted => 'បានលុប';

  @override
  String get adminDismissed => 'បានច្រានចោល';

  @override
  String adminBannedToast(String username) {
    return 'បានហាមឃាត់ @$username';
  }

  @override
  String adminBannedWithVideos(String username, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count វីដេអូ',
    );
    return 'បានហាមឃាត់ @$username · បានលុប $_temp0';
  }

  @override
  String get adminBanFailed => 'មិនអាចហាមឃាត់អ្នកប្រើនេះបានទេ។';

  @override
  String adminBanTitle(String name) {
    return 'ហាមឃាត់ $name?';
  }

  @override
  String get adminHowLong => 'រយៈពេល';

  @override
  String adminDays(int count) {
    return '$count ថ្ងៃ';
  }

  @override
  String get adminForever => 'ជារៀងរហូត';

  @override
  String get adminReason => 'មូលហេតុ';

  @override
  String get adminAlsoDeleteVideos => 'លុបវីដេអូដែលត្រូវបានរាយការណ៍ផងដែរ';

  @override
  String get adminAlsoDeleteVideosSub => 'វីដេអូរបស់គាត់ដែលមានរបាយការណ៍';

  @override
  String get adminBanNote =>
      'ពេលត្រូវហាមឃាត់ គាត់មិនអាចចូល បង្ហោះ ឬបញ្ចេញមតិបានទេ ហើយនឹងឃើញមូលហេតុពេលព្យាយាមចូល។';

  @override
  String get adminBanUser => 'ហាមឃាត់អ្នកប្រើ';

  @override
  String get adminBanReasonSexual => 'អាក្រាត ឬខ្លឹមសារផ្លូវភេទ';

  @override
  String get adminBanReasonSpam => 'សារឥតបានការ ឬការបោកប្រាស់';

  @override
  String get adminBanReasonHate => 'ការស្អប់ ឬការយាយី';

  @override
  String get adminBanReasonFake => 'គណនីក្លែងក្លាយ';

  @override
  String adminUnbanTitle(String username) {
    return 'ឈប់ហាមឃាត់ @$username?';
  }

  @override
  String get adminUnbanMessage => 'គាត់អាចចូល បង្ហោះ និងបញ្ចេញមតិម្តងទៀតបាន។';

  @override
  String get adminUnban => 'ឈប់ហាមឃាត់';

  @override
  String adminUnbannedToast(String username) {
    return 'បានឈប់ហាមឃាត់ @$username';
  }

  @override
  String get adminUnbanFailed => 'មិនអាចឈប់ហាមឃាត់បានទេ។';

  @override
  String get adminUsersLoadFailed => 'មិនអាចផ្ទុកអ្នកប្រើប្រាស់បានទេ។';

  @override
  String adminNoMatch(String query) {
    return 'រកមិនឃើញ «$query» ទេ។';
  }

  @override
  String get adminNoReported => 'មិនមាននរណាម្នាក់មានរបាយការណ៍ទេ។';

  @override
  String get adminNoBanned => 'មិនមាននរណាម្នាក់ត្រូវហាមឃាត់ទេ។';

  @override
  String get adminNoUsers => 'មិនទាន់មានអ្នកប្រើប្រាស់ទេ។';

  @override
  String get adminSearchUsers => 'ស្វែងរកឈ្មោះ @username ឬលេខទូរស័ព្ទ';

  @override
  String get adminFilterAll => 'ទាំងអស់';

  @override
  String get adminFilterReported => 'ត្រូវបានរាយការណ៍';

  @override
  String get adminFilterBanned => 'ត្រូវបានហាមឃាត់';

  @override
  String get adminBannedForGood => 'ហាមឃាត់ជារៀងរហូត';

  @override
  String adminBannedUntil(String date) {
    return 'ហាមឃាត់ដល់ $date';
  }

  @override
  String get adminRoleAdmin => 'អ្នកគ្រប់គ្រង';

  @override
  String get adminViewProfile => 'មើលប្រវត្តិរូប';

  @override
  String get adminPeople => 'មនុស្ស';

  @override
  String get adminUsersRowSub => 'ស្វែងរក មើលអ្នកត្រូវរាយការណ៍ និងត្រូវហាមឃាត់';

  @override
  String get adminActivity => 'សកម្មភាព';

  @override
  String get adminActivityLog => 'កំណត់ហេតុសកម្មភាពអ្នកគ្រប់គ្រង';

  @override
  String get adminActivityLogSub => 'រាល់ការអនុម័ត ហាមឃាត់ និងលុប';

  @override
  String get adminAccount => 'គណនី';

  @override
  String get adminBackToApp => 'ត្រឡប់ទៅ KhmerCat';

  @override
  String get adminBackToAppSub => 'ចាកចេញពីផ្នែកគ្រប់គ្រង';

  @override
  String get adminLogLoadFailed => 'មិនអាចផ្ទុកកំណត់ហេតុបានទេ។';

  @override
  String get adminNothingDone => 'មិនទាន់មានសកម្មភាពទេ។';

  @override
  String get adminActivityTitle => 'កំណត់ហេតុសកម្មភាព';

  @override
  String adminActApprove(String target) {
    return 'បានអនុម័ត $target';
  }

  @override
  String adminActReject(String target) {
    return 'បានបដិសេធ $target';
  }

  @override
  String adminActDeactivate(String target) {
    return 'បានបិទ $target';
  }

  @override
  String adminActActivate(String target) {
    return 'បានបើក $target វិញ';
  }

  @override
  String adminActRemoveVideo(String target) {
    return 'បានលុប $target';
  }

  @override
  String adminActDismiss(String target) {
    return 'បានច្រានចោលរបាយការណ៍លើ $target';
  }

  @override
  String adminActBan(String target) {
    return 'បានហាមឃាត់ $target';
  }

  @override
  String adminActUnban(String target) {
    return 'បានឈប់ហាមឃាត់ $target';
  }

  @override
  String get adminYou => 'អ្នក';

  @override
  String get adminAnAdmin => 'អ្នកគ្រប់គ្រងម្នាក់';

  @override
  String get adminNow => 'ឥឡូវនេះ';

  @override
  String adminMinutesAgo(int count) {
    return '$count នាទីមុន';
  }

  @override
  String adminHoursAgo(int count) {
    return '$count ម៉ោងមុន';
  }

  @override
  String get adminYesterday => 'ម្សិលមិញ';

  @override
  String adminDaysAgo(int count) {
    return '$count ថ្ងៃមុន';
  }

  @override
  String get adminReasonViolence => 'អំពើហិង្សា ឬការរំលោភ';

  @override
  String get adminReasonChildSafety => 'សុវត្ថិភាពកុមារ';

  @override
  String get adminReasonMisleading => 'ព័ត៌មានមិនពិត ឬបំភាន់';

  @override
  String get adminReasonAi => 'ខ្លឹមសារ AI មានបញ្ហា';

  @override
  String get adminReasonSelfHarm => 'ការធ្វើអត្តឃាត និងការធ្វើបាបខ្លួនឯង';

  @override
  String get adminReasonBranded => 'ខ្លឹមសារពាណិជ្ជកម្មមិនបានបញ្ជាក់';

  @override
  String get adminReasonCopyright => 'សិទ្ធិអ្នកនិពន្ធ ឬខ្លឹមសាររបស់អ្នកដទៃ';

  @override
  String get adminReasonInappropriate => 'មិនសមរម្យ';

  @override
  String get adminReasonOther => 'ផ្សេងៗ';

  @override
  String get adminShortNudity => 'អាក្រាត';

  @override
  String get adminShortHarassment => 'យាយី';

  @override
  String get adminShortViolence => 'ហិង្សា';

  @override
  String get adminShortChildSafety => 'សុវត្ថិភាពកុមារ';

  @override
  String get adminShortMisleading => 'បំភាន់';

  @override
  String get adminShortAi => 'ខ្លឹមសារ AI';

  @override
  String get adminShortSelfHarm => 'ធ្វើបាបខ្លួនឯង';

  @override
  String get adminShortBranded => 'ពាណិជ្ជកម្ម';

  @override
  String get adminShortSpam => 'សារឥតបានការ';

  @override
  String get adminShortCopyright => 'សិទ្ធិអ្នកនិពន្ធ';

  @override
  String get adminShortOther => 'ផ្សេងៗ';

  @override
  String get adminTabOff => 'បានបិទ';

  @override
  String get restaurantTabReviews => 'ការវាយតម្លៃ';

  @override
  String get restaurantTabInfo => 'ព័ត៌មាន';

  @override
  String get statReviews => 'ការវាយតម្លៃ';

  @override
  String get qrCodeTooltip => 'កូដ QR';

  @override
  String get restaurantUnavailable => 'មិនអាចបើកភោជនីយដ្ឋានបានទេ';

  @override
  String get notFound => 'រកមិនឃើញ';

  @override
  String get removePosterTitle => 'ដកផ្ទាំងរូបភាពថ្ងៃឈប់សម្រាកចេញ?';

  @override
  String get removePosterMessage =>
      'វានឹងត្រូវដកចេញពីប្រវត្តិរូប និងព័ត៌មានថ្មីៗ ហើយម៉ោងធ្វើការធម្មតារបស់អ្នកនឹងបង្ហាញឡើងវិញនៅថ្ងៃនោះ។';

  @override
  String get removeAction => 'ដកចេញ';

  @override
  String get removePosterFailed => 'មិនអាចដកផ្ទាំងរូបភាពចេញបានទេ។';

  @override
  String get restaurantNoPostsTitle => 'មិនទាន់មានការបង្ហោះនៅឡើយទេ';

  @override
  String get restaurantNoPostsOwner =>
      'ចុច + ដើម្បីបង្ហោះវីដេអូដំបូងក្នុងនាមភោជនីយដ្ឋាននេះ។';

  @override
  String get restaurantReviewsEmpty =>
      'វីដេអូពីភ្ញៀវដែលបានមកញ៉ាំនឹងបង្ហាញនៅទីនេះ។';

  @override
  String get holidayToday => 'ថ្ងៃនេះ';

  @override
  String get holidayNotice => 'ដំណឹងថ្ងៃឈប់សម្រាក';

  @override
  String get removePoster => 'ដកផ្ទាំងរូបភាពចេញ';

  @override
  String holidayClosedOn(String dates) {
    return 'បិទ · $dates';
  }

  @override
  String holidayOpenOn(String dates) {
    return 'បើក · $dates';
  }

  @override
  String holidayClosedToday(String title) {
    return 'បិទថ្ងៃនេះ · $title';
  }

  @override
  String holidayOpenHoursToday(String opens, String closes, String title) {
    return 'បើក $opens – $closes ថ្ងៃនេះ · $title';
  }

  @override
  String holidayOpenToday(String title) {
    return 'បើកថ្ងៃនេះ · $title';
  }

  @override
  String infoMenuPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ទំព័រ',
    );
    return '$_temp0 · កូដ QR';
  }

  @override
  String get infoCategory => 'ប្រភេទ';

  @override
  String get infoOpeningHours => 'ម៉ោងបើក';

  @override
  String get infoService => 'សេវាកម្ម';

  @override
  String get infoPhone => 'លេខទូរស័ព្ទ';

  @override
  String get infoAbout => 'អំពី';

  @override
  String get infoNoDetails => 'មិនទាន់មានព័ត៌មានលម្អិតនៅឡើយទេ។';

  @override
  String get infoDetails => 'ព័ត៌មានលម្អិត';

  @override
  String get infoFinishProfile => 'បំពេញប្រវត្តិរូបរបស់អ្នក';

  @override
  String infoDoneOfTotal(int done, int total) {
    return 'បានបំពេញ $done/$total';
  }

  @override
  String get infoCompleteHint =>
      'ប្រវត្តិរូបដែលបំពេញគ្រប់ នឹងត្រូវអនុម័តលឿនជាង ហើយបង្ហាញច្រើនជាងក្នុងការស្វែងរក។';

  @override
  String get openNow => 'កំពុងបើក';

  @override
  String get closedStatus => 'បិទ';

  @override
  String get serviceDineIn => 'ញ៉ាំនៅហាងតែប៉ុណ្ណោះ';

  @override
  String get serviceDelivery => 'ដឹកជញ្ជូនតែប៉ុណ្ណោះ';

  @override
  String get serviceDineInDelivery => 'ញ៉ាំនៅហាង និងដឹកជញ្ជូន';

  @override
  String get serviceTakeaway => 'ខ្ចប់យកទៅ';

  @override
  String get approvalNotApproved => 'មិនត្រូវបានអនុម័ត';

  @override
  String get approvalRejectedBody =>
      'អ្នកគ្រប់គ្រងមិនបានអនុម័តភោជនីយដ្ឋាននេះទេ ដូច្នេះអតិថិជនមិនអាចមើលឃើញវាបានទេ។';

  @override
  String approvalReason(String reason) {
    return 'មូលហេតុ៖ $reason';
  }

  @override
  String get approvalPendingBody =>
      'អតិថិជនមិនទាន់អាចមើលឃើញវានៅឡើយទេ។ វានឹងបង្ហាញជាសាធារណៈ បន្ទាប់ពីក្រុមការងារ Khmer Cat អនុម័ត។';

  @override
  String get unpublishedTitle => 'លាក់ពីអតិថិជន';

  @override
  String get unpublishedBody =>
      'មានតែក្រុមការងាររបស់អ្នកប៉ុណ្ណោះដែលអាចមើលឃើញភោជនីយដ្ឋាននេះ។';

  @override
  String get publishAction => 'ផ្សាយ';

  @override
  String get publishedAgain => 'ភោជនីយដ្ឋានបង្ហាញជាសាធារណៈវិញហើយ';

  @override
  String get publishFailed => 'មិនអាចផ្សាយបានទេ។';

  @override
  String get deleteVideoTitle => 'លុបវីដេអូ?';

  @override
  String get deleteVideoMessage =>
      'វានឹងត្រូវផ្លាស់ទីទៅ «បានលុប» រយៈពេល ៣០ ថ្ងៃ បន្ទាប់មកនឹងត្រូវលុបជាអចិន្ត្រៃយ៍។';

  @override
  String get videoDeleteFailed => 'មិនអាចលុបវីដេអូបានទេ។';

  @override
  String get addVideo => 'បន្ថែមវីដេអូ';

  @override
  String get videosLoadFailed => 'មិនអាចផ្ទុកវីដេអូបានទេ។';

  @override
  String get textMore => 'មើលបន្ថែម';

  @override
  String distanceAway(String distance) {
    return 'ចម្ងាយ $distance';
  }

  @override
  String get signInToFollowRestaurant => 'ចូលគណនីដើម្បីតាមដានភោជនីយដ្ឋាននេះ';

  @override
  String get signInToWriteReview => 'ចូលគណនីដើម្បីសរសេរការវាយតម្លៃ';

  @override
  String get viewMenu => 'មើលម៉ឺនុយ';

  @override
  String shareOnKhmerCat(String name) {
    return '$name នៅលើ Khmer Cat';
  }

  @override
  String shareMenuLine(String url) {
    return 'ម៉ឺនុយ៖ $url';
  }

  @override
  String get popularTag => 'ពេញនិយម';

  @override
  String get hoursNotAdded => 'មិនទាន់បានបន្ថែមម៉ោងបើកនៅឡើយទេ';

  @override
  String get hoursDaily => 'រាល់ថ្ងៃ';

  @override
  String get restaurantTabComments => 'មតិយោបល់';

  @override
  String get restaurantPostsEmpty =>
      'វីដេអូដែលភោជនីយដ្ឋាននេះបានបង្ហោះនឹងបង្ហាញនៅទីនេះ។';

  @override
  String likesPill(String formatted, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ចូលចិត្ត',
    );
    return '$formatted $_temp0';
  }

  @override
  String get addLink => '+ បន្ថែម';

  @override
  String get orderDelivery => 'កុម្ម៉ង់ដឹកជញ្ជូន';

  @override
  String get followUs => 'តាមដានយើង';

  @override
  String statPostLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ការបង្ហោះ',
    );
    return '$_temp0';
  }

  @override
  String statReviewLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ការវាយតម្លៃ',
    );
    return '$_temp0';
  }

  @override
  String statFollowerLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'អ្នកតាមដាន',
    );
    return '$_temp0';
  }

  @override
  String get reviewsEmptyTeam =>
      'ការវាយតម្លៃពីអតិថិជនរបស់អ្នកនឹងបង្ហាញនៅទីនេះ។';

  @override
  String get reviewsEmptyVisitor =>
      'ក្លាយជាអ្នកដំបូងដែលវាយតម្លៃភោជនីយដ្ឋាននេះ។';

  @override
  String get writeReview => 'សរសេរការវាយតម្លៃ';

  @override
  String get editYourReview => 'កែប្រែការវាយតម្លៃរបស់អ្នក';

  @override
  String filterAll(int count) {
    return 'ទាំងអស់ · $count';
  }

  @override
  String filterWithVideo(int count) {
    return 'មានវីដេអូ · $count';
  }

  @override
  String get noVideoReviewsYet => 'មិនទាន់មានការវាយតម្លៃជាវីដេអូនៅឡើយទេ។';

  @override
  String get signInToLikeReviews => 'ចូលគណនីដើម្បីចូលចិត្តការវាយតម្លៃ';

  @override
  String ratingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ការដាក់ពិន្ទុ',
    );
    return '$_temp0';
  }

  @override
  String get replyAction => 'ឆ្លើយតប';

  @override
  String get editReply => 'កែការឆ្លើយតប';

  @override
  String agoShortMinutes(int count) {
    return '$countនាទី';
  }

  @override
  String agoShortHours(int count) {
    return '$countម៉ោង';
  }

  @override
  String agoShortDays(int count) {
    return '$countថ្ងៃ';
  }

  @override
  String agoShortWeeks(int count) {
    return '$countសប្ដាហ៍';
  }

  @override
  String agoShortMonths(int count) {
    return '$countខែ';
  }

  @override
  String agoShortYears(int count) {
    return '$countឆ្នាំ';
  }

  @override
  String get videoUnavailable => 'វីដេអូនេះមិនអាចមើលបានទេ។';

  @override
  String replyFrom(String name) {
    return 'ការឆ្លើយតបពី $name';
  }

  @override
  String get reviewsLoadFailed => 'មិនអាចផ្ទុកការវាយតម្លៃបានទេ។';

  @override
  String replyTo(String name) {
    return 'ឆ្លើយតបទៅ $name';
  }

  @override
  String get replyHint => 'អរគុណពួកគេ ឬឆ្លើយសំណួររបស់ពួកគេ…';

  @override
  String get replyRemoved => 'បានដកការឆ្លើយតបចេញ។';

  @override
  String get replyPosted => 'បានបង្ហោះការឆ្លើយតប។';

  @override
  String get saveAction => 'រក្សាទុក';

  @override
  String get posterTitlePlaceholder => 'ចំណងជើងថ្ងៃឈប់សម្រាករបស់អ្នក';

  @override
  String get posterPosted => 'បានបង្ហោះផ្ទាំងរូបភាពថ្ងៃឈប់សម្រាក។';

  @override
  String posterPostedMany(int count) {
    return 'បានបង្ហោះផ្ទាំងរូបភាពថ្ងៃឈប់សម្រាកទៅភោជនីយដ្ឋានចំនួន $count។';
  }

  @override
  String get posterPostFailed => 'មិនអាចបង្ហោះផ្ទាំងរូបភាពបានទេ។';

  @override
  String get posterYourHoliday => 'ថ្ងៃឈប់សម្រាករបស់អ្នក';

  @override
  String get posterTitleLabel => 'ចំណងជើង';

  @override
  String get posterTitleHint => 'ឧ. រីករាយទិវាឯករាជ្យ';

  @override
  String get posterDescriptionLabel => 'ការពិពណ៌នា';

  @override
  String posterDescriptionHint(String date) {
    return 'ឧ. យើងបិទនៅ$date។ ជួបគ្នាថ្ងៃបន្ទាប់!';
  }

  @override
  String get posterApplyTo => 'អនុវត្តលើ';

  @override
  String chosenOfTotal(int chosen, int total) {
    return '$chosen/$total';
  }

  @override
  String get clearAction => 'សម្អាត';

  @override
  String get selectAll => 'ជ្រើសរើសទាំងអស់';

  @override
  String get posterActingAs =>
      'អ្នកកំពុងប្រើក្នុងនាមភោជនីយដ្ឋាននេះ ដូច្នេះផ្ទាំងរូបភាពនេះសម្រាប់តែភោជនីយដ្ឋាននេះប៉ុណ្ណោះ។';

  @override
  String get posterNoRestaurants =>
      'អ្នកមិនទាន់មាន ឬគ្រប់គ្រងភោជនីយដ្ឋាននៅឡើយទេ។';

  @override
  String get posterOpeningOnHoliday => 'ការបើកនៅថ្ងៃឈប់សម្រាក';

  @override
  String get posterStarts => 'ចាប់ផ្តើម';

  @override
  String get changeAction => 'ប្ដូរ';

  @override
  String posterUntil(String date) {
    return 'រហូតដល់ $date';
  }

  @override
  String get posterOpens => 'បើក';

  @override
  String get posterCloses => 'បិទ';

  @override
  String get modeSpecial => 'ម៉ោងពិសេស';

  @override
  String get modeOpen => 'បើក';

  @override
  String get newPosterTitle => 'ផ្ទាំងរូបភាពថ្មី';

  @override
  String get postAction => 'បង្ហោះ';

  @override
  String get addPhoto => 'បន្ថែមរូបភាព';

  @override
  String get posterSeePrefix => 'អតិថិជននឹងឃើញ ';

  @override
  String get posterSeeSuffix =>
      ' នៅលើប្រវត្តិរូបរបស់អ្នក និងក្នុងការស្វែងរកនៅថ្ងៃនោះ។';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ថ្ងៃ',
    );
    return '$_temp0';
  }

  @override
  String get createTitle => 'បង្កើត';

  @override
  String get postingAs => 'បង្ហោះក្នុងនាម ';

  @override
  String get createVideoTitle => 'វីដេអូ';

  @override
  String get createVideoSub => 'ថត ឬផ្ទុកឡើង';

  @override
  String get createPosterTitle => 'ផ្ទាំងរូបភាពថ្ងៃឈប់សម្រាក';

  @override
  String get createPosterSub => 'បិទ ឬម៉ោងពិសេស';

  @override
  String get loggingOut => 'កំពុងចាកចេញ…';

  @override
  String get loggedOut => 'បានចាកចេញ';

  @override
  String get logOutFailed => 'មិនអាចចាកចេញបានទេ។ សូមព្យាយាមម្តងទៀត។';

  @override
  String get approvalStepSubmitted => 'បានដាក់ស្នើ';

  @override
  String get approvalStepReviewing => 'កំពុងពិនិត្យ…';

  @override
  String get approvalStepReviewed => 'បានពិនិត្យ';

  @override
  String approvalWorkingTitle(String name) {
    return 'កំពុងរៀបចំ $name…';
  }

  @override
  String get approvalLiveTitle => 'ភោជនីយដ្ឋានរបស់អ្នករួចរាល់ហើយ!';
}
