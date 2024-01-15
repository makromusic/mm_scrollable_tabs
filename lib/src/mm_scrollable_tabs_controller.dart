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

typedef MMScrollableTabsControllerListener<T> = void Function(
  MMScrollableTabsItem<T> tab,
);

class MMScrollableTabsController<T> {
  MMScrollableTabsController({
    required this.tabs,
  })  : assert(tabs.isNotEmpty),
        assert(tabs.map((e) => e.key).toSet().length == tabs.length);

  final List<MMScrollableTabsItem<T>> tabs;

  final List<MMScrollableTabsControllerListener<T>> _listeners = [];
  _MMScrollableTabsBarState? _tabBarState;
  _MMNestedScrollableTabsBodyState? _bodyState;

  void addListener(MMScrollableTabsControllerListener<T> listener) {
    _checkDisposed();
    _listeners.add(listener);
  }

  void removeListener(MMScrollableTabsControllerListener<T> listener) {
    _checkDisposed();
    _listeners.remove(listener);
  }

  void _notifyListeners(MMScrollableTabsItem<T> tab) {
    _checkDisposed();
    for (final listener in _listeners) {
      listener(tab);
    }
  }

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

  void dispose() {
    if (!_disposed) {
      _disposed = true;
      // dispose global keys
      this._bodyState = null;
      this._tabBarState = null;
    }
  }
}
