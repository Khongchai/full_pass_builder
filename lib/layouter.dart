import 'package:flutter/rendering.dart';
import 'package:full_pass_builder/full_pass_builder.dart';

/// A class that helps manage the positioning of children as well as providing
/// some vital information obtain during `performLayout`
class Layouter {
  /// The minimum 2d size of any children.
  ///
  /// For example, if you have a list of 2 items,
  /// Item1 with size {x = 10, y = 20},
  /// Item2 with size {x = 20, y = 10}
  ///
  /// The min rectangle is the smallest value for both x and y of any child
  /// combined, which is Rect(10, 10).
  final Size minRectangle;

  /// The minimum 2d size of any children.
  ///
  /// For example, if you have a list of 2 items,
  /// Item1 with size {x = 10, y = 20},
  /// Item2 with size {x = 20, y = 10}
  ///
  /// The max rectangle is the largest value for both x and y of any child
  /// combined, which is Rect(20, 20).
  final Size maxRectangle;
  final BoxConstraints constraints;

  // Combining sizes and offsets together would make the API very confusing,
  // because one can be re-assigned a new value (offset) and one can't (size).
  final List<Size> childrenSizes;
  final List<ChildrenGeometriesProviderParentData> childrenParentData;

  final int childCount;

  const Layouter(
      {required this.minRectangle,
      required this.maxRectangle,
      required this.constraints,
      required this.childrenSizes,
      required this.childrenParentData})
      : assert(childrenSizes.length == childrenParentData.length),
        childCount = childrenSizes.length;

  void forEachChild(
      void Function(BoxConstraints constraints, Size size,
              OffsetWrapper offset, int childIndex)
          callback) {
    assert(
        childrenSizes.length == childrenParentData.length,
        "Do not add or remove items to/from the childrenSizes and "
        "childrenParentData lists.");
    for (int i = 0, j = 0;
        i < childrenSizes.length && j < childrenParentData.length;
        i++, j++) {
      callback(constraints, childrenSizes[i],
          OffsetWrapper(childrenParentData[i]), i); // i should be equals to j
    }
  }
}

/// Expose only the offset property of the parent to be externally set or get.
class OffsetWrapper {
  final ChildrenGeometriesProviderParentData _parentData;

  const OffsetWrapper(this._parentData);

  Offset get get => _parentData.offset;

  set set(Offset offset) => _parentData.offset = offset;
}
