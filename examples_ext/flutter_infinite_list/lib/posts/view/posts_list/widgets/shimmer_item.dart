import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'loading_item.dart';

class ShimmerItem extends StatefulWidget {
  @override
  _ShimmerItemState createState() => _ShimmerItemState();
}

class _ShimmerItemState extends State<ShimmerItem> {
  bool _enabled = true;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      enabled: _enabled,
      child: LoadingItem(),
    );
  }
}
