import 'package:flutter/material.dart';
import 'package:mm_scrollable_tabs/mm_scrollable_tabs.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App!!',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class CustomPersistentHeaderDelegate extends SliverPersistentHeaderDelegate {
  const CustomPersistentHeaderDelegate({
    required this.height,
    required this.child,
  });
  final double height;
  final Widget child;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(height: height, color: Colors.white, child: child);
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ScrollController scrollController;
  late final MMScrollableTabsController<String> controller;

  @override
  void initState() {
    scrollController = ScrollController();
    final tabs = [
      for (int i = 1; i <= 10; i++)
        MMScrollableTabsItem(label: 'Tab $i', key: 'key_$i'),
    ];

    controller = MMScrollableTabsController<String>(tabs: tabs);

    controller.addListener((tab) {
      debugPrint('Tab active ${tab.key} with index ${tabs.indexOf(tab)}');
    });

    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const appBarHeight = 50.0;
    const toolbarHeight = 40.0;
    const greenHeight = 100.0;

    final pinnedFlexibleSpaceBarHeight =
        greenHeight + appBarHeight + MediaQuery.of(context).padding.top * 2;
    final pinnedToolbarHeight = pinnedFlexibleSpaceBarHeight + toolbarHeight;

    return Scaffold(
      body: NestedScrollView(
        controller: scrollController,
        scrollDirection: Axis.vertical,
        //floatHeaderSlivers: true,

        headerSliverBuilder: (context, collapsed) {
          return [
            SliverAppBar(
              automaticallyImplyLeading: false,
              toolbarHeight: appBarHeight,
              collapsedHeight: appBarHeight,
              pinned: true,
              backgroundColor: Colors.yellow,
              expandedHeight: MediaQuery.of(context).size.width,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text('Title'),
                collapseMode: CollapseMode.pin,
                background: Container(
                  color: Colors.blue,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(height: 300, color: Colors.red),
            ),
            SliverAppBar(
              pinned: true,
              toolbarHeight: greenHeight,
              scrolledUnderElevation: 0,
              flexibleSpace: Container(color: Colors.green),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: CustomPersistentHeaderDelegate(
                height: toolbarHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: MMScrollableTabsBar<String>(
                      controller: controller,
                      buildTabWidget: (tab, active) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 4.0,
                          ),
                          decoration: BoxDecoration(
                            color: active ? Colors.red : Colors.transparent,
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(tab.label),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: Builder(
          builder: (context) {
            return MMNestedScrollableTabsBody<String>(
              controller: controller,
              pinnedToolbarHeight: pinnedToolbarHeight,
              buildContentWidget: (tab, active) {
                return Column(
                  key: tab.globalKey,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16.0,
                        right: 16.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tab.label,
                            style: TextStyle(
                              color: active ? Colors.red : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              if (tab.key == 'key_1') {
                                debugPrint('Tab 1');
                              }
                            },
                            child: const Text('Button'),
                          )
                        ],
                      ),
                    ),
                    for (final color in Colors.primaries.take(8))
                      Container(
                        height: 34.0,
                        color: color,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 4.0,
                        ),
                        child: Center(child: Text(color.toString())),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
