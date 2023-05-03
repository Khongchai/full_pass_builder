import 'package:example/full_pass_builder_factory.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final List<Text> _textList = [
    const Text("Hello"),
  ];

  late final List<Widget Function()> _examples = [
    () => FullPassBuilderExamples.verticalMasonry(
        verticalGap: 8,
        horizontalGap: 8,
        masonryBuilder: (context, constraints) {
          return [
            [
              Container(
                  width: constraints.maxWidth / 3, height: 200, color: Colors.black),
              Container(
                  width: constraints.maxWidth / 3,
                  height: 200,
                  color: Colors.pinkAccent),
              Container(width: constraints.maxWidth / 3, height: 300, color: Colors.red),
              Container(
                  width: constraints.maxWidth / 3, height: 100, color: Colors.lightBlue),
              Container(
                  width: constraints.maxWidth / 3, height: 100, color: Colors.lightGreen),
            ],
            [
              Container(width: constraints.maxWidth / 3, height: 300, color: Colors.red),
              Container(
                  width: constraints.maxWidth / 3,
                  height: 200,
                  color: Colors.pinkAccent),
              Container(
                  width: constraints.maxWidth / 3, height: 300, color: Colors.black12),
              Container(
                  width: constraints.maxWidth / 3, height: 100, color: Colors.lightBlue),
              Container(
                  width: constraints.maxWidth / 3, height: 100, color: Colors.black),
            ],
            [
              Container(
                  width: constraints.maxWidth / 3,
                  height: 255,
                  color: Colors.purpleAccent),
              Container(
                  width: constraints.maxWidth / 3,
                  height: 100,
                  color: Colors.pinkAccent),
              Container(
                  width: constraints.maxWidth / 3, height: 100, color: Colors.greenAccent),
              Container(
                  width: constraints.maxWidth / 3, height: 50, color: Colors.lightBlue),
              Container(
                  width: constraints.maxWidth / 3, height: 110, color: Colors.yellow),
              Container(
                  width: constraints.maxWidth / 3, height: 330, color: Colors.brown),
            ]
          ];
        }),
    () => FullPassBuilderExamples.stickyFooter(
      additonalBottomPadding: kBottomNavigationBarHeight,
      childrenBuilder: (context, constraints) => [
        ..._textList,
        ..._textList,
      ],
      stickyChildBuilder: (context, constraints) => ElevatedButton(
          onPressed: () {
            setState(() {
              _textList.add(const Text("New text"));
              _textList.add(const Text("New text"));
              _textList.add(const Text("New text"));
            });
          },
          child: const Text("Sticky Button::Click to Add More Text")),
    ),
    () => FullPassBuilderExamples.intrinsicHeight(
      space: 16,
      topLeft: Container(
        color: Colors.red,
        height: 50,
        width: 50,
      ),
      center: Container(
        color: Colors.green,
        height: 100,
        width: 100,
      ),
      bottomRight: Container(
        color: Colors.blue,
        height: 75,
        width: 25,
      ),
    ),
  ];

  int _exampleIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.abc),
                  label: 'Masonry',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.abc),
                  label: 'Sticky Footer',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.abc),
                  label: 'Intrinsic Height',
                ),
              ],
              currentIndex: _exampleIndex,
              unselectedFontSize: 16,
              unselectedLabelStyle: const TextStyle(color: Colors.black),
              unselectedIconTheme: const IconThemeData(
                color: Colors.greenAccent,
              ),
              selectedItemColor: Colors.amber[800],
              onTap: (index) {
                setState(() {
                  _exampleIndex = index;
                });
              }),
          body: Container(
            key: ObjectKey(_examples),
            color: Colors.red.withOpacity(0.2),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: _examples[_exampleIndex](),
            ),
          ),
        )
        // When the widget has the information of all its children
        // bottomUp: (parentConstraints, childrenGeometries) => [])),
        );
  }
}
