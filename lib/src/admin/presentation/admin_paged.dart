import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// A page of an admin list.
typedef AdminPageResult<T> = ({
  List<T> items,
  bool hasMore,
  Map<String, int> counts,
});

/// State for a paged admin list: the first page loads whenever [keys]
/// change, [loadMore] fetches the next, and a stale response (keys changed
/// meanwhile) is dropped.
class AdminPaged<T> {
  final List<T> items;
  final Map<String, int> counts;
  final bool loading;
  final bool failed;
  final bool hasMore;
  final Future<void> Function() reload;
  final Future<void> Function() loadMore;
  final void Function(bool Function(T) test) removeWhere;

  const AdminPaged({
    required this.items,
    required this.counts,
    required this.loading,
    required this.failed,
    required this.hasMore,
    required this.reload,
    required this.loadMore,
    required this.removeWhere,
  });

  bool get isEmptyLoading => items.isEmpty && loading;
}

AdminPaged<T> useAdminPaged<T>(
  Future<AdminPageResult<T>> Function(int page) fetch,
  List<Object?> keys,
) {
  final items = useState<List<T>>([]);
  final counts = useState<Map<String, int>>({});
  final page = useRef(0);
  final hasMore = useState(true);
  final loading = useState(false);
  final failed = useState(false);
  final seq = useRef(0);
  // Set once the widget is gone, so late responses are ignored.
  final disposed = useRef(false);
  useEffect(
    () =>
        () => disposed.value = true,
    [],
  );
  bool mounted() => !disposed.value;

  Future<void> load({required bool reset}) async {
    if (!reset && (loading.value || !hasMore.value)) return;
    final mine = reset ? ++seq.value : seq.value;
    loading.value = true;
    failed.value = false;
    final next = reset ? 1 : page.value + 1;
    try {
      final result = await fetch(next);
      if (!mounted() || mine != seq.value) return;
      page.value = next;
      items.value = reset ? result.items : [...items.value, ...result.items];
      counts.value = result.counts;
      hasMore.value = result.hasMore;
    } catch (_) {
      if (mounted() && mine == seq.value) failed.value = true;
    } finally {
      if (mounted() && mine == seq.value) loading.value = false;
    }
  }

  useEffect(() {
    items.value = [];
    hasMore.value = true;
    load(reset: true);
    return null;
  }, keys);

  return AdminPaged<T>(
    items: items.value,
    counts: counts.value,
    loading: loading.value,
    failed: failed.value,
    hasMore: hasMore.value,
    reload: () => load(reset: true),
    loadMore: () => load(reset: false),
    removeWhere: (test) => items.value = [
      for (final x in items.value)
        if (!test(x)) x,
    ],
  );
}

/// Calls [onEnd] as [controller] nears the bottom.
void useLoadMoreOnScroll(ScrollController controller, VoidCallback onEnd) {
  final callback = useRef(onEnd)..value = onEnd;
  useEffect(() {
    void listener() {
      if (controller.hasClients && controller.position.extentAfter < 400) {
        callback.value();
      }
    }

    controller.addListener(listener);
    return () => controller.removeListener(listener);
  }, [controller]);
}
