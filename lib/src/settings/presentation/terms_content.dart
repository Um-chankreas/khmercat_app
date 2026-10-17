// The KhmerCat Terms of Service text, as structured data so the screen can
// lay out headings, paragraphs and bullet lists. English only for now.

/// One piece of a section: a paragraph, or a bulleted list.
sealed class TermsBlock {
  const TermsBlock();
}

class TermsParagraph extends TermsBlock {
  final String text;
  const TermsParagraph(this.text);
}

class TermsBullets extends TermsBlock {
  final List<String> items;
  const TermsBullets(this.items);
}

class TermsSection {
  final String title;
  final List<TermsBlock> blocks;
  const TermsSection(this.title, this.blocks);
}

// TODO: set the real effective date before release.
const termsEffectiveDate = '[Date]';

const termsContactEmail = 'legal@khmercat.com';

const termsIntro = [
  'Welcome to KhmerCat.',
  'KhmerCat is a platform that helps users discover restaurants, cafés, bars, '
      'and food experiences through short-form video content, reviews, '
      'ratings, maps, and business profiles.',
  'By accessing or using KhmerCat, you agree to these Terms of Service '
      '(“Terms”). If you do not agree, do not use the Services.',
];

const termsSections = <TermsSection>[
  TermsSection('Who May Use KhmerCat', [
    TermsParagraph('You may use KhmerCat only if:'),
    TermsBullets([
      'You are at least 13 years old.',
      'You are legally capable of entering into a binding agreement.',
      'You comply with these Terms and all applicable laws.',
    ]),
    TermsParagraph(
      'If you are under 18 years old, you represent that your parent or legal '
      'guardian has reviewed and agreed to these Terms on your behalf.',
    ),
    TermsParagraph(
      'We may refuse access to or terminate accounts at our discretion.',
    ),
  ]),
  TermsSection('Your Account', [
    TermsParagraph(
      'You may need to create an account to access certain features.',
    ),
    TermsParagraph('You agree to:'),
    TermsBullets([
      'Provide accurate information.',
      'Keep your account credentials secure.',
      'Notify us of unauthorized use.',
      'Be responsible for activity occurring under your account.',
    ]),
    TermsParagraph('You may not:'),
    TermsBullets([
      'Create fake accounts.',
      'Impersonate any person or business.',
      'Buy, sell, or transfer accounts.',
      'Use bots, crawlers, or automated systems without permission.',
    ]),
  ]),
  TermsSection('Your Content', [
    TermsParagraph(
      'KhmerCat allows users to upload, create, post, and share content '
      'including:',
    ),
    TermsBullets([
      'Videos',
      'Photos',
      'Reviews',
      'Ratings',
      'Comments',
      'Business information',
      'Profile information',
    ]),
    TermsParagraph('You retain ownership of your content.'),
    TermsParagraph(
      'By posting content through the Services, you grant KhmerCat a '
      'worldwide, royalty-free, transferable, sublicensable, non-exclusive '
      'license to host, store, reproduce, display, distribute, modify, adapt, '
      'promote, and otherwise use that content in connection with operating, '
      'improving, marketing, and providing the Services.',
    ),
    TermsParagraph(
      'This license ends when your content is deleted, except where retention '
      'is reasonably necessary for legal, security, backup, or operational '
      'purposes.',
    ),
  ]),
  TermsSection('Content Restrictions', [
    TermsParagraph(
      'You may not upload, post, share, or transmit content that:',
    ),
    TermsBullets([
      'Violates Cambodian law.',
      'Infringes intellectual property rights.',
      'Contains false or misleading information.',
      'Constitutes harassment or abuse.',
      'Promotes violence or criminal activity.',
      'Contains malware or harmful code.',
      'Includes fake restaurant reviews.',
      'Manipulates ratings or rankings.',
      'Impersonates another individual or business.',
    ]),
    TermsParagraph('We reserve the right to remove content without notice.'),
  ]),
  TermsSection('Reviews and Ratings', [
    TermsParagraph(
      'KhmerCat provides review and rating tools to assist users in making '
      'dining decisions.',
    ),
    TermsParagraph('You agree that:'),
    TermsBullets([
      'Reviews reflect genuine experiences.',
      'Ratings are submitted honestly.',
      'Reviews are not exchanged for undisclosed compensation.',
    ]),
    TermsParagraph(
      'KhmerCat does not verify every review and makes no guarantee regarding '
      'the accuracy of user-generated content.',
    ),
    TermsParagraph('We may remove reviews or ratings at our discretion.'),
  ]),
  TermsSection('Business Profiles', [
    TermsParagraph(
      'Restaurants and businesses may create profiles on KhmerCat.',
    ),
    TermsParagraph('Businesses are solely responsible for:'),
    TermsBullets([
      'Menu information.',
      'Pricing.',
      'Promotions.',
      'Contact information.',
      'Operating hours.',
      'Uploaded content.',
    ]),
    TermsParagraph(
      'KhmerCat does not guarantee the accuracy of information provided by '
      'businesses.',
    ),
  ]),
  TermsSection('Sponsored Content and Advertising', [
    TermsParagraph(
      'KhmerCat may display sponsored content, advertisements, and promoted '
      'businesses.',
    ),
    TermsParagraph(
      'Businesses may pay for increased visibility within the Services.',
    ),
    TermsParagraph(
      'Sponsored placement does not constitute an endorsement by KhmerCat.',
    ),
    TermsParagraph(
      'KhmerCat does not guarantee any level of customer traffic, engagement, '
      'revenue, or business performance.',
    ),
  ]),
  TermsSection('Intellectual Property', [
    TermsParagraph(
      'The Services, including software, features, branding, logos, designs, '
      'and technology, are owned by KhmerCat or its licensors and are '
      'protected by applicable intellectual property laws.',
    ),
    TermsParagraph('You may not:'),
    TermsBullets([
      'Copy',
      'Modify',
      'Reverse engineer',
      'Distribute',
      'Sell',
      'Lease',
    ]),
    TermsParagraph(
      'any part of the Services except as expressly permitted by law.',
    ),
  ]),
  TermsSection('Platform Enforcement', [
    TermsParagraph('To protect users and businesses, KhmerCat may:'),
    TermsBullets([
      'Remove content.',
      'Restrict visibility.',
      'Suspend accounts.',
      'Terminate accounts.',
      'Investigate violations.',
    ]),
    TermsParagraph(
      'We reserve the right to take action whenever we reasonably believe '
      'conduct violates these Terms or harms the Services.',
    ),
  ]),
  TermsSection('Location-Based Features', [
    TermsParagraph(
      'KhmerCat uses location information to provide restaurant '
      'recommendations, map functionality, search results, and other '
      'location-based features.',
    ),
    TermsParagraph(
      'You may disable location permissions through your device settings, '
      'though certain features may become unavailable.',
    ),
  ]),
  TermsSection('Third-Party Services', [
    TermsParagraph(
      'The Services may contain links to or integrations with third-party '
      'providers, including mapping, hosting, analytics, payment, and '
      'communication services.',
    ),
    TermsParagraph(
      'KhmerCat is not responsible for third-party services, products, '
      'content, or practices.',
    ),
    TermsParagraph(
      'Your use of third-party services may be governed by separate '
      'agreements.',
    ),
  ]),
  TermsSection('Disclaimers', [
    TermsParagraph('THE SERVICES ARE PROVIDED “AS IS” AND “AS AVAILABLE.”'),
    TermsParagraph(
      'TO THE MAXIMUM EXTENT PERMITTED BY LAW, KHMERCAT DISCLAIMS ALL '
      'WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WARRANTIES OF '
      'MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, NON-INFRINGEMENT, '
      'ACCURACY, AND AVAILABILITY.',
    ),
    TermsParagraph('KHMERCAT DOES NOT GUARANTEE:'),
    TermsBullets([
      'Restaurant quality.',
      'Food safety.',
      'Business legitimacy.',
      'Review accuracy.',
      'Continuous platform availability.',
    ]),
  ]),
  TermsSection('Limitation of Liability', [
    TermsParagraph(
      'TO THE MAXIMUM EXTENT PERMITTED BY LAW, KHMERCAT SHALL NOT BE LIABLE '
      'FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, EXEMPLARY, OR '
      'PUNITIVE DAMAGES.',
    ),
    TermsParagraph('THIS INCLUDES DAMAGES RELATED TO:'),
    TermsBullets([
      'FOODBORNE ILLNESS',
      'ALLERGIC REACTIONS',
      'BUSINESS LOSSES',
      'LOST PROFITS',
      'REPUTATIONAL HARM',
      'USER DISPUTES',
      'DATA LOSS',
      'SERVICE INTERRUPTIONS',
    ]),
    TermsParagraph(
      'IN NO EVENT SHALL KHMERCAT’S TOTAL LIABILITY EXCEED THE GREATER OF:',
    ),
    TermsParagraph('(A) USD \$100; OR'),
    TermsParagraph(
      '(B) THE AMOUNT PAID BY YOU TO KHMERCAT DURING THE TWELVE MONTHS '
      'PRECEDING THE CLAIM.',
    ),
  ]),
  TermsSection('Indemnification', [
    TermsParagraph(
      'You agree to defend, indemnify, and hold harmless KhmerCat, its '
      'officers, employees, contractors, affiliates, and partners from '
      'claims, damages, liabilities, and expenses arising from:',
    ),
    TermsBullets([
      'Your use of the Services.',
      'Your content.',
      'Your violation of these Terms.',
      'Your violation of applicable laws.',
    ]),
  ]),
  TermsSection('Suspension and Termination', [
    TermsParagraph(
      'We may suspend or terminate access to the Services at any time, with '
      'or without notice.',
    ),
    TermsParagraph(
      'Upon termination, rights granted to you under these Terms immediately '
      'cease.',
    ),
  ]),
  TermsSection('Governing Law', [
    TermsParagraph(
      'These Terms are governed by the laws of the Kingdom of Cambodia.',
    ),
    TermsParagraph(
      'Any dispute arising out of or relating to these Terms shall be '
      'submitted to the competent courts of Cambodia.',
    ),
  ]),
  TermsSection('Changes to These Terms', [
    TermsParagraph('We may revise these Terms from time to time.'),
    TermsParagraph(
      'If we make material changes, we may provide notice through the '
      'Services.',
    ),
    TermsParagraph(
      'Your continued use of KhmerCat following any update constitutes '
      'acceptance of the revised Terms.',
    ),
  ]),
];
