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

    controller = MMScrollableTabsController<String>(
      onTabActive: (tab) {
        print('Tab active ${tab.key} with index ${tabs.indexOf(tab)}');
      },
      tabs: tabs,
    );

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
    const toolbarHeight = 80.0;

    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
          controller: scrollController,
          scrollDirection: Axis.vertical,
          //floatHeaderSlivers: true,
          headerSliverBuilder: (context, collapsed) {
            final nestedScrollViewState =
                context.findAncestorStateOfType<NestedScrollViewState>();
            final innerScrollController =
                nestedScrollViewState?.innerController;
            return [
              SliverToBoxAdapter(
                child: Container(
                  height: 400,
                  color: Colors.red,
                ),
              ),
              SliverAppBar(
                pinned: true,
                scrolledUnderElevation: 0.0,
                toolbarHeight: toolbarHeight,
                flexibleSpace: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: MMScrollableTabsBar<String>(
                      scrollController: innerScrollController,
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
            ];
          },
          body: Builder(
            builder: (context) {
              final nestedScrollViewState =
                  context.findAncestorStateOfType<NestedScrollViewState>();
              final innerScrollController =
                  nestedScrollViewState?.innerController;

              return MMScrollableTabsBody<String>(
                controller: controller,
                scrollController: innerScrollController,
                toolbarOffset: toolbarHeight,
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
                                  print('Tab 1');
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
      ),
    );
  }
}
