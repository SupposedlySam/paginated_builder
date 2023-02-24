import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'loading_item.dart';

class ShimmerView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: LoadingItem(),
        ),
        itemCount: 10,
      ),
    );
  }
}
