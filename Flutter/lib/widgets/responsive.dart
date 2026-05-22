import 'package:flutter/cupertino.dart';

/// Centers content with a sensible max width on tablets / foldables /
/// landscape phones. Phones in portrait pass through unchanged.
class ResponsiveContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = 560,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
