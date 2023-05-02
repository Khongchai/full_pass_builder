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
                  // Decides how to position children.
                  // TODO @khongchai this migth be a better API
                  // layoutAndSizing: (ctx, layouter) {
                  // TODO @khongchai
                  // These things should be a separate class
                  //    return composer.setHorizontal()
                  //            ..moveHalfDown()
                  //            ..forEachChild((childSize, setChildOffset) => Size)
                  //            ..
                  //            .compose();
                  //    layouter.template.allMid() => Size
                  //    layouter.template.allStart() => Size
                  //    layouter.template.allEnd() => Size
                  //    layouter.template.masonry() =>
                  //    layouter.template.parallax() =>
                  //    layouter.template.zigZag() => Size
                  //    layouter.template.sticky() => Size
                  //    layouter.template.stickyFooter() => Size
                  // }
                  layoutAndSizing: (layouter) {
                    double heightSoFar = 0;
                    layouter.forEachChild((constraints, size, offset, index) {
                      // Is last
                      if (layouter.childCount - 1 == index) {
                        final fixedBottom = MediaQuery.of(context).size.height -
                            MediaQuery.of(context).padding.top -
                            size.height;
                        final contentBottom =
                            heightSoFar + MediaQuery.of(context).padding.top;
                        offset.set =
                            Offset(0, (max(fixedBottom, contentBottom)));
                      } else {
                        offset.set = Offset(0, heightSoFar);
                        heightSoFar += size.height;
                      }
                    });

                    return Size(
                        layouter.maxRectangle.width,
                        max(
                            layouter.childrenParentData.last.offset.dy +
                                layouter.childrenSizes.last.height,
                            MediaQuery.of(context).size.height));
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
