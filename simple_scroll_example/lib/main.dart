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
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final ScrollController scrollController;
  late final MMScrollableTabsController controller;

  @override
  void initState() {
    scrollController = ScrollController();

    final tabs = List.generate(
      10,
      (index) => MMScrollableTabsItem(
        label: 'Tab $index',
        key: 'key$index',
      ),
    );

    controller = MMScrollableTabsController(
      tabs: tabs,
      onTabActive: (index) {
        // Read localization of ok
        print('onTabActive $index');
      },
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            MMScrollableTabsBar(
              controller: controller,
              scrollController: scrollController,
              buildTabWidget: (tab, active) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  child: Text(
                    tab.label,
                    style: TextStyle(
                      color: active ? Colors.blue : Colors.black,
                    ),
                  ),
                );
              },
            ),
            Expanded(
              child: MMScrollableTabsBody(
                scrollController: scrollController,
                controller: controller,
                buildContentWidget: (tab, active) {
                  return Column(
                    key: tab.globalKey,
                    children: [
                      Text(
                        tab.label,
                        style: TextStyle(
                          color: active ? Colors.blue : Colors.black,
                        ),
                      ),
                      for (var i = 0; i < 10; i++)
                        Text(
                          'Content $i',
                          style: const TextStyle(color: Colors.black),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
