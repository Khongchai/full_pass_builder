import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:full_pass_builder/full_pass_builder.dart';

/// Sets of layout templates that conforms to the [LayouterVisitorWithContext] interface.
///
class FullPassBuilderFactory {
  FullPassBuilderFactory._();

  /// A basic example of how you can achieve the [spaceEvenly] of the flex layout.
  ///
  /// This is meant more as an example; it does not take into account the
  /// non-flexbile geometries of some children before setting the offsets.
  ///
  /// The horizontal equivalent can be done by swapping the x and y axes.
  static FullPassBuilder verticalSpaceEvenly(
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
  static FullPassBuilder stickyFooter(
      {required ChildrenBuilder childrenBuilder,
      required double additonalBottomPadding,
      required ChildBuilder stickyChildBuilder}) {
    return FullPassBuilder(
        layouterVisitor: (context, layouter) {
          double heightSoFar = 0;
          layouter.forEachChild((constraints, size, offset, index) {
            final mdof = MediaQuery.of(context);
            // Is last
            if (layouter.childCount - 1 == index) {
              final fixedBottom =
                  mdof.size.height - mdof.padding.top - size.height;
              final contentBottom =
                  heightSoFar + mdof.padding.top - additonalBottomPadding;
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

  /// Your standard masonry-style UI.
  static FullPassBuilder verticalMasonry(
      {required double verticalGap,
      required double horizontalGap,
      required List<List<Widget>> Function(BuildContext context)
          masonryBuilder}) {
    // Each integer represents the number of member in a stack.
    final List<int> stackSizes = [];
    return FullPassBuilder(layouterVisitor: (context, layouter) {
      // Stack is like either a row or a column
      int stackIndex = 0;
      int childrenCountInPreviousStacks = 0;
      layouter.forEachChild((constraints, size, offset, childIndex) {
        // Whether or not we have reached a new masonry stack.
        if (stackSizes[stackIndex] - 1 <=
            (childIndex - childrenCountInPreviousStacks)) {
          childrenCountInPreviousStacks += stackSizes[stackIndex];
          // TODO @khongchai
          // Do something before resetting the stack index.
          stackIndex++;
        }
      });
      return MediaQuery.of(context).size;
    }, childrenBuilder: (context, constraints) {
      final widgets = masonryBuilder(context);
      widgets.forEach((e) => stackSizes.add(e.length));
      return widgets.expand((element) => element).toList(growable: false);
    });
  }

  /// https://www.youtube.com/watch?v=Si5XJ_IocEs
  ///
  /// Just an example of a custom layout calculation. Using the IntrinsicHeight,
  /// as is shown in the video above might be more convenient.
  ///
  /// Important note:
  /// Even though this one does not require a speculative layout and does not
  /// cause O(n^2) layout time, it might cause O(n^2) development time :p
  static FullPassBuilder intrinsicHeight({
    required Widget topLeft,
    required Widget center,
    required Widget bottomRight,
    required double space,
  }) {
    const topLeftIndex = 0;
    const bottomRightIndex = 2;
    return FullPassBuilder(
        layouterVisitor: (context, layouter) {
          final screenSize = MediaQuery.of(context).size;
          layouter.forEachChild((constraints, size, offset, childIndex) {
            double offsetX = 0;
            double offsetY = 0;

            // Center
            offsetX = screenSize.width / 2 - size.width / 2;
            offsetY = screenSize.height / 2 - size.height / 2;

            if (childIndex == topLeftIndex) {
              offsetX -= layouter.maxRectangle.width / 2 + size.width / 2 + space;
              offsetY -= layouter.maxRectangle.height / 2 - size.height /2;
            } else if (childIndex == bottomRightIndex) {
              offsetX += layouter.maxRectangle.width / 2 + size.width / 2 + space;
              offsetY += layouter.maxRectangle.height / 2 - size.height /2;
            }

            offset.set = Offset(offsetX, offsetY);
          });
          return screenSize;
        },
        childrenBuilder: (context, constraints) =>
        [topLeft, center, bottomRight]
        );
  }
}
