library full_pass_builder;

// TODO @khongchai separate exports into a separate file.
export "package:full_pass_builder/full_pass_builder.dart";

import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

import 'layouter.dart';

/// Same as LayouterVisitor, but with context
///
/// {@macro layouter_visitor}
typedef LayouterVisitorWithContext = Size Function(
    BuildContext context, Layouter layouter);

/// {@template layouter_visitor}
///
/// This method accepts a layouter and returns the Size of the container of all
/// widgets.
///
/// The layouter have access to some common data about the parent of the current
/// widget after having laid them out individually. One can use those decision
/// to make extra offsets based on the current ambient layout data such as
/// the constriants, the screen width and height, or the siblings data.
///
/// This is similar to obtaining Widgets detail using [GlobalKey], but instead
/// of getting the layout details post-render, all details are obtained within
/// the same frame.
///
/// This is guaranteed to be called after [childrenBuilder], this means that you
/// can use information the [childrenBuilder] have access to in this visitor.
///
/// ```dart
///     final List<int> nestedRowsAmount = [];
///     return FullPassBuilder(layouterVisitor: (context, layouter) {
///      // ...
///         return Size(...);
///     }, childrenBuilder: (context, constraints) {
///         final List<List<Widget>> widgets = obtainWidgetsFromSomewhere(context);
///         widgets.forEach((w) => nestedRowsAmount.add(w.length));
///       return [...];
///     });
/// ```
///
/// {@endtemplate}
typedef LayouterVisitor = Size Function(Layouter layouter);

typedef ChildrenBuilder = List<Widget> Function(
    BuildContext context, BoxConstraints constraints);

typedef ChildBuilder = Widget Function(
    BuildContext context, BoxConstraints constraints);

/// A widget that makes it much easier to create custom layouts. Some of your
/// layouts might require siblings, or children geometries to be present, but
/// to get that, you'd usually have to go through all the boilerplate and imperative
/// code with [GlobalKey] and [addPostFrameCallback]. With this, all you need
/// is to just invoke the FullPassBuilder constructor, and all the information
/// you need will just be there for you.
///
/// This widget is a wrapper over the the [ChildrenGeometriesProvidedBuilder].
///
/// It takes the constraints from [LayoutBuilder] and the children geometries from
/// [ChildrenGeometriesProvidedBuilder] and create a widget builder that has access
/// to all details reported to it by both the parents and children.
///
/// To create a flex-like layout that position its children evenly, you can do
/// something like this.
/// ```dart
///  Widget build(BuildContext context) {
///     return FullPassBuilder(childrenBuilder: (context) => [
///        Text1("Hello"),
///        Text2("Hello"),
///     ],
///     layouterVisitor: (context, layouter) {
///                     double offsetSoFar = 0;
///                     final screenHeight = MediaQuery.of(context).size.height;
///                     final portion = screenHeight / layouter.childCount;
///                     layouter.forEachChild((constraints, size, offset, childIndex) {
///                       offset.set = Offset(0, offsetSoFar);
///                       offsetSoFar += portion;
///                     });
///                     return Size(layouter.maxRectangle.width, screenHeight);
///                   },
///     );
///  }
///
/// For more advanced examples, take a look at the [FullPassBuilderFactory] class.
/// ```
///
/// If you need something text-related [like this](https://www.youtube.com/watch?v=cq34RWXegM8),
/// this widget won't solve your problem. Text-related widget position requires
/// additional calculations and the custom render object itself will have to also
/// render the texts. I want this widget to be as generic as possible.
class FullPassBuilder extends StatelessWidget {
  /// Same as LayouterVisitor, but with context
  ///
  /// {@macro layouter_visitor}
  final LayouterVisitorWithContext layouterVisitor;
  final ChildrenBuilder childrenBuilder;

  const FullPassBuilder(
      {required this.layouterVisitor, required this.childrenBuilder, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => ChildrenGeometriesProvidedBuilder(
          children: childrenBuilder(context, constraints),
          layouterVisitor: (layouter) => layouterVisitor(context, layouter)),
    );
  }
}

/// A widget that exposes its layout calculation to an external visitor.
///
/// With this widget, you get data widgets such as Column and Row have access to:
/// the geometries of the children.
/// With the geometries, you can arbitrarily position your children however you
/// wish.
class ChildrenGeometriesProvidedBuilder extends MultiChildRenderObjectWidget {
  /// {@macro layouter_visitor}
  final LayouterVisitor layouterVisitor;

  ChildrenGeometriesProvidedBuilder(
      {required List<Widget> children, required this.layouterVisitor, Key? key})
      : super(key: key, children: children);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return ChildrenGeometriesProviderRenderObject(
        layoutVisitor: layouterVisitor);
  }

  @override
  void updateRenderObject(BuildContext context,
      ChildrenGeometriesProviderRenderObject renderObject) {
    renderObject.layoutVisitor = layouterVisitor;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('layouterVisitor', layouterVisitor.toString()));
    properties.add(StringProperty('children', children.toString()));
  }
}

class ChildrenGeometriesProviderParentData
    extends ContainerBoxParentData<RenderBox> {}

class ChildrenGeometriesProviderRenderObject extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox,
            ChildrenGeometriesProviderParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox,
            ChildrenGeometriesProviderParentData>,
        DebugOverflowIndicatorMixin {
  LayouterVisitor layoutVisitor;

  ChildrenGeometriesProviderRenderObject({required this.layoutVisitor});

  @override
  double computeMinIntrinsicWidth(double height) => 0.0;

  @override
  double computeMaxIntrinsicWidth(double height) {
    double totalWidth = 0;
    forEachChild((child, _) {
      totalWidth += child.size.width;
    });
    return totalWidth;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  double computeMinIntrinsicHeight(double width) => 0.0;

  @override
  double computeMaxIntrinsicHeight(double width) {
    double totalHeight = 0;
    forEachChild((child, _) {
      totalHeight += child.size.height;
    });
    return totalHeight;
  }

  @override
  void performLayout() {
    size = computeDryLayout(constraints);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final List<double> minRectangle =
        List.filled(2, double.infinity, growable: false);
    final List<double> maxRectangle = List.filled(2, 0, growable: false);
    final List<Size> childrenSizes =
        List.filled(childCount, Size.zero, growable: false);
    final List<ChildrenGeometriesProviderParentData> parentData = List.filled(
        childCount, ChildrenGeometriesProviderParentData(),
        growable: false);

    forEachChild((child, i) {
      final size = ChildLayoutHelper.layoutChild(child, constraints);

      minRectangle[0] = min(minRectangle[0], size.width);
      minRectangle[1] = min(minRectangle[1], size.height);

      maxRectangle[0] = max(maxRectangle[0], size.width);
      maxRectangle[1] = max(maxRectangle[1], size.height);

      childrenSizes[i] = size;
      parentData[i] = child.parentData as ChildrenGeometriesProviderParentData;
    });

    return constraints.constrain(layoutVisitor(Layouter(
        minRectangle: Size(minRectangle[0], minRectangle[1]),
        maxRectangle: Size(maxRectangle[0], maxRectangle[1]),
        constraints: constraints,
        childrenSizes: childrenSizes,
        childrenParentData: parentData)));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! ChildrenGeometriesProviderParentData) {
      child.parentData = ChildrenGeometriesProviderParentData();
    }
  }

  void forEachChild(void Function(RenderBox child, int index) callback) {
    RenderBox? child = firstChild;
    int i = 0;
    while (child != null) {
      callback(child, i);
      i++;
      final parentData =
          child.parentData as ChildrenGeometriesProviderParentData;
      child = parentData.nextSibling;
    }
  }
}
