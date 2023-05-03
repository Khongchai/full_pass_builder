import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:full_pass_builder/full_pass_builder.dart';

/// Sets of layout templates that conforms to the [LayouterVisitorWithContext] interface.
///
class FullPassBuilderExamples {
  FullPassBuilderExamples._();

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
  ///
  /// The constraints parameter passed to the masonryBuilder is the final
  /// constraints after having subtracted both the horizontal and verticalGap.
  ///
  /// This is a simple n-row masonry. More complex layouts like masonry grids
  /// can also be created...if you have the time...and the energy.
  static FullPassBuilder verticalMasonry(
      {required double verticalGap,
      required double horizontalGap,
      required List<List<Widget>> Function(
              BuildContext context, BoxConstraints constraints)
          masonryBuilder}) {
    // Each integer represents the number of member in a column.
    final List<int> columnSizes = [];
    return FullPassBuilder(layouterVisitor: (context, layouter) {
      int columnIndex = 0;
      int childrenCountInPreviousColumns = 0;
      double maxItemWidth = 0;

      // Usable states
      List<double> maxWidthInEachColumn =
          List.filled(columnSizes.length, 0, growable: false);
      List<List<OffsetWrapper>> offsetsByColumn =
          List.generate(columnSizes.length, (_) => [], growable: false);
      List<List<Size>> sizesByColumn =
          List.generate(columnSizes.length, (_) => [], growable: false);

      layouter.forEachChild((constraints, size, offset, childIndex) {
        maxItemWidth = max(size.width, maxItemWidth);
        sizesByColumn[columnIndex].add(size);
        offsetsByColumn[columnIndex].add(offset);
        // Whether or not we have reached a new masonry column.

        if (columnSizes[columnIndex] - 1 <=
            (childIndex - childrenCountInPreviousColumns)) {
          // We have! Reset the state for the next column.
          maxWidthInEachColumn[columnIndex] = maxItemWidth;
          childrenCountInPreviousColumns += columnSizes[columnIndex];
          columnIndex++;
        }
      });

      assert(
          sizesByColumn.length &
                  offsetsByColumn.length &
                  maxWidthInEachColumn.length ==
              columnSizes.length,
          "Sizes of all columns should be the same.");

      double sizeY = MediaQuery.of(context).size.height;
      double maxWidthInPreviousColumn = 0;
      for (int i = 0; i < columnSizes.length; i++) {
        maxWidthInPreviousColumn +=
            i - 1 == -1 ? 0 : maxWidthInEachColumn[i - 1];
        final currentOffsets = offsetsByColumn[i];
        final currentSizes = sizesByColumn[i];

        double columnHeightSoFar = 0;
        for (int j = 0; j < currentOffsets.length; j++) {
          double xOffset = 0;
          double yOffset = 0;

          xOffset += maxWidthInPreviousColumn + horizontalGap * i;
          yOffset += columnHeightSoFar;

          currentOffsets[j].set = Offset(xOffset, yOffset);
          columnHeightSoFar += currentSizes[j].height + verticalGap;
          sizeY = max(columnHeightSoFar, sizeY);
        }
      }

      return Size(MediaQuery.of(context).size.width, sizeY);
    }, childrenBuilder: (context, constraints) {
      final widgets = masonryBuilder(
          context,
          constraints.copyWith(
            maxWidth: constraints.maxWidth - horizontalGap,
            maxHeight: constraints.maxHeight - verticalGap,
          ));
      widgets.forEach((e) => columnSizes.add(e.length));
      return widgets.expand((element) => element).toList(growable: false);
    });
  }

  /// https://www.youtube.com/watch?v=Si5XJ_IocEs
  ///
  /// Just an example of a custom layout calculation. Using the IntrinsicHeight,
  /// as is shown in the video above might be more convenient.
  ///
  /// However, this one does not require a speculative layout and does not cause O(n^2) layout time.
  /// (but it might cause O(n^2) development time :p)
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
              offsetX -=
                  layouter.maxRectangle.width / 2 + size.width / 2 + space;
              offsetY -= layouter.maxRectangle.height / 2 - size.height / 2;
            } else if (childIndex == bottomRightIndex) {
              offsetX +=
                  layouter.maxRectangle.width / 2 + size.width / 2 + space;
              offsetY += layouter.maxRectangle.height / 2 - size.height / 2;
            }

            offset.set = Offset(offsetX, offsetY);
          });
          return screenSize;
        },
        childrenBuilder: (context, constraints) =>
            [topLeft, center, bottomRight]);
  }
}
