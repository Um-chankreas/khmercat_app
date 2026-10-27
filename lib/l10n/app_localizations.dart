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

  /// No description provided for @switchButton.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get switchButton;

  /// No description provided for @switchingProfile.
  ///
  /// In en, this message translates to:
  /// **'Switching profile…'**
  String get switchingProfile;

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

  /// No description provided for @yourAccount.
  ///
  /// In en, this message translates to:
  /// **'Your account'**
  String get yourAccount;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// No description provided for @addressSection.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressSection;

  /// No description provided for @savedAddresses.
  ///
  /// In en, this message translates to:
  /// **'Saved addresses'**
  String get savedAddresses;

  /// No description provided for @reviewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 review} other{{count} reviews}}'**
  String reviewsCount(int count);

  /// No description provided for @restaurantHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get restaurantHidden;

  /// No description provided for @savedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} saved'**
  String savedCount(int count);

  /// No description provided for @addressesTitle.
  ///
  /// In en, this message translates to:
  /// **'Addresses'**
  String get addressesTitle;

  /// No description provided for @addNewAddress.
  ///
  /// In en, this message translates to:
  /// **'Add new address'**
  String get addNewAddress;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @noAddressesMessage.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t saved any addresses yet.\nTap \"Add new address\" to add one.'**
  String get noAddressesMessage;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @addressesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your addresses.'**
  String get addressesLoadFailed;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @editAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editAction;

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreActions;

  /// No description provided for @deleteAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete address?'**
  String get deleteAddressTitle;

  /// No description provided for @deleteAddressMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{label}\" will be removed from your addresses.'**
  String deleteAddressMessage(String label);

  /// No description provided for @addressDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the address'**
  String get addressDeleteFailed;

  /// No description provided for @addressSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the address. Please try again.'**
  String get addressSaveFailed;

  /// No description provided for @addressSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for an address'**
  String get addressSearchHint;

  /// No description provided for @addressPinHint.
  ///
  /// In en, this message translates to:
  /// **'Move the map to place the pin'**
  String get addressPinHint;

  /// No description provided for @findingAddress.
  ///
  /// In en, this message translates to:
  /// **'Finding address…'**
  String get findingAddress;

  /// No description provided for @addressDetailHint.
  ///
  /// In en, this message translates to:
  /// **'House no., building, floor (optional)'**
  String get addressDetailHint;

  /// No description provided for @saveAddress.
  ///
  /// In en, this message translates to:
  /// **'Save address'**
  String get saveAddress;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @addressSaved.
  ///
  /// In en, this message translates to:
  /// **'Address saved'**
  String get addressSaved;

  /// No description provided for @addressUpdated.
  ///
  /// In en, this message translates to:
  /// **'Address updated'**
  String get addressUpdated;

  /// No description provided for @placeOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open that place'**
  String get placeOpenFailed;

  /// No description provided for @addressLabelHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get addressLabelHome;

  /// No description provided for @addressLabelOffice.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get addressLabelOffice;

  /// No description provided for @addressLabelOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get addressLabelOther;

  /// No description provided for @backAction.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backAction;

  /// No description provided for @myLocation.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get myLocation;

  /// No description provided for @reviewersTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviewers'**
  String get reviewersTitle;

  /// No description provided for @followAction.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get followAction;

  /// No description provided for @followingAction.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get followingAction;

  /// No description provided for @youLabel.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youLabel;

  /// No description provided for @noFollowersYet.
  ///
  /// In en, this message translates to:
  /// **'No followers yet'**
  String get noFollowersYet;

  /// No description provided for @notFollowingAnyoneYet.
  ///
  /// In en, this message translates to:
  /// **'Not following anyone yet'**
  String get notFollowingAnyoneYet;

  /// No description provided for @noReviewersYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviewersYet;

  /// No description provided for @peopleLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this list.'**
  String get peopleLoadFailed;

  /// No description provided for @signInToFollow.
  ///
  /// In en, this message translates to:
  /// **'Sign in to follow people'**
  String get signInToFollow;

  /// No description provided for @followFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update follow. Please try again.'**
  String get followFailed;

  /// No description provided for @profileTabVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get profileTabVideos;

  /// No description provided for @adminNavHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get adminNavHome;

  /// No description provided for @adminNavRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Restaurants'**
  String get adminNavRestaurants;

  /// No description provided for @adminNavReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get adminNavReports;

  /// No description provided for @adminNavSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get adminNavSettings;

  /// No description provided for @adminHi.
  ///
  /// In en, this message translates to:
  /// **'Hi {name}'**
  String adminHi(String name);

  /// No description provided for @adminDashboardLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the dashboard.'**
  String get adminDashboardLoadFailed;

  /// No description provided for @adminTileToApprove.
  ///
  /// In en, this message translates to:
  /// **'Restaurants to approve'**
  String get adminTileToApprove;

  /// No description provided for @adminTileOpenReports.
  ///
  /// In en, this message translates to:
  /// **'Open reports'**
  String get adminTileOpenReports;

  /// No description provided for @adminUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get adminUsers;

  /// No description provided for @adminTileUsersWeek.
  ///
  /// In en, this message translates to:
  /// **'Users · +{count} this week'**
  String adminTileUsersWeek(int count);

  /// No description provided for @adminTileActiveRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Active restaurants'**
  String get adminTileActiveRestaurants;

  /// No description provided for @adminWaitingApproval.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval'**
  String get adminWaitingApproval;

  /// No description provided for @adminSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all {count}'**
  String adminSeeAll(int count);

  /// No description provided for @adminNoRestaurantsWaiting.
  ///
  /// In en, this message translates to:
  /// **'No restaurants waiting.'**
  String get adminNoRestaurantsWaiting;

  /// No description provided for @adminLatestReports.
  ///
  /// In en, this message translates to:
  /// **'Latest reports'**
  String get adminLatestReports;

  /// No description provided for @adminNoOpenReports.
  ///
  /// In en, this message translates to:
  /// **'No open reports.'**
  String get adminNoOpenReports;

  /// No description provided for @adminVideoBy.
  ///
  /// In en, this message translates to:
  /// **'Video by @{username}'**
  String adminVideoBy(String username);

  /// No description provided for @adminReportsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 report} other{{count} reports}}'**
  String adminReportsCount(int count);

  /// No description provided for @adminVideosCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 video} other{{count} videos}}'**
  String adminVideosCount(int count);

  /// No description provided for @adminSomethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get adminSomethingWrong;

  /// No description provided for @adminReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get adminReject;

  /// No description provided for @adminRejectTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject {name}?'**
  String adminRejectTitle(String name);

  /// No description provided for @adminReasonForOwner.
  ///
  /// In en, this message translates to:
  /// **'Reason for the owner (optional)'**
  String get adminReasonForOwner;

  /// No description provided for @adminRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get adminRejected;

  /// No description provided for @adminApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get adminApprove;

  /// No description provided for @adminApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get adminApproved;

  /// No description provided for @adminDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get adminDelete;

  /// No description provided for @adminTabPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get adminTabPending;

  /// No description provided for @adminTabActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get adminTabActive;

  /// No description provided for @adminTabDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Deactivated'**
  String get adminTabDeactivated;

  /// No description provided for @adminDeactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate {name}?'**
  String adminDeactivateTitle(String name);

  /// No description provided for @adminDeactivateHint.
  ///
  /// In en, this message translates to:
  /// **'Why? e.g. fake photos, many reports'**
  String get adminDeactivateHint;

  /// No description provided for @adminDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get adminDeactivate;

  /// No description provided for @adminActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get adminActivate;

  /// No description provided for @adminActivatedAgain.
  ///
  /// In en, this message translates to:
  /// **'Activated again'**
  String get adminActivatedAgain;

  /// No description provided for @adminRestaurantsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load restaurants.'**
  String get adminRestaurantsLoadFailed;

  /// No description provided for @adminNoPending.
  ///
  /// In en, this message translates to:
  /// **'No restaurants waiting for approval.'**
  String get adminNoPending;

  /// No description provided for @adminNoActive.
  ///
  /// In en, this message translates to:
  /// **'No active restaurants.'**
  String get adminNoActive;

  /// No description provided for @adminNoDeactivated.
  ///
  /// In en, this message translates to:
  /// **'No deactivated restaurants.'**
  String get adminNoDeactivated;

  /// No description provided for @adminOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner {name}'**
  String adminOwner(String name);

  /// No description provided for @adminDeactivatedOn.
  ///
  /// In en, this message translates to:
  /// **'Deactivated {date}'**
  String adminDeactivatedOn(String date);

  /// No description provided for @adminReasonValue.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String adminReasonValue(String reason);

  /// No description provided for @adminVideoTakenDown.
  ///
  /// In en, this message translates to:
  /// **'This video was taken down.'**
  String get adminVideoTakenDown;

  /// No description provided for @adminDeleteVideoTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this video?'**
  String get adminDeleteVideoTitle;

  /// No description provided for @adminDeleteVideoMessage.
  ///
  /// In en, this message translates to:
  /// **'It\'s taken down for everyone and its reports are closed. {author} can still see it in their Deleted tab for 30 days.'**
  String adminDeleteVideoMessage(String author);

  /// No description provided for @adminTheAuthor.
  ///
  /// In en, this message translates to:
  /// **'The author'**
  String get adminTheAuthor;

  /// No description provided for @adminVideoDeleted.
  ///
  /// In en, this message translates to:
  /// **'Video deleted'**
  String get adminVideoDeleted;

  /// No description provided for @adminReportsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load reports.'**
  String get adminReportsLoadFailed;

  /// No description provided for @adminAllClear.
  ///
  /// In en, this message translates to:
  /// **'No open reports. All clear!'**
  String get adminAllClear;

  /// No description provided for @adminNothingResolved.
  ///
  /// In en, this message translates to:
  /// **'Nothing resolved yet.'**
  String get adminNothingResolved;

  /// No description provided for @adminReportsDismissed.
  ///
  /// In en, this message translates to:
  /// **'Reports dismissed'**
  String get adminReportsDismissed;

  /// No description provided for @adminTabOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get adminTabOpen;

  /// No description provided for @adminTabResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get adminTabResolved;

  /// No description provided for @adminTapToView.
  ///
  /// In en, this message translates to:
  /// **'Tap to view'**
  String get adminTapToView;

  /// No description provided for @adminAuthorBanned.
  ///
  /// In en, this message translates to:
  /// **'Author banned'**
  String get adminAuthorBanned;

  /// No description provided for @adminDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get adminDismiss;

  /// No description provided for @adminBan.
  ///
  /// In en, this message translates to:
  /// **'Ban'**
  String get adminBan;

  /// No description provided for @adminByYou.
  ///
  /// In en, this message translates to:
  /// **'by you'**
  String get adminByYou;

  /// No description provided for @adminByName.
  ///
  /// In en, this message translates to:
  /// **'by {name}'**
  String adminByName(String name);

  /// No description provided for @adminUserBanned.
  ///
  /// In en, this message translates to:
  /// **'User banned'**
  String get adminUserBanned;

  /// No description provided for @adminDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get adminDeleted;

  /// No description provided for @adminDismissed.
  ///
  /// In en, this message translates to:
  /// **'Dismissed'**
  String get adminDismissed;

  /// No description provided for @adminBannedToast.
  ///
  /// In en, this message translates to:
  /// **'@{username} banned'**
  String adminBannedToast(String username);

  /// No description provided for @adminBannedWithVideos.
  ///
  /// In en, this message translates to:
  /// **'@{username} banned · {count, plural, =1{1 video} other{{count} videos}} deleted'**
  String adminBannedWithVideos(String username, int count);

  /// No description provided for @adminBanFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t ban this user.'**
  String get adminBanFailed;

  /// No description provided for @adminBanTitle.
  ///
  /// In en, this message translates to:
  /// **'Ban {name}?'**
  String adminBanTitle(String name);

  /// No description provided for @adminHowLong.
  ///
  /// In en, this message translates to:
  /// **'How long'**
  String get adminHowLong;

  /// No description provided for @adminDays.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String adminDays(int count);

  /// No description provided for @adminForever.
  ///
  /// In en, this message translates to:
  /// **'Forever'**
  String get adminForever;

  /// No description provided for @adminReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get adminReason;

  /// No description provided for @adminAlsoDeleteVideos.
  ///
  /// In en, this message translates to:
  /// **'Also delete reported videos'**
  String get adminAlsoDeleteVideos;

  /// No description provided for @adminAlsoDeleteVideosSub.
  ///
  /// In en, this message translates to:
  /// **'Their videos with open reports'**
  String get adminAlsoDeleteVideosSub;

  /// No description provided for @adminBanNote.
  ///
  /// In en, this message translates to:
  /// **'They can\'t log in, post or comment while banned, and are told why when they try to log in.'**
  String get adminBanNote;

  /// No description provided for @adminBanUser.
  ///
  /// In en, this message translates to:
  /// **'Ban user'**
  String get adminBanUser;

  /// No description provided for @adminBanReasonSexual.
  ///
  /// In en, this message translates to:
  /// **'Nudity or sexual content'**
  String get adminBanReasonSexual;

  /// No description provided for @adminBanReasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam or scam'**
  String get adminBanReasonSpam;

  /// No description provided for @adminBanReasonHate.
  ///
  /// In en, this message translates to:
  /// **'Hate or harassment'**
  String get adminBanReasonHate;

  /// No description provided for @adminBanReasonFake.
  ///
  /// In en, this message translates to:
  /// **'Fake account'**
  String get adminBanReasonFake;

  /// No description provided for @adminUnbanTitle.
  ///
  /// In en, this message translates to:
  /// **'Unban @{username}?'**
  String adminUnbanTitle(String username);

  /// No description provided for @adminUnbanMessage.
  ///
  /// In en, this message translates to:
  /// **'They can log in, post and comment again.'**
  String get adminUnbanMessage;

  /// No description provided for @adminUnban.
  ///
  /// In en, this message translates to:
  /// **'Unban'**
  String get adminUnban;

  /// No description provided for @adminUnbannedToast.
  ///
  /// In en, this message translates to:
  /// **'@{username} unbanned'**
  String adminUnbannedToast(String username);

  /// No description provided for @adminUnbanFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t unban.'**
  String get adminUnbanFailed;

  /// No description provided for @adminUsersLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load users.'**
  String get adminUsersLoadFailed;

  /// No description provided for @adminNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No one matches \"{query}\".'**
  String adminNoMatch(String query);

  /// No description provided for @adminNoReported.
  ///
  /// In en, this message translates to:
  /// **'No one has open reports.'**
  String get adminNoReported;

  /// No description provided for @adminNoBanned.
  ///
  /// In en, this message translates to:
  /// **'No one is banned.'**
  String get adminNoBanned;

  /// No description provided for @adminNoUsers.
  ///
  /// In en, this message translates to:
  /// **'No users yet.'**
  String get adminNoUsers;

  /// No description provided for @adminSearchUsers.
  ///
  /// In en, this message translates to:
  /// **'Search name, @username or phone'**
  String get adminSearchUsers;

  /// No description provided for @adminFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get adminFilterAll;

  /// No description provided for @adminFilterReported.
  ///
  /// In en, this message translates to:
  /// **'Reported'**
  String get adminFilterReported;

  /// No description provided for @adminFilterBanned.
  ///
  /// In en, this message translates to:
  /// **'Banned'**
  String get adminFilterBanned;

  /// No description provided for @adminBannedForGood.
  ///
  /// In en, this message translates to:
  /// **'Banned for good'**
  String get adminBannedForGood;

  /// No description provided for @adminBannedUntil.
  ///
  /// In en, this message translates to:
  /// **'Banned until {date}'**
  String adminBannedUntil(String date);

  /// No description provided for @adminRoleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminRoleAdmin;

  /// No description provided for @adminViewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get adminViewProfile;

  /// No description provided for @adminPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get adminPeople;

  /// No description provided for @adminUsersRowSub.
  ///
  /// In en, this message translates to:
  /// **'Search, see reported and banned, ban or unban'**
  String get adminUsersRowSub;

  /// No description provided for @adminActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get adminActivity;

  /// No description provided for @adminActivityLog.
  ///
  /// In en, this message translates to:
  /// **'Admin activity log'**
  String get adminActivityLog;

  /// No description provided for @adminActivityLogSub.
  ///
  /// In en, this message translates to:
  /// **'Every approve, ban and delete'**
  String get adminActivityLogSub;

  /// No description provided for @adminAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get adminAccount;

  /// No description provided for @adminBackToApp.
  ///
  /// In en, this message translates to:
  /// **'Back to KhmerCat'**
  String get adminBackToApp;

  /// No description provided for @adminBackToAppSub.
  ///
  /// In en, this message translates to:
  /// **'Leave the admin area'**
  String get adminBackToAppSub;

  /// No description provided for @adminLogLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the log.'**
  String get adminLogLoadFailed;

  /// No description provided for @adminNothingDone.
  ///
  /// In en, this message translates to:
  /// **'Nothing done yet.'**
  String get adminNothingDone;

  /// No description provided for @adminActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity log'**
  String get adminActivityTitle;

  /// No description provided for @adminActApprove.
  ///
  /// In en, this message translates to:
  /// **'Approved {target}'**
  String adminActApprove(String target);

  /// No description provided for @adminActReject.
  ///
  /// In en, this message translates to:
  /// **'Rejected {target}'**
  String adminActReject(String target);

  /// No description provided for @adminActDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivated {target}'**
  String adminActDeactivate(String target);

  /// No description provided for @adminActActivate.
  ///
  /// In en, this message translates to:
  /// **'Activated {target}'**
  String adminActActivate(String target);

  /// No description provided for @adminActRemoveVideo.
  ///
  /// In en, this message translates to:
  /// **'Deleted {target}'**
  String adminActRemoveVideo(String target);

  /// No description provided for @adminActDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismissed reports on {target}'**
  String adminActDismiss(String target);

  /// No description provided for @adminActBan.
  ///
  /// In en, this message translates to:
  /// **'Banned {target}'**
  String adminActBan(String target);

  /// No description provided for @adminActUnban.
  ///
  /// In en, this message translates to:
  /// **'Unbanned {target}'**
  String adminActUnban(String target);

  /// No description provided for @adminYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get adminYou;

  /// No description provided for @adminAnAdmin.
  ///
  /// In en, this message translates to:
  /// **'An admin'**
  String get adminAnAdmin;

  /// No description provided for @adminNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get adminNow;

  /// No description provided for @adminMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String adminMinutesAgo(int count);

  /// No description provided for @adminHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String adminHoursAgo(int count);

  /// No description provided for @adminYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get adminYesterday;

  /// No description provided for @adminDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String adminDaysAgo(int count);

  /// No description provided for @adminReasonViolence.
  ///
  /// In en, this message translates to:
  /// **'Violence or abuse'**
  String get adminReasonViolence;

  /// No description provided for @adminReasonChildSafety.
  ///
  /// In en, this message translates to:
  /// **'Child safety'**
  String get adminReasonChildSafety;

  /// No description provided for @adminReasonMisleading.
  ///
  /// In en, this message translates to:
  /// **'False or misleading information'**
  String get adminReasonMisleading;

  /// No description provided for @adminReasonAi.
  ///
  /// In en, this message translates to:
  /// **'Problematic AI content'**
  String get adminReasonAi;

  /// No description provided for @adminReasonSelfHarm.
  ///
  /// In en, this message translates to:
  /// **'Suicide and self-harm'**
  String get adminReasonSelfHarm;

  /// No description provided for @adminReasonBranded.
  ///
  /// In en, this message translates to:
  /// **'Undisclosed branded content'**
  String get adminReasonBranded;

  /// No description provided for @adminReasonCopyright.
  ///
  /// In en, this message translates to:
  /// **'Copyright or someone else\'s content'**
  String get adminReasonCopyright;

  /// No description provided for @adminReasonInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate'**
  String get adminReasonInappropriate;

  /// No description provided for @adminReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get adminReasonOther;

  /// No description provided for @adminShortNudity.
  ///
  /// In en, this message translates to:
  /// **'Nudity'**
  String get adminShortNudity;

  /// No description provided for @adminShortHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment'**
  String get adminShortHarassment;

  /// No description provided for @adminShortViolence.
  ///
  /// In en, this message translates to:
  /// **'Violence'**
  String get adminShortViolence;

  /// No description provided for @adminShortChildSafety.
  ///
  /// In en, this message translates to:
  /// **'Child safety'**
  String get adminShortChildSafety;

  /// No description provided for @adminShortMisleading.
  ///
  /// In en, this message translates to:
  /// **'Misleading'**
  String get adminShortMisleading;

  /// No description provided for @adminShortAi.
  ///
  /// In en, this message translates to:
  /// **'AI content'**
  String get adminShortAi;

  /// No description provided for @adminShortSelfHarm.
  ///
  /// In en, this message translates to:
  /// **'Self-harm'**
  String get adminShortSelfHarm;

  /// No description provided for @adminShortBranded.
  ///
  /// In en, this message translates to:
  /// **'Branded'**
  String get adminShortBranded;

  /// No description provided for @adminShortSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get adminShortSpam;

  /// No description provided for @adminShortCopyright.
  ///
  /// In en, this message translates to:
  /// **'Copyright'**
  String get adminShortCopyright;

  /// No description provided for @adminShortOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get adminShortOther;

  /// No description provided for @adminTabOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get adminTabOff;

  /// No description provided for @restaurantTabReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get restaurantTabReviews;

  /// No description provided for @restaurantTabInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get restaurantTabInfo;

  /// No description provided for @statReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get statReviews;

  /// No description provided for @qrCodeTooltip.
  ///
  /// In en, this message translates to:
  /// **'QR code'**
  String get qrCodeTooltip;

  /// No description provided for @restaurantUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Restaurant unavailable'**
  String get restaurantUnavailable;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get notFound;

  /// No description provided for @removePosterTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove holiday poster?'**
  String get removePosterTitle;

  /// No description provided for @removePosterMessage.
  ///
  /// In en, this message translates to:
  /// **'It comes off your profile and the feed, and your usual hours show again that day.'**
  String get removePosterMessage;

  /// No description provided for @removeAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeAction;

  /// No description provided for @removePosterFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not remove the poster.'**
  String get removePosterFailed;

  /// No description provided for @restaurantNoPostsTitle.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get restaurantNoPostsTitle;

  /// No description provided for @restaurantNoPostsOwner.
  ///
  /// In en, this message translates to:
  /// **'Tap + to post your first video as this restaurant.'**
  String get restaurantNoPostsOwner;

  /// No description provided for @restaurantReviewsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Videos from diners who visited show up here.'**
  String get restaurantReviewsEmpty;

  /// No description provided for @holidayToday.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get holidayToday;

  /// No description provided for @holidayNotice.
  ///
  /// In en, this message translates to:
  /// **'HOLIDAY NOTICE'**
  String get holidayNotice;

  /// No description provided for @removePoster.
  ///
  /// In en, this message translates to:
  /// **'Remove poster'**
  String get removePoster;

  /// No description provided for @holidayClosedOn.
  ///
  /// In en, this message translates to:
  /// **'Closed · {dates}'**
  String holidayClosedOn(String dates);

  /// No description provided for @holidayOpenOn.
  ///
  /// In en, this message translates to:
  /// **'Open · {dates}'**
  String holidayOpenOn(String dates);

  /// No description provided for @holidayClosedToday.
  ///
  /// In en, this message translates to:
  /// **'Closed today · {title}'**
  String holidayClosedToday(String title);

  /// No description provided for @holidayOpenHoursToday.
  ///
  /// In en, this message translates to:
  /// **'Open {opens} – {closes} today · {title}'**
  String holidayOpenHoursToday(String opens, String closes, String title);

  /// No description provided for @holidayOpenToday.
  ///
  /// In en, this message translates to:
  /// **'Open today · {title}'**
  String holidayOpenToday(String title);

  /// No description provided for @infoMenuPages.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 page} other{{count} pages}} · QR code'**
  String infoMenuPages(int count);

  /// No description provided for @infoCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get infoCategory;

  /// No description provided for @infoOpeningHours.
  ///
  /// In en, this message translates to:
  /// **'Opening hours'**
  String get infoOpeningHours;

  /// No description provided for @infoService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get infoService;

  /// No description provided for @infoPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get infoPhone;

  /// No description provided for @infoAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get infoAbout;

  /// No description provided for @infoNoDetails.
  ///
  /// In en, this message translates to:
  /// **'No details yet.'**
  String get infoNoDetails;

  /// No description provided for @infoDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get infoDetails;

  /// No description provided for @infoFinishProfile.
  ///
  /// In en, this message translates to:
  /// **'Finish your profile'**
  String get infoFinishProfile;

  /// No description provided for @infoDoneOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String infoDoneOfTotal(int done, int total);

  /// No description provided for @infoCompleteHint.
  ///
  /// In en, this message translates to:
  /// **'Complete profiles get approved faster and show up more in search.'**
  String get infoCompleteHint;

  /// No description provided for @openNow.
  ///
  /// In en, this message translates to:
  /// **'Open now'**
  String get openNow;

  /// No description provided for @closedStatus.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closedStatus;

  /// No description provided for @serviceDineIn.
  ///
  /// In en, this message translates to:
  /// **'Dine-in Only'**
  String get serviceDineIn;

  /// No description provided for @serviceDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery Only'**
  String get serviceDelivery;

  /// No description provided for @serviceDineInDelivery.
  ///
  /// In en, this message translates to:
  /// **'Dine-in & Delivery'**
  String get serviceDineInDelivery;

  /// No description provided for @serviceTakeaway.
  ///
  /// In en, this message translates to:
  /// **'Takeaway'**
  String get serviceTakeaway;

  /// No description provided for @approvalNotApproved.
  ///
  /// In en, this message translates to:
  /// **'Not approved'**
  String get approvalNotApproved;

  /// No description provided for @approvalRejectedBody.
  ///
  /// In en, this message translates to:
  /// **'An admin didn\'t approve this restaurant, so customers can\'t see it.'**
  String get approvalRejectedBody;

  /// No description provided for @approvalReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String approvalReason(String reason);

  /// No description provided for @approvalPendingBody.
  ///
  /// In en, this message translates to:
  /// **'Customers can\'t see it yet. It goes public once the Khmer Cat team approves it.'**
  String get approvalPendingBody;

  /// No description provided for @unpublishedTitle.
  ///
  /// In en, this message translates to:
  /// **'Hidden from customers'**
  String get unpublishedTitle;

  /// No description provided for @unpublishedBody.
  ///
  /// In en, this message translates to:
  /// **'Only your team can see this restaurant.'**
  String get unpublishedBody;

  /// No description provided for @publishAction.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publishAction;

  /// No description provided for @publishedAgain.
  ///
  /// In en, this message translates to:
  /// **'Restaurant is public again'**
  String get publishedAgain;

  /// No description provided for @publishFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not publish.'**
  String get publishFailed;

  /// No description provided for @deleteVideoTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete video?'**
  String get deleteVideoTitle;

  /// No description provided for @deleteVideoMessage.
  ///
  /// In en, this message translates to:
  /// **'It will be moved to Delete for 30 days, then removed permanently.'**
  String get deleteVideoMessage;

  /// No description provided for @videoDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete video.'**
  String get videoDeleteFailed;

  /// No description provided for @addVideo.
  ///
  /// In en, this message translates to:
  /// **'Add video'**
  String get addVideo;

  /// No description provided for @videosLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load videos.'**
  String get videosLoadFailed;

  /// No description provided for @textMore.
  ///
  /// In en, this message translates to:
  /// **'more'**
  String get textMore;

  /// No description provided for @distanceAway.
  ///
  /// In en, this message translates to:
  /// **'{distance} away'**
  String distanceAway(String distance);

  /// No description provided for @signInToFollowRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Sign in to follow this restaurant'**
  String get signInToFollowRestaurant;

  /// No description provided for @signInToWriteReview.
  ///
  /// In en, this message translates to:
  /// **'Sign in to write a review'**
  String get signInToWriteReview;

  /// No description provided for @viewMenu.
  ///
  /// In en, this message translates to:
  /// **'View menu'**
  String get viewMenu;

  /// No description provided for @shareOnKhmerCat.
  ///
  /// In en, this message translates to:
  /// **'{name} on Khmer Cat'**
  String shareOnKhmerCat(String name);

  /// No description provided for @shareMenuLine.
  ///
  /// In en, this message translates to:
  /// **'Menu: {url}'**
  String shareMenuLine(String url);

  /// No description provided for @popularTag.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popularTag;

  /// No description provided for @hoursNotAdded.
  ///
  /// In en, this message translates to:
  /// **'Opening hours not added yet'**
  String get hoursNotAdded;

  /// No description provided for @hoursDaily.
  ///
  /// In en, this message translates to:
  /// **'daily'**
  String get hoursDaily;

  /// No description provided for @restaurantTabComments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get restaurantTabComments;

  /// No description provided for @restaurantPostsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Videos posted by this restaurant show up here.'**
  String get restaurantPostsEmpty;

  /// No description provided for @likesPill.
  ///
  /// In en, this message translates to:
  /// **'{formatted} {count, plural, =1{like} other{likes}}'**
  String likesPill(String formatted, int count);

  /// No description provided for @addLink.
  ///
  /// In en, this message translates to:
  /// **'+ Add'**
  String get addLink;

  /// No description provided for @orderDelivery.
  ///
  /// In en, this message translates to:
  /// **'Order delivery'**
  String get orderDelivery;

  /// No description provided for @followUs.
  ///
  /// In en, this message translates to:
  /// **'Follow us'**
  String get followUs;

  /// No description provided for @statPostLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Post} other{Posts}}'**
  String statPostLabel(int count);

  /// No description provided for @statReviewLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Review} other{Reviews}}'**
  String statReviewLabel(int count);

  /// No description provided for @statFollowerLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Follower} other{Followers}}'**
  String statFollowerLabel(int count);

  /// No description provided for @reviewsEmptyTeam.
  ///
  /// In en, this message translates to:
  /// **'Reviews from your customers show up here.'**
  String get reviewsEmptyTeam;

  /// No description provided for @reviewsEmptyVisitor.
  ///
  /// In en, this message translates to:
  /// **'Be the first to review this restaurant.'**
  String get reviewsEmptyVisitor;

  /// No description provided for @writeReview.
  ///
  /// In en, this message translates to:
  /// **'Write a review'**
  String get writeReview;

  /// No description provided for @editYourReview.
  ///
  /// In en, this message translates to:
  /// **'Edit your review'**
  String get editYourReview;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All · {count}'**
  String filterAll(int count);

  /// No description provided for @filterWithVideo.
  ///
  /// In en, this message translates to:
  /// **'With video · {count}'**
  String filterWithVideo(int count);

  /// No description provided for @noVideoReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No video reviews yet.'**
  String get noVideoReviewsYet;

  /// No description provided for @signInToLikeReviews.
  ///
  /// In en, this message translates to:
  /// **'Sign in to like reviews'**
  String get signInToLikeReviews;

  /// No description provided for @ratingsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 rating} other{{count} ratings}}'**
  String ratingsCount(int count);

  /// No description provided for @replyAction.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get replyAction;

  /// No description provided for @editReply.
  ///
  /// In en, this message translates to:
  /// **'Edit reply'**
  String get editReply;

  /// No description provided for @agoShortMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count}m'**
  String agoShortMinutes(int count);

  /// No description provided for @agoShortHours.
  ///
  /// In en, this message translates to:
  /// **'{count}h'**
  String agoShortHours(int count);

  /// No description provided for @agoShortDays.
  ///
  /// In en, this message translates to:
  /// **'{count}d'**
  String agoShortDays(int count);

  /// No description provided for @agoShortWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count}w'**
  String agoShortWeeks(int count);

  /// No description provided for @agoShortMonths.
  ///
  /// In en, this message translates to:
  /// **'{count}mo'**
  String agoShortMonths(int count);

  /// No description provided for @agoShortYears.
  ///
  /// In en, this message translates to:
  /// **'{count}y'**
  String agoShortYears(int count);

  /// No description provided for @videoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This video isn\'t available.'**
  String get videoUnavailable;

  /// No description provided for @replyFrom.
  ///
  /// In en, this message translates to:
  /// **'Reply from {name}'**
  String replyFrom(String name);

  /// No description provided for @reviewsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load reviews.'**
  String get reviewsLoadFailed;

  /// No description provided for @replyTo.
  ///
  /// In en, this message translates to:
  /// **'Reply to {name}'**
  String replyTo(String name);

  /// No description provided for @replyHint.
  ///
  /// In en, this message translates to:
  /// **'Thank them, or answer their question…'**
  String get replyHint;

  /// No description provided for @replyRemoved.
  ///
  /// In en, this message translates to:
  /// **'Reply removed.'**
  String get replyRemoved;

  /// No description provided for @replyPosted.
  ///
  /// In en, this message translates to:
  /// **'Reply posted.'**
  String get replyPosted;

  /// No description provided for @saveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveAction;

  /// No description provided for @posterTitlePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Your holiday title'**
  String get posterTitlePlaceholder;

  /// No description provided for @posterPosted.
  ///
  /// In en, this message translates to:
  /// **'Holiday poster posted.'**
  String get posterPosted;

  /// No description provided for @posterPostedMany.
  ///
  /// In en, this message translates to:
  /// **'Holiday poster posted to {count} restaurants.'**
  String posterPostedMany(int count);

  /// No description provided for @posterPostFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not post the poster.'**
  String get posterPostFailed;

  /// No description provided for @posterYourHoliday.
  ///
  /// In en, this message translates to:
  /// **'your holiday'**
  String get posterYourHoliday;

  /// No description provided for @posterTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get posterTitleLabel;

  /// No description provided for @posterTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Happy Independence Day'**
  String get posterTitleHint;

  /// No description provided for @posterDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get posterDescriptionLabel;

  /// No description provided for @posterDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. We\'re closed on {date}. Back the next day!'**
  String posterDescriptionHint(String date);

  /// No description provided for @posterApplyTo.
  ///
  /// In en, this message translates to:
  /// **'Apply to'**
  String get posterApplyTo;

  /// No description provided for @chosenOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{chosen} of {total}'**
  String chosenOfTotal(int chosen, int total);

  /// No description provided for @clearAction.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearAction;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @posterActingAs.
  ///
  /// In en, this message translates to:
  /// **'You\'re acting as this restaurant, so the poster is for it only.'**
  String get posterActingAs;

  /// No description provided for @posterNoRestaurants.
  ///
  /// In en, this message translates to:
  /// **'You don\'t own or manage a restaurant yet.'**
  String get posterNoRestaurants;

  /// No description provided for @posterOpeningOnHoliday.
  ///
  /// In en, this message translates to:
  /// **'Opening on the holiday'**
  String get posterOpeningOnHoliday;

  /// No description provided for @posterStarts.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get posterStarts;

  /// No description provided for @changeAction.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeAction;

  /// No description provided for @posterUntil.
  ///
  /// In en, this message translates to:
  /// **'Until {date}'**
  String posterUntil(String date);

  /// No description provided for @posterOpens.
  ///
  /// In en, this message translates to:
  /// **'Opens'**
  String get posterOpens;

  /// No description provided for @posterCloses.
  ///
  /// In en, this message translates to:
  /// **'Closes'**
  String get posterCloses;

  /// No description provided for @modeSpecial.
  ///
  /// In en, this message translates to:
  /// **'Special'**
  String get modeSpecial;

  /// No description provided for @modeOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get modeOpen;

  /// No description provided for @newPosterTitle.
  ///
  /// In en, this message translates to:
  /// **'New poster'**
  String get newPosterTitle;

  /// No description provided for @postAction.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get postAction;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// No description provided for @posterSeePrefix.
  ///
  /// In en, this message translates to:
  /// **'Customers will see '**
  String get posterSeePrefix;

  /// No description provided for @posterSeeSuffix.
  ///
  /// In en, this message translates to:
  /// **' on your profile and in search that day.'**
  String get posterSeeSuffix;

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String daysCount(int count);

  /// No description provided for @createTitle.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createTitle;

  /// No description provided for @postingAs.
  ///
  /// In en, this message translates to:
  /// **'Posting as '**
  String get postingAs;

  /// No description provided for @createVideoTitle.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get createVideoTitle;

  /// No description provided for @createVideoSub.
  ///
  /// In en, this message translates to:
  /// **'Record or upload'**
  String get createVideoSub;

  /// No description provided for @createPosterTitle.
  ///
  /// In en, this message translates to:
  /// **'Holiday poster'**
  String get createPosterTitle;

  /// No description provided for @createPosterSub.
  ///
  /// In en, this message translates to:
  /// **'Closed or special hours'**
  String get createPosterSub;

  /// No description provided for @loggingOut.
  ///
  /// In en, this message translates to:
  /// **'Logging out…'**
  String get loggingOut;

  /// No description provided for @loggedOut.
  ///
  /// In en, this message translates to:
  /// **'Logged out'**
  String get loggedOut;

  /// No description provided for @logOutFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t log out. Please try again.'**
  String get logOutFailed;

  /// No description provided for @approvalStepSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get approvalStepSubmitted;

  /// No description provided for @approvalStepReviewing.
  ///
  /// In en, this message translates to:
  /// **'Reviewing…'**
  String get approvalStepReviewing;

  /// No description provided for @approvalStepReviewed.
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get approvalStepReviewed;

  /// No description provided for @approvalWorkingTitle.
  ///
  /// In en, this message translates to:
  /// **'Getting {name} ready…'**
  String approvalWorkingTitle(String name);

  /// No description provided for @approvalLiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Your restaurant is live!'**
  String get approvalLiveTitle;
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
