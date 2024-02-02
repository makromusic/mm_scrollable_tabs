part of '../mm_scrollable_tabs.dart';

class MMScrollableTabsBar<T> extends StatefulWidget {
  const MMScrollableTabsBar({
    super.key,
    required this.controller,
    required this.buildTabWidget,
    this.firstItemLeftPadding = 0,
    this.lastItemRightPadding = 0,
  });

  final MMScrollableTabsController<T> controller;
  final double firstItemLeftPadding;
  final double lastItemRightPadding;
  final Widget Function(T key, bool active) buildTabWidget;

  @override
  State<MMScrollableTabsBar<T>> createState() => _MMScrollableTabsBarState<T>();
}

class _MMScrollableTabsBarState<T> extends State<MMScrollableTabsBar<T>>
    with WidgetsBindingObserver {
  late final ScrollController tabScrollController;
  bool autoScrolling = false;
  MMScrollableTabsItem<T>? active;
  NestedScrollViewState? nestedScrollViewState;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    tabScrollController = ScrollController();
    widget.controller._tabBarState = this;
    nestedScrollViewState =
        context.findAncestorStateOfType<NestedScrollViewState>();
    nestedScrollViewState?.innerController.addListener(
      contentScrollToTabScrollListener,
    );

    active = widget.controller.tabs.firstOrNull;
    if (widget.controller._bodyState != null) {
      //* It means that this code block is only executed if the body state is already initialized (while changing the parent tab bar)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (active != null) {
          widget.controller._autoScrollToTab(active!);
        }
      });
    }

    super.initState();
  }

  @override
  void dispose() {
    nestedScrollViewState?.innerController.removeListener(
      contentScrollToTabScrollListener,
    );
    tabScrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void setActiveTab(MMScrollableTabsItem<T> active) {
    if (!mounted) return;
    setState(() => this.active = active);
  }

  void contentScrollToTabScrollListener() {
    final scrollController = nestedScrollViewState!.innerController;
    if (scrollController.positions.length != 1) return;

    final maxContentOffset = scrollController.position.maxScrollExtent;
    final maxTabOffset = tabScrollController.position.maxScrollExtent;

    if (maxContentOffset < maxTabOffset) return;

    final contentOffset = scrollController.offset;

    // Map the content offset to the tab offset
    final tabOffset = maxTabOffset * (contentOffset / maxContentOffset);
    tabScrollController.jumpTo(tabOffset);
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    children.add(SizedBox(width: widget.firstItemLeftPadding));
    children.addAll(widget.controller.tabs.map((tab) {
      return GestureDetector(
        onTap: () => widget.controller._autoScrollToTab(tab),
        child: widget.buildTabWidget(tab.key, active?.key == tab.key),
      );
    }).toList());
    children.add(SizedBox(width: widget.lastItemRightPadding));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: tabScrollController,
      child: Row(children: children),
    );
  }
}
