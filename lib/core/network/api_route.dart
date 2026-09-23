abstract class ApiRoute {
  // auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String register = '/auth/register';
  static const String verifyEmail = '/auth/verify-email';
  static const String resendOTP = '/auth/resend-otp';
  static const String refreshToken = '/auth/refresh-token';
  static const String getUserAccount = '/auth/get-user-account';

  // feed / videos
  static const String videosFeed = '/videos/feed';
  static String videoLike(String id) => '/videos/$id/like';
  static String videoSave(String id) => '/videos/$id/save';
  static String videoComments(String id) => '/videos/$id/comments';
  static String comment(String id) => '/comments/$id';
  static String commentLike(String id) => '/comments/$id/like';

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
}
