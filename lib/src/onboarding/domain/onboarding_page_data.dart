// lib/features/onboarding/domain/onboarding_page_data.dart

import 'package:flutter/material.dart';

/// A small floating label beside the phones, e.g. "4.8 rating".
class OnboardingBadge {
  final IconData icon;
  final String label;
  const OnboardingBadge(this.icon, this.label);
}

class OnboardingPageData {
  /// Illustration, shown as-is. Ignored when [screenshots] is set.
  final String? imagePath;

  /// Real app screenshots, shown in phone frames: the first in front, a
  /// second (optional) tilted behind it.
  final List<String> screenshots;
  final String title;
  final String description;

  /// Up to two badges floating around the visual (top-left, bottom-right).
  final List<OnboardingBadge> badges;

  const OnboardingPageData({
    this.imagePath,
    this.screenshots = const [],
    this.badges = const [],
    required this.title,
    required this.description,
  }) : assert(imagePath != null || screenshots != const <String>[]);
}

const onboardingPagesRestaurant = [
  OnboardingPageData(
    screenshots: ['assets/onboarding/switch_account.jpg'],
    title: 'Create Your Restaurant',
    badges: [
      OnboardingBadge(Icons.storefront_rounded, 'Live in minutes'),
      OnboardingBadge(Icons.swap_horiz_rounded, 'Switch anytime'),
    ],
    description:
        'Start by creating your restaurant profile. It only takes a few minutes to set up your business and begin reaching more customers.',
  ),
  OnboardingPageData(
    screenshots: [
      'assets/onboarding/restaurant_videos.jpg',
      'assets/onboarding/restaurant_info.jpg',
    ],
    title: 'Build Your Restaurant Profile',
    badges: [
      OnboardingBadge(Icons.star_rounded, '4.8 rating'),
      OnboardingBadge(Icons.restaurant_menu_rounded, 'Menu & hours'),
    ],
    description:
        'Add your restaurant logo, name, description, location, contact information, opening hours, menu, and cover photo to help customers discover and trust your business.',
  ),
  OnboardingPageData(
    screenshots: [
      'assets/onboarding/new_post.jpg',
      'assets/onboarding/restaurant_reviews.jpg',
    ],
    title: 'Share Videos & Attract Customers',
    badges: [
      OnboardingBadge(Icons.play_circle_fill_rounded, 'Video posts'),
      OnboardingBadge(Icons.favorite_rounded, 'More customers'),
    ],
    description:
        'Upload video reviews, food showcases, promotional videos, or behind-the-scenes content to attract more customers and increase engagement with your restaurant.',
  ),
];
const onboardingPagesUser = [
  OnboardingPageData(
    screenshots: [
      'assets/onboarding/restaurant_videos.jpg',
      'assets/onboarding/switch_account.jpg',
    ],
    title: 'Create Your Profile',
    badges: [
      OnboardingBadge(Icons.person_rounded, 'Your profile'),
      OnboardingBadge(Icons.photo_camera_rounded, 'Photo & bio'),
    ],
    description:
        'Personalize your account by adding a profile photo, your name, and a short bio. A complete profile helps you connect with the community and share your food experiences.',
  ),
  OnboardingPageData(
    screenshots: [
      'assets/onboarding/restaurant_info.jpg',
      'assets/onboarding/restaurant_reviews.jpg',
    ],
    title: 'Explore Restaurant Near You',
    badges: [
      OnboardingBadge(Icons.location_on_rounded, 'Nearby spots'),
      OnboardingBadge(Icons.local_fire_department_rounded, 'Trending'),
    ],
    description:
        'Browse restaurants, discover trending places, explore menus, and save your favorite restaurants for future visits.',
  ),
  OnboardingPageData(
    screenshots: [
      'assets/onboarding/new_post.jpg',
      'assets/onboarding/restaurant_videos.jpg',
    ],
    title: 'Review & Share Moments',
    badges: [
      OnboardingBadge(Icons.star_rounded, 'Rate & review'),
      OnboardingBadge(Icons.videocam_rounded, 'Share videos'),
    ],
    description:
        'Upload text reviews, rate restaurants, and share videos of your dining experiences to help others discover great places to eat.',
  ),
];
