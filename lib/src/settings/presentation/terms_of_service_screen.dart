import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/l10n/app_localizations.dart';
import 'package:khmer_cat_app/src/settings/presentation/terms_content.dart';
import 'package:khmer_cat_app/src/settings/presentation/widgets/menu_chrome.dart';
import 'package:url_launcher/url_launcher.dart';

/// Terms of Service, opened from the Menu screen's "Terms of Policy" card.
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final primary = ProfileTheme.textPrimary(context);
    final secondary = ProfileTheme.textSecondary(context);
    final body = TextStyle(fontSize: 14, height: 1.5, color: primary);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: MenuBackdrop()),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                MenuTitleBar(title: l.termsOfService),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      12,
                      4,
                      12,
                      MediaQuery.paddingOf(context).bottom + 20,
                    ),
                    children: [
                      MenuCard(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'KhmerCat Terms of Service',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                    color: primary,
                                  ),
                                ),
                                const Gap(4),
                                Text(
                                  'Effective Date: $termsEffectiveDate',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: secondary,
                                  ),
                                ),
                                const Gap(14),
                                for (final p in termsIntro) ...[
                                  Text(p, style: body),
                                  const Gap(10),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      for (var i = 0; i < termsSections.length; i++) ...[
                        const Gap(12),
                        _SectionCard(
                          number: i + 1,
                          section: termsSections[i],
                          bodyStyle: body,
                        ),
                      ],
                      const Gap(12),
                      _ContactCard(
                        number: termsSections.length + 1,
                        bodyStyle: body,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final int number;
  final String title;
  const _SectionHeading({required this.number, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$number. $title',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
        color: ProfileTheme.textPrimary(context),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final int number;
  final TermsSection section;
  final TextStyle bodyStyle;
  const _SectionCard({
    required this.number,
    required this.section,
    required this.bodyStyle,
  });

  @override
  Widget build(BuildContext context) {
    return MenuCard(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeading(number: number, title: section.title),
              const Gap(10),
              for (final block in section.blocks) ...[
                switch (block) {
                  TermsParagraph(:final text) => Text(text, style: bodyStyle),
                  TermsBullets(:final items) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final item in items)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('•  ', style: bodyStyle),
                              Expanded(child: Text(item, style: bodyStyle)),
                            ],
                          ),
                        ),
                    ],
                  ),
                },
                const Gap(8),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  final int number;
  final TextStyle bodyStyle;
  const _ContactCard({required this.number, required this.bodyStyle});

  @override
  Widget build(BuildContext context) {
    return MenuCard(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeading(number: number, title: 'Contact Us'),
              const Gap(10),
              Text('KhmerCat\nPhnom Penh, Cambodia', style: bodyStyle),
              const Gap(4),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    launchUrl(Uri(scheme: 'mailto', path: termsContactEmail)),
                child: Text.rich(
                  TextSpan(
                    text: 'Email: ',
                    style: bodyStyle,
                    children: const [
                      TextSpan(
                        text: termsContactEmail,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: menuAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
