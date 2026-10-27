import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/l10n/app_localizations.dart';
import 'package:khmer_cat_app/src/settings/presentation/terms_content.dart';
import 'package:khmer_cat_app/src/settings/presentation/widgets/menu_chrome.dart';
import 'package:url_launcher/url_launcher.dart';

/// Terms of Service, opened from the Menu screen's "Terms of Policy" card,
/// or from sign-up with [askToAccept]: Decline / Accept buttons that pop
/// with whether they accepted.
class TermsOfServiceScreen extends HookWidget {
  final bool askToAccept;
  const TermsOfServiceScreen({this.askToAccept = false, super.key});

  @override
  Widget build(BuildContext context) {
    final scroll = useScrollController();
    // Accept unlocks once they've scrolled to the end (and stays unlocked).
    final reachedEnd = useState(false);
    useEffect(() {
      if (!askToAccept) return null;
      void check() {
        if (reachedEnd.value || !scroll.hasClients) return;
        if (scroll.position.extentAfter < 40) reachedEnd.value = true;
      }

      scroll.addListener(check);
      // Content that already fits on screen counts as read.
      WidgetsBinding.instance.addPostFrameCallback((_) => check());
      return () => scroll.removeListener(check);
    }, [scroll, askToAccept]);

    final l = AppLocalizations.of(context);
    final primary = ProfileTheme.textPrimary(context);
    final secondary = ProfileTheme.textSecondary(context);
    final body = TextStyle(fontSize: 14, height: 1.5, color: primary);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: SoftCirclesBackdrop()),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                MenuTitleBar(title: l.termsOfService),
                Expanded(
                  child: ListView(
                    controller: scroll,
                    padding: EdgeInsets.fromLTRB(
                      12,
                      4,
                      12,
                      askToAccept
                          ? 20
                          : MediaQuery.paddingOf(context).bottom + 20,
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
                if (askToAccept) _AcceptBar(canAccept: reachedEnd.value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Decline (pops false) / Accept (pops true), pinned under the terms.
/// Accept stays greyed out until [canAccept] (scrolled to the end).
class _AcceptBar extends StatelessWidget {
  final bool canAccept;
  const _AcceptBar({required this.canAccept});

  @override
  Widget build(BuildContext context) {
    final primary = ProfileTheme.textPrimary(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: canAccept
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.keyboard_double_arrow_down_rounded,
                          size: 16,
                          color: ProfileTheme.textSecondary(context),
                        ),
                        const Gap(4),
                        Text(
                          'Scroll to the end to accept',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: ProfileTheme.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: primary,
                    side: BorderSide(color: primary.withValues(alpha: 0.2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Decline',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const Gap(10),
              Expanded(
                child: GestureDetector(
                  onTap: canAccept
                      ? () => Navigator.of(context).pop(true)
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: canAccept ? ProfileTheme.brandGradient : null,
                      color: canAccept ? null : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      'I Accept',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: canAccept
                            ? ProfileTheme.ink
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
