import 'dart:math';

import 'package:flutter/material.dart';
import 'package:full_pass_builder/full_pass_builder.dart';

/// Sets of layout templates that conforms to the [LayouterVisitorWithContext] interface.
///
/// Do not use any of these examples in production.
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
              layouter.constraints.maxWidth,
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

  /// A more complex masonry layout with masonry grids.
  ///
  /// Again, this does not require a speculative layout pass. All layouts are
  /// done within a single pass. Just with a lot of manual calculation.
  ///
  /// Warning. This is just a demo. Using this in prod will result in your
  /// and your users' demise!
  static FullPassBuilder masonryGrid({
    // In pixels
    required double verticalGap,
    // In pixels
    required double horizontalGap,
    required List<MasonryGrid> masonry,
    required int maxColumn,
  }) {
    return FullPassBuilder(
        layouterVisitor: (context, layouter) {
          final unit = layouter.constraints.maxWidth / maxColumn;
          double sizeY = MediaQuery.of(context).size.height;

          // Row
          double xPointer = 0;
          layouter.forEachChild((constraints, size, offset, childIndex) {
            offset.set = Offset(xPointer, 0);

            xPointer =
                (xPointer + size.width + horizontalGap) % constraints.maxWidth;
          });

          // Column
          final List<double> yOffsetInEachColumnSoFar =
              List.filled(maxColumn, 0);
          int columnIndex = 0;
          layouter.forEachChild((constraints, size, offset, childIndex) {
            offset.set =
                Offset(offset.get.dx, yOffsetInEachColumnSoFar[columnIndex]);

            // ceil because a part of width is possibly subtracted by
            // horizontalWidth amount
            final columnSpan = (size.width / unit).ceil();
            assert(columnSpan <= maxColumn,
                "Total span should not be more than maxColumn");

            // If overflow, wrap around to 0.
            if (columnIndex + columnSpan > maxColumn) {
              columnIndex = 0;
              offset.set = Offset(0, yOffsetInEachColumnSoFar[columnIndex]);
            }

            // Use a column span to find out the
            // item width spans how many columns.
            for (int i = columnIndex; i < columnIndex + columnSpan; i++) {
              yOffsetInEachColumnSoFar[i] += size.height + verticalGap;
            }

            columnIndex = (columnIndex + columnSpan) % maxColumn;
          });

          return Size(
              MediaQuery.of(context).size.width,
              max(
                  yOffsetInEachColumnSoFar
                      .reduce((value, element) => max(value, element)),
                  sizeY));
        },
        // Constrain based on the grid properties.
        // Not applying the horizontal gap just yet.
        childrenConstrainer: (originalConstraints, children) {
          final List<BoxConstraints> constraints =
              List.filled(children.length, originalConstraints);
          final unit = originalConstraints.maxWidth / maxColumn;
          // Gaps are to the right of each rectangle, and the right most gap should
          // be ignored, otherwise we'll have the left side with no gap and the
          // right side with gap.
          for (int i = 0; i < children.length; i++) {
            final currentGrid = masonry[i];
            final gridWidth = unit * currentGrid.columnUnitCount;
            final gridHeight = unit * currentGrid.rowUnitCount;
            constraints[i] = originalConstraints.copyWith(
              maxWidth: gridWidth - horizontalGap,
              maxHeight: gridHeight - verticalGap,
            );
          }
          return constraints;
        },
        childrenBuilder: (context, constraints) => masonry);
  }

  /// https://www.youtube.com/watch?v=Si5XJ_IocEs
  ///
  /// Just an example of a custom layout calculation using siblings layout
  /// information.
  ///
  /// Using the IntrinsicHeight, as is shown in the video above may be more
  /// convenient in most cases. However, this one does not require a speculative
  /// layout and does not cause O(n^2) layout time.
  ///
  /// (but it might cause O(n^2) development time :p)
  static FullPassBuilder siblingsInformation({
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

final _random = Random();

/// Just a simple, randomly colored grid.
class MasonryGrid extends StatelessWidget {
  final int rowUnitCount;
  final int columnUnitCount;

  MasonryGrid({
    Key? key,
    required this.rowUnitCount,
    required this.columnUnitCount,
  }) : super(key: key);

  final _randColor = Color.fromRGBO(
      _random.nextInt(256), _random.nextInt(256), _random.nextInt(256), 1.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        color: _randColor,
        borderRadius: BorderRadius.circular(8),
      ),
      width: double.infinity,
      height: double.infinity,
    );
  }
}
