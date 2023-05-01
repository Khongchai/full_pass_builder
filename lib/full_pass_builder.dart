library full_pass_builder;

import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

import 'child_size_and_parent_offset.dart';

export "package:full_pass_builder/full_pass_builder.dart";

typedef WidgetPositioner = void Function(BoxConstraints constraints,
    List<ChildSizeAndOffset> childrenSizesAndOffsets);

/// A widget that exposes its layout calculation to the children.
class FullPassBuilder extends MultiChildRenderObjectWidget {
  final WidgetPositioner positioner;

  FullPassBuilder(
      {required List<Widget> children, required this.positioner, Key? key})
      : super(key: key, children: children);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return ChildrenGeometriesProviderRenderObject(
      positioner: positioner,
    );
  }

  @override
  void updateRenderObject(BuildContext context,
      ChildrenGeometriesProviderRenderObject renderObject) {
    renderObject.positioner = positioner;
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
            ChildGeometriesProviderParentData> {
  WidgetPositioner positioner;

  ChildrenGeometriesProviderRenderObject({required this.positioner});

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

  // Return size of zero if no children, else take up the full constraints.
  @override
  Size computeDryLayout(BoxConstraints constraints) {
    List<ChildSizeAndOffset> sizesAndOffsets = [];
    forEachChild((child) {
      final size = ChildLayoutHelper.layoutChild(child, constraints);

      sizesAndOffsets
          .add(ChildSizeAndOffset(size: size, parentData: child.parentData as ChildGeometriesProviderParentData));
    });

    positioner(constraints, sizesAndOffsets);

    double totalWidth = 0;
    double totalHeight = 0;
    double elementMaxWidth = 0;
    double elementMaxHeight = 0;
    for (final s in sizesAndOffsets) {
      elementMaxWidth = max(elementMaxWidth, s.size.width);
      elementMaxHeight = max(elementMaxHeight , s.size.height);
      totalWidth += s.offset.dx;
      totalHeight += s.offset.dy;
    }
    totalWidth += elementMaxWidth;
    totalHeight += elementMaxHeight;

    return constraints.constrain(Size(totalWidth, totalHeight));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    forEachChild((child) {
      context.paintChild(child, offset);
    });
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

  // TODO @khongchai hit testing
}
