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
  final Widget? Function(
    MMScrollableTabsItem<T> tab,
    bool active,
  ) buildContentWidget;

  @override
  State<MMNestedScrollableTabsBody> createState() =>
      _MMNestedScrollableTabsBodyState<T>();
}

class _MMNestedScrollableTabsBodyState<T>
    extends State<MMNestedScrollableTabsBody<T>> with WidgetsBindingObserver {
  late Map<MMScrollableTabsItem<T>, double> initialTopOffsets;

  double? lastContentHeight;
  bool autoScrolling = false;

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

    nestedScrollViewState?.outerController.addListener(
      activeTabListener,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => initialTopOffsets = calculateOffsets());
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

  void calculateLastContentHeight() {
    final renderBox = widget.controller.tabs.last.globalKey.currentContext
        ?.findRenderObject() as RenderBox?;
    final height = renderBox?.size.height;
    if (height != null) {
      setState(() => lastContentHeight = height);
    }
  }

  double? findTopOffset(GlobalKey key) {
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    final position = renderBox?.localToGlobal(Offset.zero);
    return position?.dy;
  }

  void autoAnimateToTab(MMScrollableTabsItem<T> tab) {
    if (nestedScrollViewState == null) return;
    if (initialTopOffsets[tab] == null) return;

    setState(() => autoScrolling = true);

    final minInitialTopOffset = initialTopOffsets.values.reduce(min);
    final normalizedOffset = initialTopOffsets[tab]! - minInitialTopOffset;
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
          setState(() => autoScrolling = false);
          widget.controller.onTabActive?.call(tab);
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
          setState(() => autoScrolling = false);
          widget.controller.onTabActive?.call(tab);
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

    setState(() => active = closestTab);
    widget.controller._setActiveTabForTabBar(closestTab!);
    if (!autoScrolling) {
      widget.controller.onTabActive?.call(closestTab!);
    }
  }

  Map<MMScrollableTabsItem<T>, double> calculateOffsets() {
    final topOffsets = <MMScrollableTabsItem<T>, double>{};
    for (final tab in widget.controller.tabs) {
      final offset = findTopOffset(tab.globalKey);
      if (offset == null) continue;
      topOffsets[tab] = offset;
    }
    return topOffsets;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final slivers = widget.controller.tabs.map((tab) {
          Widget? child = widget.buildContentWidget(
            tab,
            active?.globalKey == tab.globalKey,
          );

          child ??= const SizedBox();

          return SliverToBoxAdapter(child: child);
        }).toList();

        final height = constraints.maxHeight -
            (lastContentHeight ?? 0) -
            widget.pinnedToolbarHeight;

        if (height > 0) {
          slivers.add(SliverToBoxAdapter(child: SizedBox(height: height)));
        }

        return CustomScrollView(
          physics: widget.physics,
          slivers: slivers,
        );
      },
    );
  }
}
