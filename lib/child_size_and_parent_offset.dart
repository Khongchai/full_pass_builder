import "package:flutter/rendering.dart";

import "full_pass_builder.dart";

/// A class that contains the information used during the layout of each of the
/// children of a [FullPassBuilder]
class ChildSizeAndOffset {
  final Size size;
  final ChildGeometriesProviderParentData parentData;

  const ChildSizeAndOffset({required this.size, required this.parentData});

  Offset get offset => parentData.offset;

  set offset(Offset offset) {
    parentData.offset = offset;
  }
}
