import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_km.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('en'),
    Locale('km'),
  ];

  /// No description provided for @menuTitle.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menuTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @accountAndPages.
  ///
  /// In en, this message translates to:
  /// **'Account & Pages'**
  String get accountAndPages;

  /// No description provided for @createPage.
  ///
  /// In en, this message translates to:
  /// **'Create Page'**
  String get createPage;

  /// No description provided for @yourRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Your restaurants'**
  String get yourRestaurants;

  /// No description provided for @createRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Create a restaurant'**
  String get createRestaurant;

  /// No description provided for @noRestaurantsYet.
  ///
  /// In en, this message translates to:
  /// **'You don\'t manage any pages yet.'**
  String get noRestaurantsYet;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageKhmer.
  ///
  /// In en, this message translates to:
  /// **'ខ្មែរ'**
  String get languageKhmer;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @termsOfPolicy.
  ///
  /// In en, this message translates to:
  /// **'Terms of Policy'**
  String get termsOfPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @termsOfPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Terms of Privacy'**
  String get termsOfPrivacy;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @logOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logOutConfirmTitle;

  /// No description provided for @logOutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'You can always sign back in.'**
  String get logOutConfirmMessage;

  /// No description provided for @statFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get statFollowing;

  /// No description provided for @statFollowers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get statFollowers;

  /// No description provided for @statPosts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get statPosts;

  /// No description provided for @statLikes.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get statLikes;

  /// No description provided for @profileTabPosts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get profileTabPosts;

  /// No description provided for @profileTabSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get profileTabSaved;

  /// No description provided for @profileTabShared.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get profileTabShared;

  /// No description provided for @profileTabLiked.
  ///
  /// In en, this message translates to:
  /// **'Liked'**
  String get profileTabLiked;

  /// No description provided for @profileTabFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get profileTabFavorites;

  /// No description provided for @profileTabTrash.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get profileTabTrash;

  /// No description provided for @profileTabAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profileTabAbout;

  /// No description provided for @emptyPosts.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t posted any videos yet.'**
  String get emptyPosts;

  /// No description provided for @emptySaved.
  ///
  /// In en, this message translates to:
  /// **'Videos you save show up here.'**
  String get emptySaved;

  /// No description provided for @emptyShared.
  ///
  /// In en, this message translates to:
  /// **'Videos you share show up here.'**
  String get emptyShared;

  /// No description provided for @emptyLiked.
  ///
  /// In en, this message translates to:
  /// **'Videos you like show up here.'**
  String get emptyLiked;

  /// No description provided for @emptyFavorites.
  ///
  /// In en, this message translates to:
  /// **'Your favorite videos show up here.'**
  String get emptyFavorites;

  /// No description provided for @emptyTrash.
  ///
  /// In en, this message translates to:
  /// **'Deleted videos stay here for 30 days.'**
  String get emptyTrash;

  /// No description provided for @aboutSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Info'**
  String get aboutSectionTitle;

  /// No description provided for @aboutName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get aboutName;

  /// No description provided for @aboutUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get aboutUsername;

  /// No description provided for @aboutEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get aboutEmail;

  /// No description provided for @aboutBio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get aboutBio;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @currentlyViewing.
  ///
  /// In en, this message translates to:
  /// **'Currently viewing'**
  String get currentlyViewing;

  /// No description provided for @youAreViewingAs.
  ///
  /// In en, this message translates to:
  /// **'You are using the app as {name}'**
  String youAreViewingAs(String name);

  /// No description provided for @switchTo.
  ///
  /// In en, this message translates to:
  /// **'Switch to'**
  String get switchTo;

  /// No description provided for @profileTypePersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get profileTypePersonal;

  /// No description provided for @profileTypeRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get profileTypeRestaurant;

  /// No description provided for @profileStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get profileStatusActive;

  /// No description provided for @profileStatusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get profileStatusInactive;

  /// No description provided for @switchedTo.
  ///
  /// In en, this message translates to:
  /// **'Switched to {name}'**
  String switchedTo(String name);

  /// No description provided for @switchFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not switch profile. Please try again.'**
  String get switchFailed;

  /// No description provided for @confirmSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch to {name}'**
  String confirmSwitchTitle(String name);

  /// No description provided for @confirmSwitchMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to switch back to your personal account.'**
  String get confirmSwitchMessage;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordHint;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// No description provided for @switchAccount.
  ///
  /// In en, this message translates to:
  /// **'Switch account'**
  String get switchAccount;

  /// No description provided for @profilesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 profile} other{{count} profiles}}'**
  String profilesCount(int count);

  /// No description provided for @accountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSection;

  /// No description provided for @deactivateAccount.
  ///
  /// In en, this message translates to:
  /// **'Deactivate account'**
  String get deactivateAccount;

  /// No description provided for @deactivateAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hide your profile for a while'**
  String get deactivateAccountSubtitle;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove your account'**
  String get deleteAccountSubtitle;

  /// No description provided for @deactivateAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate your account?'**
  String get deactivateAccountTitle;

  /// No description provided for @deactivateAccountPoint1.
  ///
  /// In en, this message translates to:
  /// **'Your profile, videos and comments are hidden.'**
  String get deactivateAccountPoint1;

  /// No description provided for @deactivateAccountPoint2.
  ///
  /// In en, this message translates to:
  /// **'You\'re signed out on every device.'**
  String get deactivateAccountPoint2;

  /// No description provided for @deactivateAccountPoint3.
  ///
  /// In en, this message translates to:
  /// **'Log in again anytime to reactivate.'**
  String get deactivateAccountPoint3;

  /// No description provided for @deactivateAction.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivateAction;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountPoint1.
  ///
  /// In en, this message translates to:
  /// **'Your profile, videos, comments and likes are removed for good.'**
  String get deleteAccountPoint1;

  /// No description provided for @deleteAccountPoint2.
  ///
  /// In en, this message translates to:
  /// **'Restaurants you own are deleted too.'**
  String get deleteAccountPoint2;

  /// No description provided for @deleteAccountPoint3.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be undone.'**
  String get deleteAccountPoint3;

  /// No description provided for @deleteAccountAlternative.
  ///
  /// In en, this message translates to:
  /// **'Just need a break? Deactivate instead.'**
  String get deleteAccountAlternative;

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to confirm'**
  String get confirmPasswordHint;

  /// No description provided for @accountDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Your account is deactivated. See you soon!'**
  String get accountDeactivated;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted.'**
  String get accountDeleted;

  /// No description provided for @accountReactivated.
  ///
  /// In en, this message translates to:
  /// **'Welcome back! Your account is active again.'**
  String get accountReactivated;

  /// No description provided for @accountActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get accountActionFailed;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get navNotifications;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;
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
      <String>['en', 'km'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'km':
      return AppLocalizationsKm();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
