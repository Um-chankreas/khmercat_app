import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khmer_cat_app/core/network/network_provider.dart';

import '../data/comments_remote_datasource.dart';

final commentsRemoteDataSourceProvider = Provider<CommentsRemoteDataSource>((
  ref,
) {
  return CommentsRemoteDataSource(ref.watch(apiClientProvider));
});
