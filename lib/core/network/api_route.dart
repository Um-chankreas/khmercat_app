abstract class ApiRoute {
  // auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String register = '/auth/register';
  static const String verifyEmail = '/auth/verify-email';
  static const String resendOTP = '/auth/resend-otp';
  static const String refreshToken = '/auth/refresh-token';
  static const String getUserAccount = '/auth/get-user-account';

  // own account (password-confirmed)
  static const String deactivateAccount = '/account/deactivate';
  static const String account = '/account';

  // feed / videos
  static const String videosFeed = '/videos/feed';
  static String video(String id) => '/videos/$id';
  static String videoLike(String id) => '/videos/$id/like';
  static String videoSave(String id) => '/videos/$id/save';
  static String videoView(String id) => '/videos/$id/view';
  static String videoComments(String id) => '/videos/$id/comments';
  static String comment(String id) => '/comments/$id';
  static String commentLike(String id) => '/comments/$id/like';
  static String commentReplies(String id) => '/comments/$id/replies';

  // search
  static const String search = '/search';

  // places (Google Places proxy — used by the restaurant location picker)
  static const String placesAutocomplete = '/places/autocomplete';
  static const String placesDetails = '/places/details';

  // restaurants
  static const String createRestaurant = '/restaurants/create';
  static const String myRestaurants = '/restaurants/mine';
  static const String switchRestaurant = '/restaurants/switch';
  static String restaurant(String id) => '/restaurants/$id';
  static String restaurantFollow(String id) => '/restaurants/$id/follow';
  static String restaurantAvatar(String id) => '/restaurants/$id/avatar';
  static String restaurantCover(String id) => '/restaurants/$id/cover';
  static String restaurantMenu(String id) => '/restaurants/$id/menu';
  static String restaurantMenuPage(String id, String pageId) =>
      '/restaurants/$id/menu/$pageId';

  // uploads
  static const String uploadReviewVideo = '/reviews/upload';
  static const String uploadRestaurantVideo = '/restaurants/videos/upload';

  // users
  static String user(String username) => '/users/$username';
  static String userFollow(String username) => '/users/$username/follow';

  // own profile images (multipart)
  static const String profileAvatar = '/profile/avatar';
  static const String profileCover = '/profile/cover';

  // edit profile form (name stays read-only here; bio/email/phone/social)
  static const String editProfile = '/profile/edit';

  // my profile (Videos / Favorite / Delete tabs — owner-only)
  static String myProfile(String userId) => '/profile/$userId';
  static String myProfilePosts(String userId) => '/profile/$userId/posts';
  static String myProfilePostFavorite(String userId, String postId) =>
      '/profile/$userId/posts/$postId/favorite';
  static String myProfilePost(String userId, String postId) =>
      '/profile/$userId/posts/$postId';

  // push notifications (Firebase Cloud Messaging device tokens)
  static const String deviceTokens = '/device-tokens';

  // private-channel auth for Reverb (websockets) — JWT-protected variant,
  // see routes/api.php for why this isn't Laravel's default endpoint.
  static const String broadcastingAuth = '/broadcasting/auth';

  // in-app notifications
  static const String notifications = '/notifications';
  static const String markAllNotificationsRead = '/notifications/read-all';
  static String markNotificationRead(String id) => '/notifications/$id/read';
  static String notification(String id) => '/notifications/$id';
  static const String markNotificationsRead = '/notifications/read';
  static const String notificationsBatch = '/notifications/batch';
}
