import 'package:flutter/material.dart';

class DefaultPageLoadingView extends StatelessWidget {
  const DefaultPageLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator.adaptive());
  }
}
