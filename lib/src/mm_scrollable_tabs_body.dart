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

          return SliverToBoxAdapter(
            child: SizedBox(key: tab._globalKey, child: child),
          );
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
