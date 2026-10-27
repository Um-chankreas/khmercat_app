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
  String get switchButton => 'Switch';

  @override
  String get switchingProfile => 'Switching profile…';

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

  @override
  String get adminNavHome => 'Home';

  @override
  String get adminNavRestaurants => 'Restaurants';

  @override
  String get adminNavReports => 'Reports';

  @override
  String get adminNavSettings => 'Settings';

  @override
  String adminHi(String name) {
    return 'Hi $name';
  }

  @override
  String get adminDashboardLoadFailed => 'Couldn\'t load the dashboard.';

  @override
  String get adminTileToApprove => 'Restaurants to approve';

  @override
  String get adminTileOpenReports => 'Open reports';

  @override
  String get adminUsers => 'Users';

  @override
  String adminTileUsersWeek(int count) {
    return 'Users · +$count this week';
  }

  @override
  String get adminTileActiveRestaurants => 'Active restaurants';

  @override
  String get adminWaitingApproval => 'Waiting for approval';

  @override
  String adminSeeAll(int count) {
    return 'See all $count';
  }

  @override
  String get adminNoRestaurantsWaiting => 'No restaurants waiting.';

  @override
  String get adminLatestReports => 'Latest reports';

  @override
  String get adminNoOpenReports => 'No open reports.';

  @override
  String adminVideoBy(String username) {
    return 'Video by @$username';
  }

  @override
  String adminReportsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reports',
      one: '1 report',
    );
    return '$_temp0';
  }

  @override
  String adminVideosCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count videos',
      one: '1 video',
    );
    return '$_temp0';
  }

  @override
  String get adminSomethingWrong => 'Something went wrong';

  @override
  String get adminReject => 'Reject';

  @override
  String adminRejectTitle(String name) {
    return 'Reject $name?';
  }

  @override
  String get adminReasonForOwner => 'Reason for the owner (optional)';

  @override
  String get adminRejected => 'Rejected';

  @override
  String get adminApprove => 'Approve';

  @override
  String get adminApproved => 'Approved';

  @override
  String get adminDelete => 'Delete';

  @override
  String get adminTabPending => 'Pending';

  @override
  String get adminTabActive => 'Active';

  @override
  String get adminTabDeactivated => 'Deactivated';

  @override
  String adminDeactivateTitle(String name) {
    return 'Deactivate $name?';
  }

  @override
  String get adminDeactivateHint => 'Why? e.g. fake photos, many reports';

  @override
  String get adminDeactivate => 'Deactivate';

  @override
  String get adminActivate => 'Activate';

  @override
  String get adminActivatedAgain => 'Activated again';

  @override
  String get adminRestaurantsLoadFailed => 'Couldn\'t load restaurants.';

  @override
  String get adminNoPending => 'No restaurants waiting for approval.';

  @override
  String get adminNoActive => 'No active restaurants.';

  @override
  String get adminNoDeactivated => 'No deactivated restaurants.';

  @override
  String adminOwner(String name) {
    return 'Owner $name';
  }

  @override
  String adminDeactivatedOn(String date) {
    return 'Deactivated $date';
  }

  @override
  String adminReasonValue(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get adminVideoTakenDown => 'This video was taken down.';

  @override
  String get adminDeleteVideoTitle => 'Delete this video?';

  @override
  String adminDeleteVideoMessage(String author) {
    return 'It\'s taken down for everyone and its reports are closed. $author can still see it in their Deleted tab for 30 days.';
  }

  @override
  String get adminTheAuthor => 'The author';

  @override
  String get adminVideoDeleted => 'Video deleted';

  @override
  String get adminReportsLoadFailed => 'Couldn\'t load reports.';

  @override
  String get adminAllClear => 'No open reports. All clear!';

  @override
  String get adminNothingResolved => 'Nothing resolved yet.';

  @override
  String get adminReportsDismissed => 'Reports dismissed';

  @override
  String get adminTabOpen => 'Open';

  @override
  String get adminTabResolved => 'Resolved';

  @override
  String get adminTapToView => 'Tap to view';

  @override
  String get adminAuthorBanned => 'Author banned';

  @override
  String get adminDismiss => 'Dismiss';

  @override
  String get adminBan => 'Ban';

  @override
  String get adminByYou => 'by you';

  @override
  String adminByName(String name) {
    return 'by $name';
  }

  @override
  String get adminUserBanned => 'User banned';

  @override
  String get adminDeleted => 'Deleted';

  @override
  String get adminDismissed => 'Dismissed';

  @override
  String adminBannedToast(String username) {
    return '@$username banned';
  }

  @override
  String adminBannedWithVideos(String username, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count videos',
      one: '1 video',
    );
    return '@$username banned · $_temp0 deleted';
  }

  @override
  String get adminBanFailed => 'Couldn\'t ban this user.';

  @override
  String adminBanTitle(String name) {
    return 'Ban $name?';
  }

  @override
  String get adminHowLong => 'How long';

  @override
  String adminDays(int count) {
    return '$count days';
  }

  @override
  String get adminForever => 'Forever';

  @override
  String get adminReason => 'Reason';

  @override
  String get adminAlsoDeleteVideos => 'Also delete reported videos';

  @override
  String get adminAlsoDeleteVideosSub => 'Their videos with open reports';

  @override
  String get adminBanNote =>
      'They can\'t log in, post or comment while banned, and are told why when they try to log in.';

  @override
  String get adminBanUser => 'Ban user';

  @override
  String get adminBanReasonSexual => 'Nudity or sexual content';

  @override
  String get adminBanReasonSpam => 'Spam or scam';

  @override
  String get adminBanReasonHate => 'Hate or harassment';

  @override
  String get adminBanReasonFake => 'Fake account';

  @override
  String adminUnbanTitle(String username) {
    return 'Unban @$username?';
  }

  @override
  String get adminUnbanMessage => 'They can log in, post and comment again.';

  @override
  String get adminUnban => 'Unban';

  @override
  String adminUnbannedToast(String username) {
    return '@$username unbanned';
  }

  @override
  String get adminUnbanFailed => 'Couldn\'t unban.';

  @override
  String get adminUsersLoadFailed => 'Couldn\'t load users.';

  @override
  String adminNoMatch(String query) {
    return 'No one matches \"$query\".';
  }

  @override
  String get adminNoReported => 'No one has open reports.';

  @override
  String get adminNoBanned => 'No one is banned.';

  @override
  String get adminNoUsers => 'No users yet.';

  @override
  String get adminSearchUsers => 'Search name, @username or phone';

  @override
  String get adminFilterAll => 'All';

  @override
  String get adminFilterReported => 'Reported';

  @override
  String get adminFilterBanned => 'Banned';

  @override
  String get adminBannedForGood => 'Banned for good';

  @override
  String adminBannedUntil(String date) {
    return 'Banned until $date';
  }

  @override
  String get adminRoleAdmin => 'Admin';

  @override
  String get adminViewProfile => 'View profile';

  @override
  String get adminPeople => 'People';

  @override
  String get adminUsersRowSub =>
      'Search, see reported and banned, ban or unban';

  @override
  String get adminActivity => 'Activity';

  @override
  String get adminActivityLog => 'Admin activity log';

  @override
  String get adminActivityLogSub => 'Every approve, ban and delete';

  @override
  String get adminAccount => 'Account';

  @override
  String get adminBackToApp => 'Back to KhmerCat';

  @override
  String get adminBackToAppSub => 'Leave the admin area';

  @override
  String get adminLogLoadFailed => 'Couldn\'t load the log.';

  @override
  String get adminNothingDone => 'Nothing done yet.';

  @override
  String get adminActivityTitle => 'Activity log';

  @override
  String adminActApprove(String target) {
    return 'Approved $target';
  }

  @override
  String adminActReject(String target) {
    return 'Rejected $target';
  }

  @override
  String adminActDeactivate(String target) {
    return 'Deactivated $target';
  }

  @override
  String adminActActivate(String target) {
    return 'Activated $target';
  }

  @override
  String adminActRemoveVideo(String target) {
    return 'Deleted $target';
  }

  @override
  String adminActDismiss(String target) {
    return 'Dismissed reports on $target';
  }

  @override
  String adminActBan(String target) {
    return 'Banned $target';
  }

  @override
  String adminActUnban(String target) {
    return 'Unbanned $target';
  }

  @override
  String get adminYou => 'You';

  @override
  String get adminAnAdmin => 'An admin';

  @override
  String get adminNow => 'now';

  @override
  String adminMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String adminHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String get adminYesterday => 'Yesterday';

  @override
  String adminDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get adminReasonViolence => 'Violence or abuse';

  @override
  String get adminReasonChildSafety => 'Child safety';

  @override
  String get adminReasonMisleading => 'False or misleading information';

  @override
  String get adminReasonAi => 'Problematic AI content';

  @override
  String get adminReasonSelfHarm => 'Suicide and self-harm';

  @override
  String get adminReasonBranded => 'Undisclosed branded content';

  @override
  String get adminReasonCopyright => 'Copyright or someone else\'s content';

  @override
  String get adminReasonInappropriate => 'Inappropriate';

  @override
  String get adminReasonOther => 'Something else';

  @override
  String get adminShortNudity => 'Nudity';

  @override
  String get adminShortHarassment => 'Harassment';

  @override
  String get adminShortViolence => 'Violence';

  @override
  String get adminShortChildSafety => 'Child safety';

  @override
  String get adminShortMisleading => 'Misleading';

  @override
  String get adminShortAi => 'AI content';

  @override
  String get adminShortSelfHarm => 'Self-harm';

  @override
  String get adminShortBranded => 'Branded';

  @override
  String get adminShortSpam => 'Spam';

  @override
  String get adminShortCopyright => 'Copyright';

  @override
  String get adminShortOther => 'Other';

  @override
  String get adminTabOff => 'Off';

  @override
  String get restaurantTabReviews => 'Reviews';

  @override
  String get restaurantTabInfo => 'Info';

  @override
  String get statReviews => 'Reviews';

  @override
  String get qrCodeTooltip => 'QR code';

  @override
  String get restaurantUnavailable => 'Restaurant unavailable';

  @override
  String get notFound => 'Not found';

  @override
  String get removePosterTitle => 'Remove holiday poster?';

  @override
  String get removePosterMessage =>
      'It comes off your profile and the feed, and your usual hours show again that day.';

  @override
  String get removeAction => 'Remove';

  @override
  String get removePosterFailed => 'Could not remove the poster.';

  @override
  String get restaurantNoPostsTitle => 'No posts yet';

  @override
  String get restaurantNoPostsOwner =>
      'Tap + to post your first video as this restaurant.';

  @override
  String get restaurantReviewsEmpty =>
      'Videos from diners who visited show up here.';

  @override
  String get holidayToday => 'TODAY';

  @override
  String get holidayNotice => 'HOLIDAY NOTICE';

  @override
  String get removePoster => 'Remove poster';

  @override
  String holidayClosedOn(String dates) {
    return 'Closed · $dates';
  }

  @override
  String holidayOpenOn(String dates) {
    return 'Open · $dates';
  }

  @override
  String holidayClosedToday(String title) {
    return 'Closed today · $title';
  }

  @override
  String holidayOpenHoursToday(String opens, String closes, String title) {
    return 'Open $opens – $closes today · $title';
  }

  @override
  String holidayOpenToday(String title) {
    return 'Open today · $title';
  }

  @override
  String infoMenuPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return '$_temp0 · QR code';
  }

  @override
  String get infoCategory => 'Category';

  @override
  String get infoOpeningHours => 'Opening hours';

  @override
  String get infoService => 'Service';

  @override
  String get infoPhone => 'Phone';

  @override
  String get infoAbout => 'About';

  @override
  String get infoNoDetails => 'No details yet.';

  @override
  String get infoDetails => 'Details';

  @override
  String get infoFinishProfile => 'Finish your profile';

  @override
  String infoDoneOfTotal(int done, int total) {
    return '$done of $total done';
  }

  @override
  String get infoCompleteHint =>
      'Complete profiles get approved faster and show up more in search.';

  @override
  String get openNow => 'Open now';

  @override
  String get closedStatus => 'Closed';

  @override
  String get serviceDineIn => 'Dine-in Only';

  @override
  String get serviceDelivery => 'Delivery Only';

  @override
  String get serviceDineInDelivery => 'Dine-in & Delivery';

  @override
  String get serviceTakeaway => 'Takeaway';

  @override
  String get approvalNotApproved => 'Not approved';

  @override
  String get approvalRejectedBody =>
      'An admin didn\'t approve this restaurant, so customers can\'t see it.';

  @override
  String approvalReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get approvalPendingBody =>
      'Customers can\'t see it yet. It goes public once the Khmer Cat team approves it.';

  @override
  String get unpublishedTitle => 'Hidden from customers';

  @override
  String get unpublishedBody => 'Only your team can see this restaurant.';

  @override
  String get publishAction => 'Publish';

  @override
  String get publishedAgain => 'Restaurant is public again';

  @override
  String get publishFailed => 'Could not publish.';

  @override
  String get deleteVideoTitle => 'Delete video?';

  @override
  String get deleteVideoMessage =>
      'It will be moved to Delete for 30 days, then removed permanently.';

  @override
  String get videoDeleteFailed => 'Failed to delete video.';

  @override
  String get addVideo => 'Add video';

  @override
  String get videosLoadFailed => 'Couldn\'t load videos.';

  @override
  String get textMore => 'more';

  @override
  String distanceAway(String distance) {
    return '$distance away';
  }

  @override
  String get signInToFollowRestaurant => 'Sign in to follow this restaurant';

  @override
  String get signInToWriteReview => 'Sign in to write a review';

  @override
  String get viewMenu => 'View menu';

  @override
  String shareOnKhmerCat(String name) {
    return '$name on Khmer Cat';
  }

  @override
  String shareMenuLine(String url) {
    return 'Menu: $url';
  }

  @override
  String get popularTag => 'Popular';

  @override
  String get hoursNotAdded => 'Opening hours not added yet';

  @override
  String get hoursDaily => 'daily';

  @override
  String get restaurantTabComments => 'Comments';

  @override
  String get restaurantPostsEmpty =>
      'Videos posted by this restaurant show up here.';

  @override
  String likesPill(String formatted, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'likes',
      one: 'like',
    );
    return '$formatted $_temp0';
  }

  @override
  String get addLink => '+ Add';

  @override
  String get orderDelivery => 'Order delivery';

  @override
  String get followUs => 'Follow us';

  @override
  String statPostLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Posts',
      one: 'Post',
    );
    return '$_temp0';
  }

  @override
  String statReviewLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Reviews',
      one: 'Review',
    );
    return '$_temp0';
  }

  @override
  String statFollowerLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Followers',
      one: 'Follower',
    );
    return '$_temp0';
  }

  @override
  String get reviewsEmptyTeam => 'Reviews from your customers show up here.';

  @override
  String get reviewsEmptyVisitor => 'Be the first to review this restaurant.';

  @override
  String get writeReview => 'Write a review';

  @override
  String get editYourReview => 'Edit your review';

  @override
  String filterAll(int count) {
    return 'All · $count';
  }

  @override
  String filterWithVideo(int count) {
    return 'With video · $count';
  }

  @override
  String get noVideoReviewsYet => 'No video reviews yet.';

  @override
  String get signInToLikeReviews => 'Sign in to like reviews';

  @override
  String ratingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ratings',
      one: '1 rating',
    );
    return '$_temp0';
  }

  @override
  String get replyAction => 'Reply';

  @override
  String get editReply => 'Edit reply';

  @override
  String agoShortMinutes(int count) {
    return '${count}m';
  }

  @override
  String agoShortHours(int count) {
    return '${count}h';
  }

  @override
  String agoShortDays(int count) {
    return '${count}d';
  }

  @override
  String agoShortWeeks(int count) {
    return '${count}w';
  }

  @override
  String agoShortMonths(int count) {
    return '${count}mo';
  }

  @override
  String agoShortYears(int count) {
    return '${count}y';
  }

  @override
  String get videoUnavailable => 'This video isn\'t available.';

  @override
  String replyFrom(String name) {
    return 'Reply from $name';
  }

  @override
  String get reviewsLoadFailed => 'Couldn\'t load reviews.';

  @override
  String replyTo(String name) {
    return 'Reply to $name';
  }

  @override
  String get replyHint => 'Thank them, or answer their question…';

  @override
  String get replyRemoved => 'Reply removed.';

  @override
  String get replyPosted => 'Reply posted.';

  @override
  String get saveAction => 'Save';

  @override
  String get posterTitlePlaceholder => 'Your holiday title';

  @override
  String get posterPosted => 'Holiday poster posted.';

  @override
  String posterPostedMany(int count) {
    return 'Holiday poster posted to $count restaurants.';
  }

  @override
  String get posterPostFailed => 'Could not post the poster.';

  @override
  String get posterYourHoliday => 'your holiday';

  @override
  String get posterTitleLabel => 'Title';

  @override
  String get posterTitleHint => 'e.g. Happy Independence Day';

  @override
  String get posterDescriptionLabel => 'Description';

  @override
  String posterDescriptionHint(String date) {
    return 'e.g. We\'re closed on $date. Back the next day!';
  }

  @override
  String get posterApplyTo => 'Apply to';

  @override
  String chosenOfTotal(int chosen, int total) {
    return '$chosen of $total';
  }

  @override
  String get clearAction => 'Clear';

  @override
  String get selectAll => 'Select all';

  @override
  String get posterActingAs =>
      'You\'re acting as this restaurant, so the poster is for it only.';

  @override
  String get posterNoRestaurants =>
      'You don\'t own or manage a restaurant yet.';

  @override
  String get posterOpeningOnHoliday => 'Opening on the holiday';

  @override
  String get posterStarts => 'Starts';

  @override
  String get changeAction => 'Change';

  @override
  String posterUntil(String date) {
    return 'Until $date';
  }

  @override
  String get posterOpens => 'Opens';

  @override
  String get posterCloses => 'Closes';

  @override
  String get modeSpecial => 'Special';

  @override
  String get modeOpen => 'Open';

  @override
  String get newPosterTitle => 'New poster';

  @override
  String get postAction => 'Post';

  @override
  String get addPhoto => 'Add photo';

  @override
  String get posterSeePrefix => 'Customers will see ';

  @override
  String get posterSeeSuffix => ' on your profile and in search that day.';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get createTitle => 'Create';

  @override
  String get postingAs => 'Posting as ';

  @override
  String get createVideoTitle => 'Video';

  @override
  String get createVideoSub => 'Record or upload';

  @override
  String get createPosterTitle => 'Holiday poster';

  @override
  String get createPosterSub => 'Closed or special hours';

  @override
  String get loggingOut => 'Logging out…';

  @override
  String get loggedOut => 'Logged out';

  @override
  String get logOutFailed => 'Couldn\'t log out. Please try again.';

  @override
  String get approvalStepSubmitted => 'Submitted';

  @override
  String get approvalStepReviewing => 'Reviewing…';

  @override
  String get approvalStepReviewed => 'Reviewed';

  @override
  String approvalWorkingTitle(String name) {
    return 'Getting $name ready…';
  }

  @override
  String get approvalLiveTitle => 'Your restaurant is live!';
}
