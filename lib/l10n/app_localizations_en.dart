// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get menuTitle => 'Menu';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get accountAndPages => 'Account & Pages';

  @override
  String get createPage => 'Create Page';

  @override
  String get yourRestaurants => 'Your restaurants';

  @override
  String get createRestaurant => 'Create a restaurant';

  @override
  String get noRestaurantsYet => 'You don\'t manage any pages yet.';

  @override
  String get preferences => 'Preferences';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageKhmer => 'ខ្មែរ';

  @override
  String get appearance => 'Appearance';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get termsOfPolicy => 'Terms of Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get termsOfPrivacy => 'Terms of Privacy';

  @override
  String get logOut => 'Log out';

  @override
  String get logOutConfirmTitle => 'Log out?';

  @override
  String get logOutConfirmMessage => 'You can always sign back in.';

  @override
  String get statFollowing => 'Following';

  @override
  String get statFollowers => 'Followers';

  @override
  String get statPosts => 'Posts';

  @override
  String get statLikes => 'Likes';

  @override
  String get profileTabPosts => 'Posts';

  @override
  String get profileTabSaved => 'Saved';

  @override
  String get profileTabShared => 'Shared';

  @override
  String get profileTabLiked => 'Liked';

  @override
  String get profileTabFavorites => 'Favorites';

  @override
  String get profileTabTrash => 'Trash';

  @override
  String get profileTabAbout => 'About';

  @override
  String get emptyPosts => 'You haven\'t posted any videos yet.';

  @override
  String get emptySaved => 'Videos you save show up here.';

  @override
  String get emptyShared => 'Videos you share show up here.';

  @override
  String get emptyLiked => 'Videos you like show up here.';

  @override
  String get emptyFavorites => 'Your favorite videos show up here.';

  @override
  String get emptyTrash => 'Deleted videos stay here for 30 days.';

  @override
  String get aboutSectionTitle => 'Account Info';

  @override
  String get aboutName => 'Name';

  @override
  String get aboutUsername => 'Username';

  @override
  String get aboutEmail => 'Email';

  @override
  String get aboutBio => 'Bio';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get currentlyViewing => 'Currently viewing';

  @override
  String youAreViewingAs(String name) {
    return 'You are using the app as $name';
  }

  @override
  String get switchTo => 'Switch to';

  @override
  String get profileTypePersonal => 'Personal';

  @override
  String get profileTypeRestaurant => 'Restaurant';

  @override
  String get profileStatusActive => 'Active';

  @override
  String get profileStatusInactive => 'Inactive';

  @override
  String switchedTo(String name) {
    return 'Switched to $name';
  }

  @override
  String get switchFailed => 'Could not switch profile. Please try again.';

  @override
  String confirmSwitchTitle(String name) {
    return 'Switch to $name';
  }

  @override
  String get confirmSwitchMessage =>
      'Enter your password to switch back to your personal account.';

  @override
  String get passwordHint => 'Password';

  @override
  String get continueAction => 'Continue';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get switchAccount => 'Switch account';

  @override
  String profilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count profiles',
      one: '1 profile',
    );
    return '$_temp0';
  }

  @override
  String get accountSection => 'Account';

  @override
  String get deactivateAccount => 'Deactivate account';

  @override
  String get deactivateAccountSubtitle => 'Hide your profile for a while';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountSubtitle => 'Permanently remove your account';

  @override
  String get deactivateAccountTitle => 'Deactivate your account?';

  @override
  String get deactivateAccountPoint1 =>
      'Your profile, videos and comments are hidden.';

  @override
  String get deactivateAccountPoint2 => 'You\'re signed out on every device.';

  @override
  String get deactivateAccountPoint3 => 'Log in again anytime to reactivate.';

  @override
  String get deactivateAction => 'Deactivate';

  @override
  String get deleteAccountTitle => 'Delete your account?';

  @override
  String get deleteAccountPoint1 =>
      'Your profile, videos, comments and likes are removed for good.';

  @override
  String get deleteAccountPoint2 => 'Restaurants you own are deleted too.';

  @override
  String get deleteAccountPoint3 => 'This can\'t be undone.';

  @override
  String get deleteAccountAlternative =>
      'Just need a break? Deactivate instead.';

  @override
  String get deleteAction => 'Delete';

  @override
  String get confirmPasswordHint => 'Enter your password to confirm';

  @override
  String get accountDeactivated => 'Your account is deactivated. See you soon!';

  @override
  String get accountDeleted => 'Your account has been deleted.';

  @override
  String get accountReactivated =>
      'Welcome back! Your account is active again.';

  @override
  String get accountActionFailed => 'Something went wrong. Please try again.';

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navNotifications => 'Notification';

  @override
  String get navProfile => 'Profile';

  @override
  String get yourAccount => 'Your account';

  @override
  String get seeAll => 'See all';

  @override
  String get showLess => 'Show less';

  @override
  String get addressSection => 'Address';

  @override
  String get savedAddresses => 'Saved addresses';

  @override
  String reviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
    );
    return '$_temp0';
  }

  @override
  String get restaurantHidden => 'Hidden';

  @override
  String savedCount(int count) {
    return '$count saved';
  }

  @override
  String get addressesTitle => 'Addresses';

  @override
  String get addNewAddress => 'Add new address';

  @override
  String get noData => 'No data';

  @override
  String get noAddressesMessage =>
      'You haven\'t saved any addresses yet.\nTap \"Add new address\" to add one.';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get addressesLoadFailed => 'Couldn\'t load your addresses.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get editAction => 'Edit';

  @override
  String get moreActions => 'More';

  @override
  String get deleteAddressTitle => 'Delete address?';

  @override
  String deleteAddressMessage(String label) {
    return '\"$label\" will be removed from your addresses.';
  }

  @override
  String get addressDeleteFailed => 'Could not delete the address';

  @override
  String get addressSaveFailed =>
      'Could not save the address. Please try again.';

  @override
  String get addressSearchHint => 'Search for an address';

  @override
  String get addressPinHint => 'Move the map to place the pin';

  @override
  String get findingAddress => 'Finding address…';

  @override
  String get addressDetailHint => 'House no., building, floor (optional)';

  @override
  String get saveAddress => 'Save address';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get addressSaved => 'Address saved';

  @override
  String get addressUpdated => 'Address updated';

  @override
  String get placeOpenFailed => 'Could not open that place';

  @override
  String get addressLabelHome => 'Home';

  @override
  String get addressLabelOffice => 'Office';

  @override
  String get addressLabelOther => 'Other';

  @override
  String get backAction => 'Back';

  @override
  String get myLocation => 'My location';

  @override
  String get reviewersTitle => 'Reviewers';

  @override
  String get followAction => 'Follow';

  @override
  String get followingAction => 'Following';

  @override
  String get youLabel => 'You';

  @override
  String get noFollowersYet => 'No followers yet';

  @override
  String get notFollowingAnyoneYet => 'Not following anyone yet';

  @override
  String get noReviewersYet => 'No reviews yet';

  @override
  String get peopleLoadFailed => 'Couldn\'t load this list.';

  @override
  String get signInToFollow => 'Sign in to follow people';

  @override
  String get followFailed => 'Couldn\'t update follow. Please try again.';

  @override
  String get profileTabVideos => 'Videos';
}
