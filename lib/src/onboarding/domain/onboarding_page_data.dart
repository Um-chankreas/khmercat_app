// lib/features/onboarding/domain/onboarding_page_data.dart

class OnboardingPageData {
  final String imagePath;
  final String title;
  final String description;

  const OnboardingPageData({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}

const onboardingPagesRestaurant = [
  OnboardingPageData(
    imagePath: 'assets/images/onboarding_create_restaurant.png',
    title: 'Create Your Restaurant',
    description:
        'Start by creating your restaurant profile. It only takes a few minutes to set up your business and begin reaching more customers.',
  ),
  OnboardingPageData(
    imagePath: 'assets/images/onboarding_build_profile.png',
    title: 'Build Your Restaurant Profile',
    description:
        'Add your restaurant logo, name, description, location, contact information, opening hours, menu, and cover photo to help customers discover and trust your business.',
  ),
  OnboardingPageData(
    imagePath: 'assets/images/onboarding_share_videos.png',
    title: 'Share Videos & Attract Customers',
    description:
        'Upload video reviews, food showcases, promotional videos, or behind-the-scenes content to attract more customers and increase engagement with your restaurant.',
  ),
];
const onboardingPagesUser = [
  OnboardingPageData(
    imagePath: 'assets/images/onboarding_create_user.png',
    title: 'Create Your Profile',
    description:
        'Personalize your account by adding a profile photo, your name, and a short bio. A complete profile helps you connect with the community and share your food experiences.',
  ),
  OnboardingPageData(
    imagePath: 'assets/images/onboarding_build_profile_search.png',
    title: 'Explore Restaurant Near You',
    description:
        'Browse restaurants, discover trending places, explore menus, and save your favorite restaurants for future visits.',
  ),
  OnboardingPageData(
    imagePath: 'assets/images/onboarding_share_user.png',
    title: 'Review & Share Moments',
    description:
        'Upload text reviews, rate restaurants, and share videos of your dining experiences to help others discover great places to eat.',
  ),
];
