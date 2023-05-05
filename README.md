# Full Pass Builder Library

This library aims to do (almost) everything `CustomMultiChildLayout` does, but with fewer code.

If you are facing the following problems, this library might help you.

- Need to do something based on the layout information of siblings node within a single frame.
- Need custom layout algorithm without writing your own render object.
- Need both the constraints and the sizes to decide what your final layout should look like.
- Need more control over the constraints passed down to children nodes.

This library does not add anything new. It just exposes some phase of Flutter's layout algorithm
through a couple of APIs. See the "Why I Made This" section for more details.

`FullPassBuilder` accepts a list of children and then exposes:

1. (optional) The point **before** each child lay its own child/children out, you are given a list
   of children of the current RenderBox, along with the constraints passed from the parent, and you
   decide if each of the children should adhere to those constraints.
2. The point **after** each child has already laid out its child/children with the optional
   constraints from point 1. At this point, we have access to the sizes of the children and we can
   control the exact position of each children and the final size of the container based on the
   reported sizes.
3. And of course, the constraints from the parents.

## Getting Started

Create a FullPassBuilder widget with a list of children and your custom algorithm.

Here's an example of a sticky footer layout.

```dart

Widget build(BuildContext context) {
  return Container(
      child: Column(
          children: [
            Text("Photo Gallery"),
            SizedBox(height: 8),
            // Sticky footer begins here.
            FullPassBuilder(
                childrenBuilder: (context, constraints) =>
                [
                  ...contentWidgets,
                  SizedBox(height: 8),
                  TextButton("I am the sticky button!", onPressed: () {}),
                ],
                // See? There is no need for a lot of code just for this.
                layouterVisitor: (context, layouter) {
                  double heightSoFar = 0;
                  layouter.forEachChild((constraints, size, offset, index) {
                    final mdof = MediaQuery.of(context);
                    // is last
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
                          mdof.size.height));
                }
            )
          ]
      )
  );
}

```

The builder accepts three parameters.

1. `childrenBuilder`, just a normal multi widgets builder of this
   signature `Widget Function(BuildContext, BoxConstraints)`.
2. `layouterVisitor`, a callback that accepts a receives a `Layouter` object. A layouter is a helper
   class that contains some methods and properties to help you layout your children with less code.
   For example, `maxRectangle` and `minRectangle` describes both the min and the max sizes across
   both 2D axes of your children, and a `forEachChild` method to hlep iterate through the doubly
   linked list of children node. The callback should return the final size the builder decides to
   be.
3. `childrenConstrainer`, a callback that receives a list of children, the original constraints, and
   returns a list of new constraints for each of the child.

View the `full_pass_builder_examples.dart` in the examples folder for more snippets.

## Why I Made This

While all of above has always been possible, a combo of `GlobalKey` and `addPostFrameCallback` has
always been the fastest, but of course, that speed comes with its own tradeoffs of render two frames
to get what you want. It also litters your declarative widget code with unnecessary imperative
layout logic.

The second option with `CustomMultiChildLayout` (or a bit more advanced, a custom `RenderBox`
subclass), while much more flexible, requires a deeper understanding of Flutter's internals and
feels very boilerplatey. With this lib, all important decision points are exposed to you and you
just need only your math skills to solve your problem.
*The class operates at a lower level, so everything this lib can do, you can already do
with `CustomMultiChildLayout`.*

I believe all libraries can match the level of API ergonomics `LayoutBuilder` provides when trying
to expose lower level Flutter APIs. The API provided by `CustomMultiChildLayout` is still requires
too much boilerplate when I need to move fast. I want a simpler set of APIs that allow the same
level of flexibility `CustomMultiChildLayout` provides.

If you are already comfortable with creating your own `RenderBox` and/or
creating `CustomMultiChildLayout`, then this library is definitely not needed.

## What Kind of Layouts Can I Create With This?

Any custom layout you can imagine...unless it's text related. In that case, you might want to
consider `CustomMultiChildLayout` (a downside of the abstraction I have chosen, sadly).

A few examples

## Masonry #1
[masonry1](images/masonry1.png)

## Masonry #2
[masonry2](images/masonry2.png)

## Using Siblings Information to Position the Widget
[masonry2](images/siblings-information.png)








