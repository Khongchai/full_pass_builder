library full_pass_builder;

// TODO @khongchai separate exports into a separate file.
export "package:full_pass_builder/full_pass_builder.dart";
export "package:full_pass_builder/helpers.dart";
export "package:full_pass_builder/child_size_and_parent_offset.dart";

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

import 'child_size_and_parent_offset.dart';

typedef WidgetLayouter = Size Function(BoxConstraints constraints,
    List<ChildSizeAndOffset> childrenSizesAndOffsets);

class FullPassBuilder extends StatelessWidget {
  final WidgetLayouter layoutAndSizing;
  final List<Widget> Function(BuildContext context, BoxConstraints constraints)
      childrenBuilder;

  const FullPassBuilder(
      {required this.layoutAndSizing, required this.childrenBuilder, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => FlexibleLayoutBuilder(
        children: childrenBuilder(context, constraints),
        positioner: layoutAndSizing,
      ),
    );
  }
}

/// A widget that exposes its layout calculation to the children.
///
/// With this widget, you get data widgets such as Column and Row have access to:
/// the geometries of the children.
/// With the geometries, you can arbitrarily position your children however you
/// wish.
///
/// With LayoutBuilder, you only get the constraints from the parent.
class FlexibleLayoutBuilder extends MultiChildRenderObjectWidget {
  final WidgetLayouter positioner;

  FlexibleLayoutBuilder(
      {required List<Widget> children, required this.positioner, Key? key})
      : super(key: key, children: children);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return ChildrenGeometriesProviderRenderObject(
      customLayouter: positioner,
    );
  }

  @override
  void updateRenderObject(BuildContext context,
      ChildrenGeometriesProviderRenderObject renderObject) {
    renderObject.customLayouter = positioner;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('positioner', positioner.toString()));
    properties.add(StringProperty('children', children.toString()));
  }
}

class ChildGeometriesProviderParentData
    extends ContainerBoxParentData<RenderBox> {}

class ChildrenGeometriesProviderRenderObject extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox,
            ChildGeometriesProviderParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox,
            ChildGeometriesProviderParentData>,
        DebugOverflowIndicatorMixin {
  WidgetLayouter customLayouter;

  ChildrenGeometriesProviderRenderObject({required this.customLayouter});

  @override
  double computeMinIntrinsicWidth(double height) => 0.0;

  @override
  double computeMaxIntrinsicWidth(double height) {
    double totalWidth = 0;
    forEachChild((child) {
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
    forEachChild((child) {
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
    List<ChildSizeAndOffset> sizesAndOffsets = [];
    forEachChild((child) {
      final size = ChildLayoutHelper.layoutChild(child, constraints);

      sizesAndOffsets.add(ChildSizeAndOffset(
          size, child.parentData as ChildGeometriesProviderParentData));
    });

    return constraints.constrain(customLayouter(constraints, sizesAndOffsets));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! ChildGeometriesProviderParentData) {
      child.parentData = ChildGeometriesProviderParentData();
    }
  }

  void forEachChild(void Function(RenderBox child) callback) {
    RenderBox? child = firstChild;
    while (child != null) {
      callback(child);
      final parentData = child.parentData as ChildGeometriesProviderParentData;
      child = parentData.nextSibling;
    }
  }
}
