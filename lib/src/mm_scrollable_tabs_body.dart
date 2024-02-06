part of '../mm_scrollable_tabs.dart';

class MMNestedScrollableTabsBody<T> extends StatefulWidget {
  const MMNestedScrollableTabsBody({
    super.key,
    required this.controller,
    required this.buildContentWidget,
    this.pinnedToolbarHeight = 0.0,
    this.physics,
    this.curve = Curves.easeOut,
    this.duration = const Duration(milliseconds: 500),
  });

  final MMScrollableTabsController<T> controller;
  final ScrollPhysics? physics;
  final double pinnedToolbarHeight;
  final Curve curve;
  final Duration duration;
  final Widget? Function(T key, bool active) buildContentWidget;

  @override
  State<MMNestedScrollableTabsBody> createState() =>
      _MMNestedScrollableTabsBodyState<T>();
}

class _MMNestedScrollableTabsBodyState<T>
    extends State<MMNestedScrollableTabsBody<T>> with WidgetsBindingObserver {
  double? lastContentHeight;
  bool autoScrolling = false;
  bool innerScrolling = false;

  MMScrollableTabsItem<T>? active;
  NestedScrollViewState? nestedScrollViewState;

  @override
  void initState() {
    widget.controller._bodyState = this;

    nestedScrollViewState =
        context.findAncestorStateOfType<NestedScrollViewState>();

    nestedScrollViewState?.innerController.addListener(
      activeTabListener,
    );
    nestedScrollViewState?.innerController.addListener(
      activeTabListener,
    );

    nestedScrollViewState?.outerController.addListener(
      _innerScrollingListener,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      calculateLastContentHeight();
      activeTabListener();
    });

    super.initState();
  }

  @override
  void dispose() {
    nestedScrollViewState?.innerController.removeListener(
      activeTabListener,
    );
    nestedScrollViewState?.outerController.removeListener(
      activeTabListener,
    );
    super.dispose();
  }

  void _innerScrollingListener() {
    setState(() => innerScrolling = true);
  }

  void calculateLastContentHeight() {
    if (widget.controller.tabs.isEmpty) return;
    final renderBox = widget.controller.tabs.last._globalKey.currentContext
        ?.findRenderObject() as RenderBox?;
    final height = renderBox?.size.height;
    if (height != null) {
      if (!mounted) return;
      setState(() => lastContentHeight = height);
    }
  }

  double? findTopOffset(GlobalKey key) {
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    final position = renderBox?.localToGlobal(Offset.zero);
    return position?.dy;
  }

  void autoAnimateToTab(MMScrollableTabsItem<T> tab) {
    return;
    assert(widget.controller.tabs.isNotEmpty);

    if (!mounted) return;
    if (nestedScrollViewState == null) return;

    final topOffsets = calculateOffsets();
    if (topOffsets[tab] == null) return;

    setState(() => autoScrolling = true);

    final minTopOffset = topOffsets.values.reduce(min);
    final normalizedOffset = topOffsets[tab]! - minTopOffset;
    final offset = normalizedOffset - widget.pinnedToolbarHeight;

    if (offset >= 0) {
      nestedScrollViewState!.innerController
          .animateTo(
        offset,
        duration: widget.duration,
        curve: widget.curve,
      )
          .then(
        (_) {
          if (!mounted) return;
          setState(() => autoScrolling = false);
          widget.controller._notifyListeners(tab);
        },
      );
    } else {
      final maxOuterOffset =
          nestedScrollViewState!.outerController.position.maxScrollExtent;
      nestedScrollViewState!.outerController
          .animateTo(
        maxOuterOffset + normalizedOffset - widget.pinnedToolbarHeight,
        duration: widget.duration,
        curve: widget.curve,
      )
          .then(
        (_) {
          if (!mounted) return;
          setState(() => autoScrolling = false);
          widget.controller._notifyListeners(tab);
        },
      );
    }
  }

  void activeTabListener() {
    //* Calculate the offsets
    final topOffsets = calculateOffsets();

    MMScrollableTabsItem<T>? closestTab;
    double minOffset = 9999;

    topOffsets.forEach((key, value) {
      final v = (value - widget.pinnedToolbarHeight).abs();
      if (v < minOffset) {
        minOffset = v;
        closestTab = key;
      }
    });

    if (closestTab == null) return;

    if (!mounted) return;
    setState(() => active = closestTab);
    widget.controller._setActiveTabForTabBar(closestTab!);
    if (!autoScrolling) {
      widget.controller._notifyListeners(closestTab!);
    }
  }

  Map<MMScrollableTabsItem<T>, double> calculateOffsets() {
    if (widget.controller.tabs.isEmpty) return {};
    final topOffsets = <MMScrollableTabsItem<T>, double>{};
    for (final tab in widget.controller.tabs) {
      final offset = findTopOffset(tab._globalKey);
      if (offset == null) continue;
      topOffsets[tab] = offset;
    }
    return topOffsets;
  }

  static const kTabBarHeight = 56.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final slivers = widget.controller.tabs.map((tab) {
          Widget? child = widget.buildContentWidget(
            tab.key,
            active?._globalKey == tab._globalKey,
          );

          child ??= const SizedBox();

          return SizedBox(key: tab._globalKey, child: child);
        }).toList();

        final height = constraints.maxHeight -
            (lastContentHeight ?? 0) -
            widget.pinnedToolbarHeight -
            kTabBarHeight;

        if (height > 0) {
          slivers.add(SizedBox(height: height));
        }
        dev.log('pinning toolbar height: ${widget.pinnedToolbarHeight}');
        dev.log('innerScrolling: ${innerScrolling}');
        return Padding(
          padding: EdgeInsets.only(top: 0),
          // innerScrolling ? widget.pinnedToolbarHeight :
          child: CustomScrollView(
            physics: widget.physics,
            slivers: [
              SliverOverlapInjector(
                handle:
                    NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              ),
              SliverStickyHeader(
                header: MMScrollableTabsBar(
                  controller: widget.controller,
                  firstItemLeftPadding: 12,
                  lastItemRightPadding: 12,
                  buildTabWidget: (key, active) {
                    final String label = "labeeell";

                    return Container(
                      height: kTabBarHeight,
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      margin: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                          color: active ? Colors.red : Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: active ? Colors.blue : Colors.red,
                          )),
                      child: Center(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate.fixed(
                    slivers,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Delegate extends SliverPersistentHeaderDelegate {
  const _Delegate(
    this.backgroundColor,
    this.child,
    this.context,
    this.headerHeight,
    this.showShadow,
  );

  final Color backgroundColor;
  final Widget child;
  final BuildContext context;
  final double headerHeight;
  final bool showShadow;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  offset: const Offset(0, 2),
                  blurRadius: 10,
                  color: Colors.black.withOpacity(0.07),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }

  @override
  double get maxExtent => headerHeight;

  @override
  double get minExtent => headerHeight;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
