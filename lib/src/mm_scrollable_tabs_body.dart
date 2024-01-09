part of '../mm_scrollable_tabs.dart';

class MMScrollableTabsBody<T> extends StatefulWidget {
  const MMScrollableTabsBody({
    super.key,
    required this.controller,
    this.scrollController,
    required this.buildContentWidget,
    this.toolbarOffset = 0.0,
    this.physics,
    this.curve = Curves.easeOut,
    this.duration = const Duration(milliseconds: 500),
  });

  final MMScrollableTabsController<T> controller;
  final ScrollController? scrollController;
  final ScrollPhysics? physics;
  final double toolbarOffset;
  final Curve curve;
  final Duration duration;
  final Widget Function(
    MMScrollableTabsItem<T> tab,
    bool active,
  ) buildContentWidget;

  @override
  State<MMScrollableTabsBody> createState() => _MMScrollableTabsBodyState<T>();
}

class _MMScrollableTabsBodyState<T> extends State<MMScrollableTabsBody<T>>
    with WidgetsBindingObserver {
  late Map<MMScrollableTabsItem<T>, double> topOffsets;
  ScrollController? attachedScrollController;

  double? lastContentHeight;
  bool autoScrolling = false;

  MMScrollableTabsItem<T>? active;

  @override
  void initState() {
    widget.controller._bodyState = this;
    topOffsets = {};

    attachedScrollController =
        (widget.scrollController?.positions.isNotEmpty ?? true)
            ? null
            : widget.scrollController;

    widget.scrollController?.addListener(activeTabListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      calculateTopOffsets();
      calculateLastContentHeight();
      activeTabListener();
    });

    super.initState();
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(activeTabListener);
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

  void calculateTopOffsets() {
    for (final tab in widget.controller.tabs) {
      final offset = findTopOffset(tab.globalKey);
      if (offset == null) continue;
      topOffsets[tab] = offset;
    }
    // Normalize the offsets
    if (topOffsets.isEmpty) return;
    final minOffset = topOffsets.values.reduce((a, b) => a < b ? a : b);
    topOffsets = topOffsets.map((key, value) {
      return MapEntry(key, value - minOffset);
    });
  }

  double? findTopOffset(GlobalKey key) {
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    final position = renderBox?.localToGlobal(Offset.zero);
    return position?.dy;
  }

  void autoAnimateToTab(MMScrollableTabsItem<T> tab) {
    if (widget.scrollController == null) return;
    if (topOffsets[tab] == null) return;

    setState(() => autoScrolling = true);

    final callback = widget.scrollController?.animateTo(
      topOffsets[tab]! - widget.toolbarOffset,
      duration: widget.duration,
      curve: widget.curve,
    );
    callback?.then(
      (_) {
        setState(() => autoScrolling = false);
        widget.controller.onTabActive?.call(tab);
      },
    );
  }

  void activeTabListener() {
    if (widget.scrollController == null) {
      widget.controller._setActiveTabForTabBar(widget.controller.tabs.first);
      widget.controller.onTabActive?.call(widget.controller.tabs.first);
      return;
    }

    final offset = widget.scrollController!.offset;
    // Find the first key that has the closest offset to zero (take absolute value)
    final filteredOffsets = topOffsets.keys.where((e) {
      return topOffsets[e] != null;
    });

    if (filteredOffsets.isEmpty) return;

    final closestTab = filteredOffsets.reduce(
      (a, b) {
        final aOffset = topOffsets[a];
        final bOffset = topOffsets[b];
        final aDistance = ((aOffset ?? 9999) - offset).abs();
        final bDistance = ((bOffset ?? 9999) - offset).abs();
        return aDistance < bDistance ? a : b;
      },
    );

    if (active != closestTab) {
      setState(() => active = closestTab);
      widget.controller._setActiveTabForTabBar(closestTab);
      if (!autoScrolling) {
        widget.controller.onTabActive?.call(closestTab);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final slivers = widget.controller.tabs.map((tab) {
          return SliverToBoxAdapter(
            child: widget.buildContentWidget(
              tab,
              active?.globalKey == tab.globalKey,
            ),
          );
        }).toList();

        final height = constraints.maxHeight -
            (lastContentHeight ?? 0) -
            widget.toolbarOffset;

        if (height > 0) {
          slivers.add(SliverToBoxAdapter(child: SizedBox(height: height)));
        }

        return CustomScrollView(
          physics: widget.physics,
          controller: attachedScrollController,
          slivers: slivers,
        );
      },
    );
  }
}
