part of '../mm_scrollable_tabs.dart';

class MMScrollableTabsBar<T> extends StatefulWidget {
  const MMScrollableTabsBar({
    super.key,
    this.scrollController,
    required this.controller,
    required this.buildTabWidget,
  });

  final MMScrollableTabsController<T> controller;
  final ScrollController? scrollController;
  final Widget Function(
    MMScrollableTabsItem<T> tab,
    bool active,
  ) buildTabWidget;

  @override
  State<MMScrollableTabsBar<T>> createState() => _MMScrollableTabsBarState<T>();
}

class _MMScrollableTabsBarState<T> extends State<MMScrollableTabsBar<T>> {
  late final ScrollController tabScrollController;
  bool autoScrolling = false;
  MMScrollableTabsItem<T>? active;

  @override
  void initState() {
    tabScrollController = ScrollController();
    widget.controller._tabBarState = this;
    widget.scrollController?.addListener(contentScrollToTabScrollListener);

    super.initState();
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(contentScrollToTabScrollListener);
    tabScrollController.dispose();
    super.dispose();
  }

  void setActiveTab(MMScrollableTabsItem<T> active) {
    setState(() => this.active = active);
  }

  void contentScrollToTabScrollListener() {
    final maxContentOffset = widget.scrollController!.position.maxScrollExtent;
    final maxTabOffset = tabScrollController.position.maxScrollExtent;

    if (maxContentOffset < maxTabOffset) return;

    final contentOffset = widget.scrollController!.offset;

    // Map the content offset to the tab offset
    final tabOffset = maxTabOffset * (contentOffset / maxContentOffset);
    tabScrollController.jumpTo(tabOffset);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: tabScrollController,
      child: Row(
        children: widget.controller.tabs.map((tab) {
          return GestureDetector(
            onTap: () {
              widget.controller._autoScrollToTab(tab);
            },
            child: widget.buildTabWidget(tab, active?.key == tab.key),
          );
        }).toList(),
      ),
    );
  }
}
