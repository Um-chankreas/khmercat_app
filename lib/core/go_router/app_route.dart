class AppRoute {
  final String name;
  final String path;
  AppRoute({required this.name, required this.path});
  static AppRoute splash = AppRoute(name: 'splash', path: '/');
  static AppRoute welcome = AppRoute(
    name: 'welcome-screen',
    path: '/welcome-screen',
  );
  static AppRoute home = AppRoute(name: 'home', path: '/');
  static AppRoute index = AppRoute(name: '/index', path: '/index');

  // upload
  static AppRoute cameraRecord = AppRoute(
    name: 'camera-record-screen',
    path: 'camera-record-screen',
  );

  // auth
  static AppRoute login = AppRoute(name: 'login', path: 'login');
  static AppRoute verifyCode = AppRoute(
    name: 'verify-code',
    path: 'verify-code',
  );
  static AppRoute createAccount = AppRoute(
    name: 'create-account',
    path: 'create-account',
  );

  // onboading
  static AppRoute onboadingRestaurant = AppRoute(
    name: '/onboading-restaurant',
    path: '/onboading-restaurant',
  );

  // onboading
  static AppRoute onboadingNormalUser = AppRoute(
    name: '/onboading-user',
    path: '/onboading-user',
  );
  static AppRoute createRestaurant = AppRoute(
    name: '/create-restaurant',
    path: '/create-restaurant',
  );
  static AppRoute memberinfo = AppRoute(
    name: 'member-info',
    path: '/member-info',
  );
  static AppRoute settings = AppRoute(name: 'settings', path: '/settings');
  static AppRoute editProfile = AppRoute(
    name: 'edit-profile',
    path: '/edit-profile',
  );

  // profiles / video viewer — pushed from the feed, search, or a video grid
  static AppRoute restaurantProfile = AppRoute(
    name: 'restaurant-profile',
    path: '/restaurants/:id',
  );
  static AppRoute userProfile = AppRoute(
    name: 'user-profile',
    path: '/users/:username',
  );
  static AppRoute videoViewer = AppRoute(
    name: 'video-viewer',
    path: '/videos/:id',
  );
}
