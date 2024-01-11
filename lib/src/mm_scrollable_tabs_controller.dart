part of '../mm_scrollable_tabs.dart';

class MMScrollableTabsItem<T> {
  MMScrollableTabsItem({
    required this.label,
    required this.key,
  }) : globalKey = GlobalKey();

  final T key;
  final String label;
  final GlobalKey globalKey;

  @override
  String toString() => 'MMScrollableTabsItem(label: $label, key: $key)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MMScrollableTabsItem<T> &&
        other.label == label &&
        other.key == key &&
        other.globalKey == globalKey;
  }

  @override
  int get hashCode => label.hashCode ^ key.hashCode ^ globalKey.hashCode;
}

class MMScrollableTabsController<T> extends ChangeNotifier {
  MMScrollableTabsController({
    required this.tabs,
    required this.onTabActive,
  })  : assert(tabs.isNotEmpty),
        assert(tabs.map((e) => e.key).toSet().length == tabs.length);

  final List<MMScrollableTabsItem<T>> tabs;
  final void Function(MMScrollableTabsItem<T> tab)? onTabActive;

  _MMScrollableTabsBarState? _tabBarState;
  _MMNestedScrollableTabsBodyState? _bodyState;

  void _autoScrollToTab(MMScrollableTabsItem<T> tab) {
    _checkDisposed();
    _bodyState?.autoAnimateToTab(tab);
  }

  void _setActiveTabForTabBar(MMScrollableTabsItem<T> tab) {
    _checkDisposed();
    _tabBarState?.setActiveTab(tab);
  }

  bool _disposed = false;

  void _checkDisposed() {
    if (_disposed) {
      throw Exception('MMScrollableTabsController is disposed');
    }
  }

  @override
  void dispose() {
    if (!_disposed) {
      _disposed = true;
      // dispose global keys
      this._bodyState = null;
      this._tabBarState = null;
      super.dispose();
    }
  }
}
