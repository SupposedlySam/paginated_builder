import 'package:flutter/material.dart';

class DefaultPageLoadingView extends StatelessWidget {
  const DefaultPageLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator.adaptive(
            strokeWidth: 1.5,
          ),
        ),
      ),
    );
  }
}
