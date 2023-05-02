import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:full_pass_builder/full_pass_builder.dart';

/// You can use extension to extend this class, rather than create your own
/// factory.
final FullPassBuilderFactory fullPassBuilderFactory =
    FullPassBuilderFactory._instance;

/// Sets of layout templates that conforms to the [LayouterVisitorWithContext] interface.
///
/// TODO masonry, parallax, the text thing.
class FullPassBuilderFactory {
  static final FullPassBuilderFactory _instance = FullPassBuilderFactory._();

  FullPassBuilderFactory._();

  /// A basic example of how you can achieve the [spaceEvenly] of the flex layout.
  ///
  /// This is meant more as an example; it does not take into account the
  /// non-flexbile geometries of some children before setting the offsets.
  ///
  /// The horizontal equivalent can be done by swapping the x and y axes.
  FullPassBuilder verticalSpaceEvenly(
      {required ChildrenBuilder childrenBuilder}) {
    return FullPassBuilder(
        layouterVisitor: (context, layouter) {
          double offsetSoFar = 0;
          final screenHeight = MediaQuery.of(context).size.height;
          final portion = screenHeight / layouter.childCount;
          layouter.forEachChild((constraints, size, offset, childIndex) {
            offset.set = Offset(0, offsetSoFar);
            offsetSoFar += portion;
          });
          return Size(layouter.maxRectangle.width, screenHeight);
        },
        childrenBuilder: childrenBuilder);
  }

  /// https://css-tricks.com/couple-takes-sticky-footer/
  FullPassBuilder stickyFooter(
      {required ChildrenBuilder childrenBuilder,
      required ChildBuilder stickyChildBuilder}) {
    return FullPassBuilder(
        layouterVisitor: (context, layouter) {
          double heightSoFar = 0;
          layouter.forEachChild((constraints, size, offset, index) {
            // Is last
            if (layouter.childCount - 1 == index) {
              final fixedBottom = MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  size.height;
              final contentBottom =
                  heightSoFar + MediaQuery.of(context).padding.top;
              offset.set = Offset(0, (max(fixedBottom, contentBottom)));
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
        childrenBuilder: (context, constraints) => [
              ...childrenBuilder(context, constraints),
              stickyChildBuilder(context, constraints)
            ]);
  }
}
