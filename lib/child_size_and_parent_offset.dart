import "package:flutter/rendering.dart";

import "full_pass_builder.dart";

/// A class that contains the information used during the layout of each of the
/// children of a [FullPassBuilder]
///
/// Only the offset property can be reassigned.
class ChildSizeAndOffset {
  final Size _size;
  final ChildGeometriesProviderParentData _parentData;

  const ChildSizeAndOffset(this._size, this._parentData);

  Offset get offset => _parentData.offset;

  set offset(Offset offset) {
    _parentData.offset = offset;
  }

  Size getSize() => _size;
}
