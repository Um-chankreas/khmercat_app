import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:khmer_cat_app/core/components/profile/profile_theme.dart';
import 'package:khmer_cat_app/core/network/api_client.dart';
import 'package:khmer_cat_app/core/network/api_exception.dart';
import 'package:khmer_cat_app/core/network/api_route.dart';
import 'package:khmer_cat_app/core/service/app_service.dart';

/// What can be reported, in the order shown: (API value, label).
const reportReasons = [
  ('sexual', 'Sexual content'),
  ('hate_harassment', 'Hate and harassment'),
  ('violence', 'Violence or abuse'),
  ('child_safety', 'Child safety'),
  ('misleading', 'False or misleading information'),
  ('ai_content', 'Problematic AI content'),
  ('self_harm', 'Suicide and self-harm'),
  ('branded', 'Undisclosed branded content'),
  ('spam', 'Spam or scam'),
  ('copyright', 'Copyright or someone else\'s content'),
  ('other', 'Something else'),
];

const _accent = Color(0xffB0125A);

/// Opens the report flow for [videoId]: pick a reason → add details →
/// thanks.
void openReportFlow(BuildContext context, ApiClient client, String videoId) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _ReasonScreen(client: client, videoId: videoId),
    ),
  );
}

Color _card(BuildContext context) =>
    ProfileTheme.textPrimary(context).withValues(alpha: 0.04);

/// "Why are you reporting this?" — the anonymity note and the reasons.
class _ReasonScreen extends StatelessWidget {
  final ApiClient client;
  final String videoId;
  const _ReasonScreen({required this.client, required this.videoId});

  @override
  Widget build(BuildContext context) {
    final primary = ProfileTheme.textPrimary(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          4,
          16,
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          Text(
            'Why are you reporting this?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: primary,
            ),
          ),
          const Gap(22),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
            decoration: BoxDecoration(
              color: const Color(0xff2F80ED).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.shield_rounded,
                  size: 22,
                  color: Color(0xff2F6FD0),
                ),
                const Gap(12),
                Expanded(
                  child: Text(
                    'Your report stays anonymous to others, and our team '
                    'reviews every report against our guidelines.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      color: ProfileTheme.textSecondary(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Gap(12),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: _card(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                for (final (value, label) in reportReasons)
                  InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => _DetailsScreen(
                          client: client,
                          videoId: videoId,
                          reason: value,
                          label: label,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: primary,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: ProfileTheme.textSecondary(context),
                          ),
                        ],
                      ),
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

/// The chosen reason, an optional note, and Submit.
class _DetailsScreen extends StatefulWidget {
  final ApiClient client;
  final String videoId;
  final String reason;
  final String label;
  const _DetailsScreen({
    required this.client,
    required this.videoId,
    required this.reason,
    required this.label,
  });

  @override
  State<_DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<_DetailsScreen> {
  final _note = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sending) return;
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    try {
      await widget.client.post(
        ApiRoute.videoReport(widget.videoId),
        body: {
          'reason': widget.reason,
          if (_note.text.trim().isNotEmpty) 'note': _note.text.trim(),
        },
      );
      if (!mounted) return;
      HapticFeedback.lightImpact();
      // Replaces the whole flow, so Done goes straight back to the video.
      Navigator.of(context)
        ..pop()
        ..pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const _ThanksScreen()),
        );
    } on ApiException catch (e) {
      if (mounted) setState(() => _sending = false);
      AppService.showToast(e.message, isError: true);
    } catch (_) {
      if (mounted) setState(() => _sending = false);
      AppService.showToast('Could not send the report.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = ProfileTheme.textPrimary(context);
    final muted = ProfileTheme.textSecondary(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: primary,
                  ),
                ),
                const Gap(8),
                Text(
                  'Tell us more if it helps us understand (optional).',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.5, color: muted),
                ),
                const Gap(20),
                TextField(
                  controller: _note,
                  maxLength: 500,
                  minLines: 4,
                  maxLines: 8,
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                  decoration: InputDecoration(
                    hintText: 'Add details',
                    filled: true,
                    fillColor: _card(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.paddingOf(context).bottom + 16,
            ),
            child: _BigButton(
              text: 'Submit',
              loading: _sending,
              onTap: _submit,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Thanks for reporting" with a check and Done.
class _ThanksScreen extends StatelessWidget {
  const _ThanksScreen();

  @override
  Widget build(BuildContext context) {
    final primary = ProfileTheme.textPrimary(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: Icon(Icons.close_rounded, color: primary),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          8,
          24,
          MediaQuery.paddingOf(context).bottom + 16,
        ),
        child: Column(
          children: [
            const Gap(12),
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xff1DCB8B),
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
            const Gap(20),
            Text(
              'Thanks for reporting',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: primary,
              ),
            ),
            const Gap(10),
            Text(
              'We\'ll review your report and take action if it breaks our '
              'community guidelines.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.5,
                height: 1.4,
                color: ProfileTheme.textSecondary(context),
              ),
            ),
            const Spacer(),
            _BigButton(text: 'Done', onTap: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  final String text;
  final bool loading;
  final VoidCallback onTap;
  const _BigButton({
    required this.text,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _accent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
