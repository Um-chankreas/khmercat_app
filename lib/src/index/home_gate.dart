import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khmer_cat_app/src/admin/presentation/admin_shell.dart';
import 'package:khmer_cat_app/src/auth/presentation/viewmodel/auth_controller.dart';
import 'package:khmer_cat_app/src/index/index_screen.dart';

/// The app's home: an admin account gets only the admin area, as its own
/// app; everyone else (signed in or not) the normal tabs.
class HomeGate extends ConsumerWidget {
  const HomeGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(
      currentUserProvider.select((u) => u?.isAdmin ?? false),
    );
    return isAdmin ? const AdminShell(isRoot: true) : const IndexScreen();
  }
}
