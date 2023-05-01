import 'package:flutter/material.dart';
import "package:full_pass_builder/full_pass_builder.dart";

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
    const Text("Hello"),
  ];

  void _addText() {
    _textList.add(const Text("Hello"));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home:
            // TODO @khongchai. This builder should make it possible to
            // make the button sticky until the space between the bottom child n
            // and the n-1 child is less than zero. At that point, the child should
            // be no longer be sticky and go along with other content.
            // If SingleChildScrollView is applied, the bottom child should scroll with everything else.
            Scaffold(
                body: SafeArea(
                    child: Container(
          color: Colors.red.withOpacity(0.2),
          child: FullPassBuilder(
            children: [
              ..._textList,
              GestureDetector(
                  onTap: _addText,
                  child: const Text("Sticky Button::Click to add more space")),
            ],
            // Decides how to position children.
            positioner: (constraints, sizesAndOffsets) {
              for (final s in sizesAndOffsets) {
                s.offset = Offset.zero;
              }
              sizesAndOffsets.last.offset = const Offset(0, 10);
            },
          ),
        ))
                // When the widget has the information of all its children
                // bottomUp: (parentConstraints, childrenGeometries) => [])),
                ));
  }
}
