import 'package:flutter/material.dart';
import 'package:telex/generated/assets.dart';

class PageHeader extends StatelessWidget {
   final double height;
  const PageHeader({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SizedBox(
      width: double.infinity,
      height: size.height * height,
      child: Image.asset(Assets.imgF2,fit: BoxFit.contain,),
    );
  }
}
