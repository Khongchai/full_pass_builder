import 'dart:math';

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
                body: Container(
          color: Colors.red.withOpacity(0.2),
          child: SingleChildScrollView(
            child: Builder(builder: (context) {
              return Padding(
                padding:
                    EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                child: FullPassBuilder(
                  childrenBuilder: (context, constraints) => [
                    ..._textList,
                    ..._textList,
                    ElevatedButton(
                        onPressed: _addText,
                        child: const Text(
                            "Sticky Button::Click to Add More Space")),
                  ],
                  // Consider this declarative API.
                  // layouter.allMid()..aggregateHeight()..done();
                  // layouter.allMid()..aggregateHeight()..done();
                  // layouter.each((childSize, setChildOffset
                  //
                  // Decides how to position children.
                  // TODO @khongchai this migth be a better API
                  // layoutAndSizing: (layouter) {
                  //    layouter.constraints
                  //    layouter.sizes
                  //    layouter.offsets
                  //    layouter.setOffsetForEachChild(Offset Function(Size childSize));
                  //    layouter.maxChildSize
                  //    layouter.minChildSize
                  //    layouter.utils.allMid() => Size
                  //    layouter.utils.allStart() => Size
                  //    layouter.utils.allEnd() => Size
                  //    layouter.utils.zigZag() => Size
                  //    layouter.utils.lastElementSticky() => Size
                  //    layouter.utils.lastElementConditionalSticky() => Size
                  // }
                  layoutAndSizing: (constraints, sizesAndOffsets) {
                    double heightSoFar = 0;
                    double maxWidth = 0;

                    for (int i = 0; i < sizesAndOffsets.length; i++) {
                      maxWidth =
                          max(sizesAndOffsets[i].getSize().width, maxWidth);
                    }

                    for (int i = 0; i < sizesAndOffsets.length; i++) {
                      // if is last
                      if (i == sizesAndOffsets.length - 1) {
                        final fixedBottom = MediaQuery.of(context).size.height -
                            MediaQuery.of(context).padding.top - sizesAndOffsets[i].getSize().height;
                        final contentBottom = heightSoFar + MediaQuery.of(context).padding.top;
                        sizesAndOffsets[i].offset =
                            Offset(0, (max(fixedBottom, contentBottom) ));
                      } else {
                        sizesAndOffsets[i].offset = Offset(0, heightSoFar);
                        heightSoFar += sizesAndOffsets[i].getSize().height;
                      }
                    }

                    return Size(maxWidth,
                        max(heightSoFar, MediaQuery.of(context).size.height));
                  },
                ),
              );
            }),
          ),
        )
                // When the widget has the information of all its children
                // bottomUp: (parentConstraints, childrenGeometries) => [])),
                ));
  }
}
