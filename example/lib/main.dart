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
        home: Scaffold(
            body: Container(
          color: Colors.red.withOpacity(0.2),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Builder(builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              return Align(
                child: Padding(
                  padding:
                      EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                  child: fullPassBuilderFactory.verticalMasonry(
                      verticalGap: 8,
                      horizontalGap: 8,
                      masonryBuilder: (context) => [
                            [
                              Container(
                                  width: screenWidth / 3,
                                  height: 300,
                                  color: Colors.black12),
                              Container(
                                  width: screenWidth / 3,
                                  height: 200,
                                  color: Colors.pinkAccent),
                              Container(
                                  width: screenWidth / 3,
                                  height: 300,
                                  color: Colors.red),
                              Container(
                                  width: screenWidth / 3,
                                  height: 100,
                                  color: Colors.lightBlue),
                            ],
                            [
                              Container(
                                  width: screenWidth / 3,
                                  height: 300,
                                  color: Colors.red),
                              Container(
                                  width: screenWidth / 3,
                                  height: 200,
                                  color: Colors.pinkAccent),
                              Container(
                                  width: screenWidth / 3,
                                  height: 300,
                                  color: Colors.black12),
                              Container(
                                  width: screenWidth / 3,
                                  height: 100,
                                  color: Colors.lightBlue),
                            ],
                            [
                              Container(
                                  width: screenWidth / 3,
                                  height: 300,
                                  color: Colors.purpleAccent),
                              Container(
                                  width: screenWidth / 3,
                                  height: 200,
                                  color: Colors.pinkAccent),
                              Container(
                                  width: screenWidth / 3,
                                  height: 100,
                                  color: Colors.lightBlue),
                            ]
                          ]),
                  // fullPassBuilderFactory.stickyFooter(
                  //   childrenBuilder: (context, constraints) => [
                  //     ..._textList,
                  //     ..._textList,
                  //   ],
                  //   stickyChildBuilder: (context, constraints) =>  ElevatedButton(
                  //       onPressed: _addText,
                  //       child: const Text(
                  //           "Sticky Button::Click to Add More Space")),
                  // ),
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
