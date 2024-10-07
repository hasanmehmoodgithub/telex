import 'package:flutter/material.dart';
import 'package:telex/utils/media_query_extension.dart';
class ResponsiveWidget extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const ResponsiveWidget({super.key,required this.child,required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.screenWidth,
      alignment: Alignment.center,
      child: SizedBox(
          width: context.screenWidth>maxWidth?maxWidth: context.screenWidth,
          child:child
      ),
    );
  }
}
